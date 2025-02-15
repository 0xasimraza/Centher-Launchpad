// SPDX-License-Identifier: LICENSED
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ILaunchpadV2, IRegistration} from "./interfaces/ILaunchpadV2.sol";

import "@openzeppelinUpgradeable/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelinUpgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";

contract LaunchpadV2 is ILaunchpadV2, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    bool private initialized;
    uint256 public createFee;
    uint256 public collectedFees;

    uint256 public constant REFERRAL_DEEP = 6;
    // uint256 private constant _MONTH = 30 days; //production
    uint256 private constant _MONTH = 1800; // testnet
    uint256 private constant _PERCENT = 10000;

    mapping(address => PresaleInfo) public presaleInfo;
    mapping(address => AffiliateSetting[]) public affiliateSettings;
    mapping(address => bool) public createdPresale;

    IERC20 public busd;
    IRegistration public register;

    modifier onlyRegisteredUser() {
        if (!(register.isRegistered(msg.sender))) {
            revert UnregisteredUser();
        }
        _;
    }

    modifier onlyCreator(address _token) {
        if (presaleInfo[_token].params.owner != msg.sender) {
            revert NotCreator();
        }
        _;
    }

    function initialize(address _register, address _busd) public initializer {
        require(!initialized, "Contract instance has already been initialized");
        initialized = true;
        __Ownable_init();
        __ReentrancyGuard_init();

        busd = IERC20(_busd);
        register = IRegistration(_register);
    }

    function createPresale(PresaleInfoParams calldata _infoParams, RoundInfo[] memory _roundsParams)
        external
        payable
        override
        onlyRegisteredUser
    {
        if (createdPresale[_infoParams.token]) {
            revert AlreadyCreated();
        }
        if (msg.value < createFee && createFee != 0) {
            revert InsufficientFees();
        }
        if (_infoParams.minTokensToSell > _infoParams.maxTokensToSell) {
            revert MaxValueGreaterThanMin();
        }
        if (IERC20(_infoParams.token).balanceOf(msg.sender) < _infoParams.maxTokensToSell) {
            revert InsufficientTokens();
        }
        if (_infoParams.owner != msg.sender) {
            revert CallerMustBeOwner();
        }
        if (_infoParams.roundDeep != _roundsParams.length) {
            revert IncorrectRoundsCount();
        }

        uint256 _totalTokenToSell = sumTokensToSell(_roundsParams);

        if (_infoParams.maxTokensToSell < _totalTokenToSell) {
            revert IncorrectAmountToSell();
        }

        uint256 tokenAmount = _infoParams.maxTokensToSell;

        IERC20(_infoParams.token).transferFrom(msg.sender, address(this), tokenAmount);

        _setupPresaleRounds(_infoParams, _roundsParams);

        collectedFees += msg.value;
        createdPresale[_infoParams.token] = true;

        emit CreatePresale(_infoParams.token, msg.sender, _infoParams, _roundsParams);
    }

    function updatePresale(PresaleInfoParams memory _infoParams, RoundInfo[] memory _roundsParams)
        external
        override
        onlyRegisteredUser
    {
        if (!createdPresale[_infoParams.token]) {
            revert NotCreated();
        }
        if (presaleInfo[_infoParams.token].params.owner != msg.sender) {
            revert NotOwner();
        }
        if (presaleInfo[_infoParams.token].roundsInfo[0].startTime < block.timestamp) {
            revert SaleAlreadyLive();
        }
        if (_infoParams.minTokensToSell > _infoParams.maxTokensToSell) {
            revert MaxValueGreaterThanMin();
        }
        if (IERC20(_infoParams.token).balanceOf(msg.sender) < _infoParams.maxTokensToSell) {
            revert InsufficientTokens();
        }
        if (_infoParams.roundDeep != _roundsParams.length) {
            revert IncorrectRoundsCount();
        }

        uint256 _totalTokenToSell = sumTokensToSell(_roundsParams);
        if (_infoParams.maxTokensToSell < _totalTokenToSell) {
            revert IncorrectAmountToSell();
        }

        uint256 newTokenAmount;

        newTokenAmount = _infoParams.maxTokensToSell;

        PresaleInfo storage info = presaleInfo[_infoParams.token];
        uint256 oldTokenAmount = info.params.maxTokensToSell + info.tokenForFee;
        if (newTokenAmount > oldTokenAmount) {
            IERC20(_infoParams.token).transferFrom(msg.sender, address(this), (newTokenAmount - oldTokenAmount));
        } else if (newTokenAmount < oldTokenAmount) {
            IERC20(_infoParams.token).transfer(msg.sender, (oldTokenAmount - newTokenAmount));
        }

        delete info.roundsInfo;

        _setupPresaleRounds(_infoParams, _roundsParams);

        emit UpdatePresale(_infoParams.token, _infoParams, _roundsParams);
    }

    function tokenPurchaseWithBNB(address _token) external payable override nonReentrant onlyRegisteredUser {
        int8 _round = getRound(_token);

        if (!(_round == 0 || _round == 1 || _round == 2)) {
            revert IncorrectRoundsCount();
        }

        RoundInfo storage info = presaleInfo[_token].roundsInfo[uint8(_round)];

        if (presaleInfo[_token].params.fundType != FundType.BNB) {
            revert PurchaseWithOnlyBUSD();
        }
        uint256 _bnbAmount = msg.value;
        if (_bnbAmount < info.minContribution) {
            revert IncorrectMinContribution();
        }
        if (_bnbAmount > info.maxContribution) {
            revert IncorrectMaxContribution();
        }
        presaleInfo[_token].raisingFundForPresale += _bnbAmount;

        presaleInfo[_token].contributions[uint8(_round)][msg.sender].contributedFund += _bnbAmount;
        presaleInfo[_token].fundRaised[uint8(_round)] += _bnbAmount;

        if (presaleInfo[_token].affiliateSetup == AffiliateStatus.Pending) {
            revert AffiliateStatusIsPending();
        }

        if (hasSoldOut(_token, uint8(_round))) {
            revert TokensAlreadySold();
        }

        if (presaleInfo[_token].contributions[uint8(_round)][msg.sender].purchaseTime == 0) {
            presaleInfo[_token].contributions[uint8(_round)][msg.sender].purchaseTime = block.timestamp;
        }

        uint256 tokenAmount;

        unchecked {
            tokenAmount = _bnbAmount * 1e18 / info.pricePerToken;
        }

        presaleInfo[_token].contributions[uint8(_round)][msg.sender].totalClaimableToken += tokenAmount;

        uint256 totalRefRewards;
        if (presaleInfo[_token].affiliateSetup == AffiliateStatus.Active) {
            totalRefRewards = _updateRefRewards(_token, _round, _bnbAmount);
        }

        uint256 fundForFees;
        unchecked {
            fundForFees = _bnbAmount - (_bnbAmount * (_PERCENT - presaleInfo[_token].params.coinFeeRate) / _PERCENT);

            presaleInfo[_token].fundForCreator += _bnbAmount - (fundForFees + totalRefRewards);
            presaleInfo[_token].fundForFee += fundForFees;
        }

        emit TokenPurchaseWithBNB(_token, msg.sender, uint8(_round), _bnbAmount, presaleInfo[_token].fundForCreator);
    }

    function tokenPurchaseWithBUSD(address _token, uint256 _busdAmount)
        external
        override
        nonReentrant
        onlyRegisteredUser
    {
        int8 _round = getRound(_token);
        if (!(_round == 0 || _round == 1 || _round == 2)) {
            revert IncorrectRoundsCount();
        }
        RoundInfo storage info = presaleInfo[_token].roundsInfo[uint8(_round)];
        if (((info.tokensToSell * 1e18) / info.pricePerToken) < _busdAmount) {
            revert SellLimitExceeding();
        }
        if (presaleInfo[_token].params.fundType != FundType.BUSD) {
            revert PurchaseWithOnlyBNB();
        }
        if (_busdAmount < info.minContribution) {
            revert IncorrectMinContribution();
        }
        if (_busdAmount > info.maxContribution) {
            revert IncorrectMaxContribution();
        }

        if (presaleInfo[_token].affiliateSetup == AffiliateStatus.Pending) {
            revert AffiliateStatusIsPending();
        }

        busd.transferFrom(msg.sender, address(this), _busdAmount);

        presaleInfo[_token].raisingFundForPresale += _busdAmount;

        presaleInfo[_token].contributions[uint8(_round)][msg.sender].contributedFund += _busdAmount;
        presaleInfo[_token].fundRaised[uint8(_round)] += _busdAmount;

        if (hasSoldOut(_token, uint8(_round))) {
            revert TokensAlreadySold();
        }

        if (presaleInfo[_token].contributions[uint8(_round)][msg.sender].purchaseTime == 0) {
            presaleInfo[_token].contributions[uint8(_round)][msg.sender].purchaseTime = block.timestamp;
        }
        uint256 tokenAmount;
        unchecked {
            tokenAmount = (_busdAmount * 1e18) / info.pricePerToken;
        }

        presaleInfo[_token].contributions[uint8(_round)][msg.sender].totalClaimableToken += tokenAmount;

        uint256 totalRefRewards;
        if (presaleInfo[_token].affiliateSetup == AffiliateStatus.Active) {
            totalRefRewards = _updateRefRewards(_token, _round, _busdAmount);
        }
        uint256 fundForFees;
        unchecked {
            fundForFees = _busdAmount - (_busdAmount * (_PERCENT - presaleInfo[_token].params.tokenFeeRate) / _PERCENT);
            presaleInfo[_token].fundForCreator += _busdAmount - (fundForFees + totalRefRewards);
            presaleInfo[_token].fundForFee += fundForFees;
        }

        emit TokenPurchaseWithBUSD(_token, msg.sender, uint8(_round), _busdAmount, presaleInfo[_token].fundForCreator);
    }

    function claimTokens(address _token, uint8 _round) external override nonReentrant onlyRegisteredUser {
        if (!(hasSoftCapReached(_token))) {
            revert CannotClaim();
        }
        ContributionInfo storage cInfo = presaleInfo[_token].contributions[_round][msg.sender];
        if (cInfo.contributedFund < 0) {
            revert NoTokensToClaim();
        }

        uint256 passedTime;
        unchecked {
            passedTime = (block.timestamp - cInfo.purchaseTime) / _MONTH;
        }

        if (passedTime < presaleInfo[_token].roundsInfo[_round].lockMonths) {
            revert Locked();
        }
        uint256 tokenAmount = getClaimableTokenAmount(_token, _round, msg.sender);
        cInfo.claimedToken += tokenAmount;

        cInfo.lastClaimedTime = block.timestamp;

        IERC20(_token).transfer(msg.sender, tokenAmount);

        emit TokenClaim(_token, msg.sender, _round, tokenAmount);
    }

    function setAffiliateSetting(address token, AffiliateSettingInput memory _setting)
        external
        override
        onlyCreator(token)
    {
        if (presaleInfo[token].affiliateSetup == AffiliateStatus.NoRefReward) {
            revert NotSupportedForRefReward();
        }

        if (presaleInfo[token].affiliateSetup == AffiliateStatus.Active) {
            revert AlreadyAffiliateSettingUpdated();
        }

        affiliateSettings[token].push(AffiliateSetting({level: 1, percent: _setting.levelOne}));

        affiliateSettings[token].push(AffiliateSetting({level: 2, percent: _setting.levelTwo}));

        affiliateSettings[token].push(AffiliateSetting({level: 3, percent: _setting.levelThree}));

        affiliateSettings[token].push(AffiliateSetting({level: 4, percent: _setting.levelFour}));

        affiliateSettings[token].push(AffiliateSetting({level: 5, percent: _setting.levelFive}));

        affiliateSettings[token].push(AffiliateSetting({level: 6, percent: _setting.levelSix}));

        presaleInfo[token].affiliateSetup = AffiliateStatus.Active;

        emit AffiliateSettingSet(token, affiliateSettings[token], presaleInfo[token].affiliateSetup);
    }

    function withdrawFundsForCreator(address _token) external override nonReentrant onlyCreator(_token) {
        if (!hasSoftCapReached(_token)) {
            revert CannotClaim();
        }
        if (!_hasEnded(_token)) {
            revert PresaleNotOver();
        }
        if (presaleInfo[_token].fundForCreator < 0) {
            revert NoFundsToClaim();
        }
        uint256 amount = presaleInfo[_token].fundForCreator;

        presaleInfo[_token].fundForCreator = 0;

        if (presaleInfo[_token].params.fundType == FundType.BUSD) {
            busd.transfer(msg.sender, amount);
        } else if (presaleInfo[_token].params.fundType == FundType.BNB) {
            (bool success,) = payable(msg.sender).call{value: amount}("");
            if (!success) {
                revert FailedToWithdrawTokens();
            }
        }
        emit WithdrawFundsForCreator(_token, msg.sender, presaleInfo[_token].params.fundType, amount);
    }

    function withdrawTokensForCreator(address _token) external override nonReentrant onlyCreator(_token) {
        if (!_hasEnded(_token)) {
            revert PresaleNotOver();
        }
        uint256 amount = presaleInfo[_token].params.maxTokensToSell;
        if (hasSoftCapReached(_token)) {
            for (uint8 i; i < presaleInfo[_token].roundsInfo.length; i++) {
                uint256 funds = presaleInfo[_token].fundRaised[i];
                presaleInfo[_token].fundRaised[i] = 0;
                unchecked {
                    amount -= (funds * 1e18) / presaleInfo[_token].roundsInfo[i].pricePerToken;
                }
            }
        }
        IERC20(_token).transfer(msg.sender, amount);
        emit WithdrawTokensForCreator(_token, msg.sender, amount);
    }

    function refund(address _token) external override nonReentrant {
        if (!_hasEnded(_token)) {
            revert PresaleNotOver();
        }
        if (hasSoftCapReached(_token)) {
            revert PresaleNotFailed();
        }

        uint256 amount;
        for (uint8 i; i < presaleInfo[_token].roundsInfo.length; i++) {
            amount += presaleInfo[_token].contributions[i][msg.sender].contributedFund;
            presaleInfo[_token].contributions[i][msg.sender].contributedFund = 0;
        }

        if (presaleInfo[_token].params.fundType == FundType.BUSD) {
            busd.transfer(msg.sender, amount);
        } else if (presaleInfo[_token].params.fundType == FundType.BNB) {
            (bool success,) = payable(msg.sender).call{value: amount}("");
            if (!success) {
                revert FailedToWithdrawFunds();
            }
        }
        emit Refund(_token, msg.sender, presaleInfo[_token].params.fundType, amount);
    }

    function claimRefReward(address _token) external override nonReentrant onlyRegisteredUser {
        if (presaleInfo[_token].affiliateSetup != AffiliateStatus.Active) {
            revert NotSupportedForRefReward();
        }
        if (presaleInfo[_token].fundForReferrer[msg.sender] == 0) {
            revert NoRewardsToClaim();
        }
        if (!hasSoftCapReached(_token)) {
            revert CannotClaim();
        }

        if (!_hasEnded(_token)) {
            revert PresaleNotOver();
        }
        uint256 _amount = presaleInfo[_token].fundForReferrer[msg.sender];
        presaleInfo[_token].fundForReferrer[msg.sender] = 0;

        if (presaleInfo[_token].params.fundType == FundType.BUSD) {
            busd.transfer(msg.sender, _amount);
        } else if (presaleInfo[_token].params.fundType == FundType.BNB) {
            (bool success,) = payable(msg.sender).call{value: _amount}("");
            if (!success) {
                revert FailedToWithdrawFunds();
            }
        }
        emit RefRewardClaim(_token, msg.sender, presaleInfo[_token].params.fundType, _amount);
    }

    function withdrawFundsForFee(address _token) external override onlyOwner {
        if (!hasSoftCapReached(_token)) {
            revert CannotClaim();
        }
        if (!_hasEnded(_token)) {
            revert PresaleNotOver();
        }
        if (presaleInfo[_token].fundForFee < 0) {
            revert NoRewardsToClaim();
        }
        uint256 amount = presaleInfo[_token].fundForFee;

        presaleInfo[_token].fundForFee = 0;

        if (presaleInfo[_token].params.fundType == FundType.BUSD) {
            busd.transfer(msg.sender, amount);
        } else if (presaleInfo[_token].params.fundType == FundType.BNB) {
            (bool success,) = payable(msg.sender).call{value: amount}("");
            if (!success) {
                revert FailedToWithdrawFunds();
            }
        }
        emit WithdrawFundsForFee(_token, presaleInfo[_token].params.fundType, amount);
    }

    function withdrawCreateFee() external override onlyOwner {
        uint256 _createFee = collectedFees;
        collectedFees = 0;

        (bool success,) = payable(msg.sender).call{value: _createFee}("");
        if (!success) {
            revert FailedToWithdrawFee();
        }
        emit WithdrawCreateFee(msg.sender, _createFee);
    }

    function changeCreateFee(uint256 _newValue) external override onlyOwner {
        emit UpdatedFee(createFee, createFee = _newValue);
    }

    function getRoundInfo(address _token) external view returns (RoundInfo[] memory) {
        return presaleInfo[_token].roundsInfo;
    }

    function getRaisedFundOfRound(address _token, uint8 _round) external view returns (uint256) {
        return presaleInfo[_token].fundRaised[_round];
    }

    function getRoundUserContribution(address contributor, address _token, uint8 _round)
        external
        view
        returns (ContributionInfo memory)
    {
        return presaleInfo[_token].contributions[_round][contributor];
    }

    function getTotalRaisedFund(address _token) external view returns (uint256) {
        return presaleInfo[_token].raisingFundForPresale;
    }

    function getFundForReferrer(address _user, address _token) external view returns (uint256) {
        return presaleInfo[_token].fundForReferrer[_user];
    }

    function hasSoldOut(address _token, uint8 _round) public view returns (bool) {
        uint256 tokenAmount;
        unchecked {
            tokenAmount =
                (presaleInfo[_token].fundRaised[_round] * 1e18) / presaleInfo[_token].roundsInfo[_round].pricePerToken;
        }

        if (tokenAmount >= presaleInfo[_token].roundsInfo[_round].tokensToSell) return true;
        else return false;
    }

    function getClaimableTokenAmount(address _token, uint8 _round, address _user) public view returns (uint256) {
        RoundInfo storage info = presaleInfo[_token].roundsInfo[_round];
        ContributionInfo memory contribution = presaleInfo[_token].contributions[_round][_user];
        uint256 passedTimeInSecs = (block.timestamp - contribution.purchaseTime);
        if (passedTimeInSecs / _MONTH > info.lockMonths) {
            uint256 months;

            unchecked {
                months = passedTimeInSecs / _MONTH - info.lockMonths;
            }

            if (months > presaleInfo[_token].params.releaseMonth) months = presaleInfo[_token].params.releaseMonth;
            uint256 tokenAmount;

            unchecked {
                tokenAmount = (months * contribution.totalClaimableToken) / presaleInfo[_token].params.releaseMonth
                    - contribution.claimedToken;
            }

            return tokenAmount;
        } else {
            return 0;
        }
    }

    function getRound(address _token) public view returns (int8) {
        int8 ret = -1;
        uint256 nowTime = block.timestamp;

        RoundInfo[] storage _roundsInfo = presaleInfo[_token].roundsInfo;

        if (nowTime < _roundsInfo[0].startTime) {
            ret = -1; // any round is not started
        } else if (nowTime >= _roundsInfo[0].startTime && nowTime < _roundsInfo[0].endTime) {
            ret = 0; // in round 1
        } else if (nowTime >= _roundsInfo[0].endTime && nowTime < _roundsInfo[1].startTime) {
            ret = -2; // round 2 is not started
        } else if (nowTime >= _roundsInfo[1].startTime && nowTime < _roundsInfo[1].endTime) {
            ret = 1; // in round 2
        } else if (nowTime >= _roundsInfo[1].endTime && nowTime < _roundsInfo[2].startTime) {
            ret = -3; // round 3 is not started
        } else if (nowTime >= _roundsInfo[2].startTime && nowTime < _roundsInfo[2].endTime) {
            ret = 2; // in round 3
        } else if (nowTime >= _roundsInfo[2].endTime) {
            ret = -4; // all round is ended
        }
        return ret;
    }

    function hasSoftCapReached(address _token) public view returns (bool) {
        RoundInfo[] storage roundInfos = presaleInfo[_token].roundsInfo;
        uint256 totalSoldTokenAmount;
        for (uint8 i; i < roundInfos.length; i++) {
            unchecked {
                totalSoldTokenAmount += (presaleInfo[_token].fundRaised[i] * 1e18) / roundInfos[i].pricePerToken;
            }
        }
        if (totalSoldTokenAmount >= presaleInfo[_token].params.minTokensToSell) return true;
        return false;
    }

    function _updateRefRewards(address _token, int8 _round, uint256 _amount)
        internal
        returns (uint256 totalRefReward)
    {
        uint256 reward;
        address[] memory referrers = register.getReferrerAddresses(msg.sender);

        AffiliateSetting[] memory levelsInfo = affiliateSettings[_token];

        for (uint256 i; i < REFERRAL_DEEP; i++) {
            if (referrers[i] != address(0) && levelsInfo[i].percent != 0) {
                unchecked {
                    reward = (_amount * levelsInfo[i].percent) / _PERCENT;
                    presaleInfo[_token].fundForReferrer[referrers[i]] += reward;
                    totalRefReward += reward;
                }
                emit SetRefReward(_token, referrers[i], msg.sender, uint8(i + 1), uint8(_round), FundType.BUSD, reward);
            }
        }
    }

    function _hasEnded(address _token) internal view returns (bool) {
        RoundInfo[] storage _roundsInfo = presaleInfo[_token].roundsInfo;
        uint256 endTimeOfPresale = _roundsInfo[_roundsInfo.length - 1].endTime;
        if (block.timestamp > endTimeOfPresale) {
            return true;
        } else {
            return false;
        }
    }

    function sumTokensToSell(RoundInfo[] memory _rounds) internal pure returns (uint256 total) {
        for (uint256 i; i < _rounds.length; i++) {
            total += _rounds[i].tokensToSell;
        }
    }

    function _setupPresaleRounds(PresaleInfoParams memory _infoParams, RoundInfo[] memory _roundsParams) internal {
        PresaleInfo storage presale = presaleInfo[_infoParams.token];
        presale.params = _infoParams;
        if (_infoParams.isRefSupport) {
            presale.affiliateSetup = AffiliateStatus.Pending;
        }
        for (uint256 i; i < _roundsParams.length; i++) {
            presale.roundsInfo.push(_roundsParams[i]);
        }
    }
}
