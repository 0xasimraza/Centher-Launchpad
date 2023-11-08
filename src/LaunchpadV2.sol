// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/ILaunchpadV2.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "forge-std/console2.sol";

contract LaunchpadV2 is ILaunchpadV2, Ownable, ReentrancyGuard {
    uint256 public createFee;

    uint256 public constant REFERRAL_DEEP = 6;

    uint256 private constant _MONTH = 86400 * 30;

    uint256 private constant _PERCENT = 10000;

    // uint256[REFERRAL_DEEP] public referralRates;

    mapping(address => PresaleInfo) public presaleInfo;
    mapping(address => AffiliateSetting[]) public affiliateSettings;
    mapping(address => bool) public createdPresale;

    IERC20 public busd;
    IRegistration public register;

    modifier onlyRegisterUser() {
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

    constructor(address _register, address _busd) Ownable() ReentrancyGuard() {
        createFee = 0.001 ether;
        // referralRates = [600, 400, 200, 200, 200, 200];

        busd = IERC20(_busd);
        register = IRegistration(_register);
    }

    function createPresale(PresaleInfoParams calldata _infoParams, RoundInfo[] memory _roundsParams)
        external
        payable
        override
        onlyRegisterUser
    {
        if (createdPresale[_infoParams.token]) {
            revert AlreadyCreated();
        }
        if (msg.value < createFee) {
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
        uint256 _totalTokenToSell;

        uint256 roundLength = _roundsParams.length;
        for (uint8 i; i < roundLength; i++) {
            _totalTokenToSell += _roundsParams[i].tokensToSell;
        }
        if (_infoParams.maxTokensToSell < _totalTokenToSell) {
            revert IncorrectAmountToSell();
        }
        uint256 tokenForFee = IERC20(_infoParams.token).totalSupply() * _infoParams.tokenFeeRate / _PERCENT;

        uint256 tokenAmount = _infoParams.maxTokensToSell + tokenForFee;

        IERC20(_infoParams.token).transferFrom(msg.sender, address(this), tokenAmount);

        // PresaleInfo storage info = presaleInfo[_infoParams.token];
        presaleInfo[_infoParams.token].params = _infoParams;
        presaleInfo[_infoParams.token].tokenForFee = tokenForFee;

        if (_infoParams.isRefSupport == true) {
            presaleInfo[_infoParams.token].affiliateSetup = AffiliateStatus.Pending;
        }

        // presaleInfo[_infoParams.token].roundsInfo = _roundsParams;

        for (uint256 i; i < roundLength; i++) {
            presaleInfo[_infoParams.token].roundsInfo.push(_roundsParams[i]);
        }

        createdPresale[_infoParams.token] = true;

        emit CreatePresale(_infoParams.token, msg.sender, _infoParams, _roundsParams);
    }

    function updatePresale(PresaleInfoParams memory _infoParams, RoundInfo[] memory _roundsParams)
        external
        override
        onlyRegisterUser
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
        uint256 _totalTokenToSell;
        uint256 roundLength = _roundsParams.length;
        for (uint8 i; i < roundLength; i++) {
            _totalTokenToSell += _roundsParams[i].tokensToSell;
        }
        if (_infoParams.maxTokensToSell < _totalTokenToSell) {
            revert IncorrectAmountToSell();
        }

        uint256 newTokenForFee = IERC20(_infoParams.token).totalSupply() * _infoParams.tokenFeeRate / _PERCENT;
        uint256 newTokenAmount = _infoParams.maxTokensToSell + newTokenForFee;

        PresaleInfo storage info = presaleInfo[_infoParams.token];
        uint256 oldTokenAmount = info.params.maxTokensToSell + info.tokenForFee;
        if (newTokenAmount > oldTokenAmount) {
            IERC20(_infoParams.token).transferFrom(msg.sender, address(this), (newTokenAmount - oldTokenAmount));
        } else if (newTokenAmount < oldTokenAmount) {
            IERC20(_infoParams.token).transfer(msg.sender, (oldTokenAmount - newTokenAmount));
        }

        info.params = _infoParams;
        info.tokenForFee = newTokenForFee;

        if (_infoParams.isRefSupport == true) {
            presaleInfo[_infoParams.token].affiliateSetup = AffiliateStatus.Pending;
        }

        delete info.roundsInfo;

        for (uint8 i; i < roundLength; i++) {
            // if (_roundsParams.length > info.roundsInfo.length) {
            //     info.roundsInfo.push(_roundsParams[info.roundsInfo.length]);
            //     loopCount--;
            // } else if (_roundsParams.length < info.roundsInfo.length) {
            //     uint256 def = info.roundsInfo.length - _roundsParams.length;
            //     for (uint8 j = 0; j < def; j++) {
            //         info.roundsInfo.pop();
            //     }
            // }

            info.roundsInfo[i] = _roundsParams[i];
        }

        emit UpdatePresale(_infoParams.token, _infoParams, _roundsParams);
    }

    function tokenPurchaseWithBUSD(address _token, uint256 _busdAmount)
        external
        override
        nonReentrant
        onlyRegisterUser
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
            revert PurchaseWithOnlyBUSD();
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

        uint256 busdForOwner = _busdAmount * (_PERCENT - presaleInfo[_token].params.tokenFeeRate) / _PERCENT;

        if (presaleInfo[_token].affiliateSetup == AffiliateStatus.Active) {
            busdForOwner = updateRefRewards(_token, _round, _busdAmount, busdForOwner);
        }

        presaleInfo[_token].fundForCreator += busdForOwner;
        presaleInfo[_token].fundForFee += (_busdAmount - busdForOwner);

        emit TokenPurchaseWithBUSD(_token, msg.sender, uint8(_round), _busdAmount, busdForOwner);
    }

    function tokenPurchaseWithBNB(address _token) external payable override nonReentrant onlyRegisterUser {
        int8 _round = getRound(_token);
        if (!(_round == 0 || _round == 1 || _round == 2)) {
            revert IncorrectRoundsCount();
        }

        RoundInfo storage info = presaleInfo[_token].roundsInfo[uint8(_round)];

        if (presaleInfo[_token].params.fundType != FundType.BNB) {
            revert PurchaseWithOnlyBNB();
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

        uint256 tokenAmount = _bnbAmount * 1e18 / info.pricePerToken;

        presaleInfo[_token].contributions[uint8(_round)][msg.sender].totalClaimableToken += tokenAmount;

        uint256 bnbForOwner = _bnbAmount * (_PERCENT - presaleInfo[_token].params.coinFeeRate) / _PERCENT;
        if (presaleInfo[_token].affiliateSetup == AffiliateStatus.Active) {
            bnbForOwner = updateRefRewards(_token, _round, _bnbAmount, bnbForOwner);
        }

        presaleInfo[_token].fundForCreator += bnbForOwner;
        presaleInfo[_token].fundForFee += (_bnbAmount - bnbForOwner);

        emit TokenPurchaseWithBNB(_token, msg.sender, uint8(_round), _bnbAmount, bnbForOwner);
    }

    function claimTokens(address _token, uint8 _round) external override nonReentrant onlyRegisterUser {
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

    function hasSoftCapReached(address _token) public view returns (bool) {
        RoundInfo[] storage roundInfos = presaleInfo[_token].roundsInfo;
        uint256 totalSoldTokenAmount;
        for (uint8 i; i < roundInfos.length; i++) {
            totalSoldTokenAmount += presaleInfo[_token].fundRaised[i] * 1e18 / roundInfos[i].pricePerToken;
        }
        if (totalSoldTokenAmount >= presaleInfo[_token].params.minTokensToSell) return true;
        return false;
    }

    function getClaimableTokenAmount(address _token, uint8 _round, address _user) public view returns (uint256) {
        RoundInfo storage info = presaleInfo[_token].roundsInfo[_round];
        ContributionInfo memory contribution = presaleInfo[_token].contributions[_round][_user];
        uint256 passedTime = (block.timestamp - contribution.purchaseTime) / _MONTH;
        if (passedTime > info.lockMonths) {
            uint256 months = (block.timestamp - contribution.purchaseTime) / _MONTH - info.lockMonths;
            if (months > presaleInfo[_token].params.releaseMonth) months = presaleInfo[_token].params.releaseMonth;
            uint256 tokenAmount;

            unchecked {
                tokenAmount = months * contribution.totalClaimableToken / presaleInfo[_token].params.releaseMonth
                    - contribution.claimedToken;
            }

            return tokenAmount;
        } else {
            return 0;
        }
    }

    function withdrawFundsForCreator(address _token) external onlyCreator(_token) {
        // if (msg.sender != presaleInfo[_token].params.owner) {
        //     revert NotCreator();
        // }
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

    function withdrawTokensForCreator(address _token) external onlyCreator(_token) {
        // if (msg.sender != presaleInfo[_token].params.owner) {
        //     revert NotCreator();
        // }
        if (!_hasEnded(_token)) {
            revert PresaleNotOver();
        }
        uint256 amount = presaleInfo[_token].params.maxTokensToSell;
        if (hasSoftCapReached(_token)) {
            for (uint8 i; i < presaleInfo[_token].roundsInfo.length; i++) {
                uint256 funds = presaleInfo[_token].fundRaised[i];
                presaleInfo[_token].fundRaised[i] = 0;
                unchecked {
                    amount -= funds * 1e18 / presaleInfo[_token].roundsInfo[i].pricePerToken;
                }
            }
        }
        IERC20(_token).transfer(msg.sender, amount);
        emit WithdrawTokensForCreator(_token, msg.sender, amount);
    }

    function getRoundInfo(address _token) external view returns (RoundInfo[] memory) {
        return presaleInfo[_token].roundsInfo;
    }

    function hasSoldOut(address _token, uint8 _round) public view returns (bool) {
        RoundInfo storage info = presaleInfo[_token].roundsInfo[_round];
        uint256 tokenAmount;
        unchecked {
            tokenAmount = presaleInfo[_token].fundRaised[_round] * 1e18 / info.pricePerToken;
        }

        if (tokenAmount >= info.tokensToSell) return true;
        else return false;
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

    function refund(address _token) external {
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

    function changeCreateFee(uint256 _newValue) external onlyOwner {
        createFee = _newValue;
    }

    // function changeRefferalRates(uint256[REFERRAL_DEEP] calldata _newRates) external onlyOwner {
    //     referralRates = _newRates;
    // }

    function claimRefReward(address _token) external nonReentrant onlyRegisterUser {
        if (presaleInfo[_token].affiliateSetup != AffiliateStatus.Active) {
            revert NotSupportedForRefReward();
        }
        if (presaleInfo[_token].fundForReferrer[msg.sender] < 0) {
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

    // function withdrawFees(address _token) external onlyOwner {
    //     if (presaleInfo[_token].params.fundType == FundType.BUSD) {
    //         withdrawTokensForFee(_token);
    //     } else {
    //         withdrawFundsForFee(_token);
    //     }
    // }

    function withdrawFundsForFee(address _token) external onlyOwner {
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

    function withdrawTokensForFee(address _token) external onlyOwner {
        if (!hasSoftCapReached(_token)) {
            revert CannotClaim();
        }
        if (!_hasEnded(_token)) {
            revert PresaleNotOver();
        }
        if (presaleInfo[_token].tokenForFee < 0) {
            revert NoTokensToClaim();
        }
        uint256 amount = presaleInfo[_token].tokenForFee;

        presaleInfo[_token].tokenForFee = 0;

        IERC20(_token).transfer(msg.sender, amount);

        emit WithdrawTokensForFee(_token, amount);
    }

    function updateRefRewards(address _token, int8 _round, uint256 _amount, uint256 bnbForOwner)
        internal
        returns (uint256)
    {
        if (presaleInfo[_token].affiliateSetup == AffiliateStatus.Active) {
            uint256 reward;
            address[] memory referrers = register.getReferrerAddresses(msg.sender);

            AffiliateSetting[] memory levelsInfo = affiliateSettings[_token];

            for (uint256 i; i < REFERRAL_DEEP; i++) {
                if (referrers[i] != address(0) && levelsInfo[i].percent != 0) {
                    unchecked {
                        reward = (_amount * levelsInfo[i].percent) / 10000;
                        presaleInfo[_token].fundForReferrer[referrers[i]] += reward;
                        bnbForOwner -= reward;
                    }
                    emit SetRefReward(
                        _token, referrers[i], msg.sender, uint8(i + 1), uint8(_round), FundType.BUSD, reward
                    );
                }
            }
        }

        return bnbForOwner;
    }

    // function getRefferalRates(address _token) external view returns (uint256[REFERRAL_DEEP] memory) {
    //     return affiliateSettings[_token];
    // }

    function _hasEnded(address _token) internal view returns (bool) {
        if (getRound(_token) == -4) {
            return true;
        } else {
            return false;
        }
    }
}
