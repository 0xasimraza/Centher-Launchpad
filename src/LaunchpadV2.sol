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
    uint256 private constant _MULTIPLER = 10000;
    uint256 private constant _PERCENT = 10000;

    uint256[REFERRAL_DEEP] public referralRates;

    mapping(address => PresaleInfo) public presaleInfo;
    mapping(address => bool) public createdPresale;

    IERC20 public busd;
    IRegistration public register;

    modifier onlyRegisterUser() {
        if (!(register.isRegistered(msg.sender))) {
            revert UnregisteredUser();
        }
        _;
    }

    constructor(address _register, address _busd) Ownable() ReentrancyGuard() {
        createFee = 0.001 ether;
        referralRates = [600, 400, 200, 200, 200, 200];

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
        if (!(msg.value >= createFee)) {
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
        for (uint8 i = 0; i < _roundsParams.length; i++) {
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

        // presaleInfo[_infoParams.token].roundsInfo = _roundsParams;

        for (uint256 i = 0; i < _roundsParams.length; i++) {
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
        for (uint8 i = 0; i < _roundsParams.length; i++) {
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

        delete info.roundsInfo;

        uint256 loopCount = _roundsParams.length;

        for (uint8 i = 0; i < loopCount; i++) {
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
        if (!(_busdAmount >= info.minContribution)) {
            revert IncorrectMinContribution();
        }
        if (!(_busdAmount <= info.maxContribution)) {
            revert IncorrectMaxContribution();
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

        uint256 tokenAmount = _busdAmount * _MULTIPLER / info.pricePerToken;

        presaleInfo[_token].contributions[uint8(_round)][msg.sender].totalClaimableToken += tokenAmount;

        address[] memory referrers = register.getReferrerAddresses(msg.sender);

        uint256 busdForOwner = _busdAmount * (_PERCENT - presaleInfo[_token].params.tokenFeeRate) / _PERCENT;

        for (uint8 i = 0; i < REFERRAL_DEEP; i++) {
            if (referrers[i] == address(0)) {
                break;
            }
            uint256 bonus = _busdAmount * referralRates[i] / _MULTIPLER;
            presaleInfo[_token].fundForReferrer[referrers[i]] += bonus;
            busdForOwner -= bonus;
            emit SetRefReward(_token, referrers[i], msg.sender, uint8(i + 1), uint8(_round), FundType.BUSD, bonus);
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
        if (hasSoldOut(_token, uint8(_round))) {
            revert TokensAlreadySold();
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
        if (presaleInfo[_token].contributions[uint8(_round)][msg.sender].purchaseTime == 0) {
            presaleInfo[_token].contributions[uint8(_round)][msg.sender].purchaseTime = block.timestamp;
        }

        uint256 tokenAmount = _bnbAmount * 1e18 / info.pricePerToken;

        presaleInfo[_token].contributions[uint8(_round)][msg.sender].totalClaimableToken += tokenAmount;

        address[] memory referrers = register.getReferrerAddresses(msg.sender);

        uint256 bnbForOwner = _bnbAmount * (_PERCENT - presaleInfo[_token].params.coinFeeRate) / _PERCENT;

        for (uint8 i = 0; i < REFERRAL_DEEP; i++) {
            if (referrers[i] == address(0)) {
                break;
            }
            uint256 bonus = _bnbAmount * referralRates[i] / _MULTIPLER;
            presaleInfo[_token].fundForReferrer[referrers[i]] += bonus;
            bnbForOwner -= bonus;
            emit SetRefReward(_token, referrers[i], msg.sender, uint8(i + 1), uint8(_round), FundType.BNB, bonus);
        }

        presaleInfo[_token].fundForCreator += bnbForOwner;
        presaleInfo[_token].fundForFee += (_bnbAmount - bnbForOwner);

        emit TokenPurchaseWithBNB(_token, msg.sender, uint8(_round), _bnbAmount, bnbForOwner);
    }

    function getRoundInfo(address _token) external view returns (RoundInfo[] memory) {
        return presaleInfo[_token].roundsInfo;
    }

    function hasSoldOut(address _token, uint8 _round) public view returns (bool) {
        RoundInfo storage info = presaleInfo[_token].roundsInfo[_round];
        uint256 tokenAmount = presaleInfo[_token].fundRaised[_round] * 1e18 / info.pricePerToken;
        console2.log("fundRaised: ", tokenAmount);
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
}
