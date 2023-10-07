// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IDeXaPresale.sol";
import "./interfaces/IRegistration.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelinUpgradeable/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelinUpgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";

contract DeXaPresale is OwnableUpgradeable, ReentrancyGuardUpgradeable, IDeXaPresale {
    uint8 public constant REFERRAL_DEEP = 6;

    uint32 public releaseMonth;

    address public deXa;

    address public coreTeamAddress;
    address public companyAddress;

    address public busd;
    address public ntr;
    address public register;

    uint256 public busdBalanceForReward;
    uint256 private constant _MONTH = 86400 * 30;

    uint256 private constant _MULTIPLER = 10000;

    uint256 public busdAmountForCoreTeam;
    uint256 public busdAmountForOwner;
    uint256 public percentForCoreTeam;

    mapping(address => uint256) public refRewardByBUSD;
    mapping(address => bool) public userBusdDeposits;
    mapping(address => bool) public userNtrDeposits;

    uint16[REFERRAL_DEEP] public referralRate;

    RoundInfo[3] public roundInfo;

    mapping(address => bool) public isBlacklisted;

    modifier onlyRegisterUser() {
        require(IRegistration(register).isRegistered(msg.sender), "No registered.");
        _;
    }

    function initialize(
        address _deXa,
        address _ntr,
        address _busd,
        address _register,
        address _coreTeam,
        address _company
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        deXa = _deXa;
        ntr = _ntr;
        busd = _busd;
        register = _register;
        coreTeamAddress = _coreTeam;
        companyAddress = _company;
        percentForCoreTeam = 1000;
        releaseMonth = 10;
    }

    function tokenPurchaseWithBUSD(uint256 _busdAmount) external override onlyRegisterUser {
        int8 _round = getRound();
        require(_round == 0 || _round == 1 || _round == 2, "Not started any Round.");

        RoundInfo storage info = roundInfo[uint8(_round)];
        require(info.busdEnabled, "Not enable to purchase with BUSD");

        require(!isBlacklisted[msg.sender], "Blacklisted User");

        require(_busdAmount >= info.minContributionForBusd, "Min contribution criteria not met");
        require(_busdAmount <= info.maxContributionForBusd, "Max contribution criteria not met");

        IERC20(busd).transferFrom(msg.sender, address(this), _busdAmount);

        info.busdRaised = info.busdRaised + _busdAmount;

        require(!hasSoldOut(uint8(_round), true), "Dexa is already sold out!");

        info.contributions[msg.sender].contributedBusdAmount += _busdAmount;
        if (info.contributions[msg.sender].purchaseTimeForBusd == 0) {
            info.contributions[msg.sender].purchaseTimeForBusd = block.timestamp;
        }

        uint256 busdForCoreTeam;

        uint256 busdForOwner;
        uint256 tokenAmount;

        unchecked {
            busdForCoreTeam = (_busdAmount * percentForCoreTeam) / _MULTIPLER;
            busdAmountForCoreTeam += busdForCoreTeam;

            busdForOwner = _busdAmount - busdForCoreTeam;
            tokenAmount = (_busdAmount * 1e18) / info.priceForBusd;
        }

        info.contributions[msg.sender].totalClaimableTokenAmountForBusd += tokenAmount;

        address[] memory referrers = IRegistration(register).getReferrerAddresses(msg.sender);
        for (uint8 i = 0; i < REFERRAL_DEEP; i++) {
            if (referrers[i] == address(0)) {
                break;
            }
            uint256 bonus;
            if (!isBlacklisted[referrers[i]]) {
                unchecked {
                    bonus = (_busdAmount * referralRate[i]) / _MULTIPLER;
                    refRewardByBUSD[referrers[i]] += bonus;

                    busdForOwner -= bonus;
                }

                IERC20(busd).transfer(referrers[i], bonus);
                emit SetRefRewardBUSD(referrers[i], msg.sender, uint8(i + 1), uint8(_round), bonus);
            }
        }

        busdAmountForOwner += busdForOwner;

        emit TokenPurchaseWithBUSD(msg.sender, uint8(_round), _busdAmount, busdForOwner);
    }

    function tokenPurchaseWithNTR(uint256 _ntrAmount) external override onlyRegisterUser {
        int8 _round = getRound();
        require(_round == 0 || _round == 1 || _round == 2, "Not started any Round.");

        RoundInfo storage info = roundInfo[uint8(_round)];
        require(info.ntrEnabled, "Not enable to purchase with NTR");

        require(!isBlacklisted[msg.sender], "Blacklisted User");

        require(_ntrAmount >= info.minContributionForNtr, "Min contribution criteria not met");
        require(_ntrAmount <= info.maxContributionForNtr, "Max contribution criteria not met");

        IERC20(ntr).transferFrom(msg.sender, address(this), _ntrAmount);

        info.ntrRaised = info.ntrRaised + _ntrAmount;

        require(!hasSoldOut(uint8(_round), false), "Dexa is already sold out!");

        info.contributions[msg.sender].contributedNtrAmount += _ntrAmount;
        if (info.contributions[msg.sender].purchaseTimeForNtr == 0) {
            info.contributions[msg.sender].purchaseTimeForNtr = block.timestamp;
        }
        uint256 tokenAmount;
        unchecked {
            tokenAmount = (_ntrAmount * 1e18) / info.priceForNtr;

            info.contributions[msg.sender].totalClaimableTokenAmountForNtr += tokenAmount;
        }

        emit TokenPurchaseWithNTR(msg.sender, uint8(_round), _ntrAmount, _ntrAmount);
    }

    function claimTokensFromBusd(uint8 _round) external nonReentrant onlyRegisterUser {
        ContributionInfo storage cInfo = roundInfo[_round].contributions[msg.sender];
        require(cInfo.contributedBusdAmount > 0, "Nothing to claim");

        bool isUnlockTime;
        unchecked {
            isUnlockTime = (block.timestamp - cInfo.purchaseTimeForBusd) / _MONTH >= roundInfo[_round].lockMonths;
        }

        require(isUnlockTime, "Locked");

        uint256 tokenAmount = getClaimableTokenAmountFromBusd(_round, msg.sender);
        cInfo.claimedTokenAmountForBusd += tokenAmount;

        cInfo.lastClaimedTimeForBusd = block.timestamp;

        IERC20(deXa).transfer(msg.sender, tokenAmount);

        emit TokenClaim(msg.sender, _round, tokenAmount);
    }

    function claimTokensFromNtr(uint8 _round) external override nonReentrant onlyRegisterUser {
        ContributionInfo storage cInfo = roundInfo[_round].contributions[msg.sender];
        require(cInfo.contributedNtrAmount > 0, "Nothing to claim");

        bool isUnlockTime;
        unchecked {
            isUnlockTime = (block.timestamp - cInfo.purchaseTimeForNtr) / _MONTH >= roundInfo[_round].lockMonths;
        }

        require(isUnlockTime, "Locked");

        uint256 tokenAmount = getClaimableTokenAmountFromNtr(_round, msg.sender);
        cInfo.claimedTokenAmountForNtr += tokenAmount;

        cInfo.lastClaimedTimeForNtr = block.timestamp;

        IERC20(deXa).transfer(msg.sender, tokenAmount);

        emit TokenClaim(msg.sender, _round, tokenAmount);
    }

    function allowanceToBusdUser(address _user, uint256 _busdAmount, uint256 _round, uint256 _purchaseTime)
        external
        override
        onlyOwner
    {
        if (_user == address(0) || _busdAmount < 0) {
            revert InvalidInputValue();
        }

        require(_round == 0 || _round == 1 || _round == 2, "Not started any Round.");

        RoundInfo storage info = roundInfo[uint8(_round)];
        require(info.busdEnabled, "Not enable to purchase with BUSD");

        require(!isBlacklisted[_user], "Blacklisted User");

        require(_busdAmount >= info.minContributionForBusd, "Min contribution criteria not met");
        require(_busdAmount <= info.maxContributionForBusd, "Max contribution criteria not met");
        require(!userBusdDeposits[_user], "Already Deposited");
        userBusdDeposits[_user] = true;

        info.busdRaised = info.busdRaised + _busdAmount;
        require(!hasSoldOut(uint8(_round), true), "Dexa is already sold out!");

        info.contributions[_user].contributedBusdAmount += _busdAmount;
        if (info.contributions[_user].purchaseTimeForBusd == 0) {
            info.contributions[_user].purchaseTimeForBusd = _purchaseTime;
        }

        uint256 busdForCoreTeam;
        uint256 busdForOwner;
        uint256 tokenAmount;

        unchecked {
            busdForCoreTeam = (_busdAmount * percentForCoreTeam) / _MULTIPLER;
            busdAmountForCoreTeam += busdForCoreTeam;

            busdForOwner = _busdAmount - busdForCoreTeam;
            tokenAmount = (_busdAmount * 1e18) / info.priceForBusd;
        }

        info.contributions[_user].totalClaimableTokenAmountForBusd += tokenAmount;

        address[] memory referrers = IRegistration(register).getReferrerAddresses(_user);
        for (uint8 i = 0; i < REFERRAL_DEEP; i++) {
            if (referrers[i] == address(0)) {
                break;
            }
            if (!isBlacklisted[referrers[i]]) {
                uint256 bonus = (_busdAmount * referralRate[i]) / _MULTIPLER;
                require(bonus <= busdBalanceForReward, "Not enough funds for reward");

                unchecked {
                    refRewardByBUSD[referrers[i]] += bonus;
                    busdForOwner -= bonus;
                    busdBalanceForReward -= bonus;
                }

                IERC20(busd).transfer(referrers[i], bonus);
                emit SetRefRewardBUSD(referrers[i], _user, uint8(i + 1), uint8(_round), bonus);
            }
        }

        busdAmountForOwner += busdForOwner;

        emit TokenPurchaseWithBUSD(_user, uint8(_round), _busdAmount, busdForOwner);
    }

    function allowanceToNtrUser(address _user, uint256 _ntrAmount, uint256 _round, uint256 _purchaseTime)
        external
        override
        onlyOwner
    {
        require(_round == 0 || _round == 1 || _round == 2, "Not started any Round.");

        RoundInfo storage info = roundInfo[uint8(_round)];
        require(info.ntrEnabled, "Not enable to purchase with NTR");

        require(!isBlacklisted[_user], "Blacklisted User");

        require(_ntrAmount >= info.minContributionForNtr, "Min contribution criteria not met");
        require(_ntrAmount <= info.maxContributionForNtr, "Max contribution criteria not met");

        require(!userNtrDeposits[_user], "Already Deposited");
        userNtrDeposits[_user] = true;

        info.ntrRaised = info.ntrRaised + _ntrAmount;

        require(!hasSoldOut(uint8(_round), false), "Dexa is already sold out!");

        info.contributions[_user].contributedNtrAmount += _ntrAmount;
        if (info.contributions[_user].purchaseTimeForNtr == 0) {
            info.contributions[_user].purchaseTimeForNtr = _purchaseTime;
        }

        uint256 tokenAmount;

        unchecked {
            tokenAmount = (_ntrAmount * 1e18) / info.priceForNtr;
            info.contributions[_user].totalClaimableTokenAmountForNtr += tokenAmount;
        }
        emit TokenPurchaseWithNTR(_user, uint8(_round), _ntrAmount, _ntrAmount);
    }

    function batchAllowanceToBusdUsers(
        address[] memory _users,
        uint256[] memory _busdAmounts,
        uint256[] memory _rounds,
        uint256[] memory _busdAmountsForReward,
        uint256 _purchaseTime
    ) external override onlyOwner {
        if (
            _users.length != _busdAmounts.length && _users.length != _rounds.length
                && _rounds.length != _busdAmountsForReward.length
        ) {
            revert InvalidInputLength();
        }
        uint256 len = _users.length;
        for (uint256 x = 0; x < len; x++) {
            if (_users[x] == address(0) || _busdAmounts[x] < 0) {
                revert InvalidInputValue();
            }
            require(_rounds[x] == 0 || _rounds[x] == 1 || _rounds[x] == 2, "Not started any Round.");

            RoundInfo storage info = roundInfo[uint8(_rounds[x])];
            require(info.busdEnabled, "Not enable to purchase with BUSD");

            require(!isBlacklisted[_users[x]], "Blacklisted User");

            require(_busdAmounts[x] >= info.minContributionForBusd, "Min contribution criteria not met");
            require(_busdAmounts[x] <= info.maxContributionForBusd, "Max contribution criteria not met");

            require(!userBusdDeposits[_users[x]], "Already Deposited");
            userBusdDeposits[_users[x]] = true;

            info.busdRaised = info.busdRaised + _busdAmounts[x];
            require(!hasSoldOut(uint8(_rounds[x]), true), "Dexa is already sold out!");

            info.contributions[_users[x]].contributedBusdAmount += _busdAmounts[x];
            if (info.contributions[_users[x]].purchaseTimeForBusd == 0) {
                info.contributions[_users[x]].purchaseTimeForBusd = _purchaseTime;
            }

            uint256 busdForCoreTeam;
            uint256 busdForOwner;
            uint256 tokenAmount;

            unchecked {
                busdForCoreTeam = (_busdAmounts[x] * percentForCoreTeam) / _MULTIPLER;

                busdAmountForCoreTeam += busdForCoreTeam;

                busdForOwner = _busdAmounts[x] - busdForCoreTeam;

                tokenAmount = (_busdAmounts[x] * 1e18) / info.priceForBusd;

                info.contributions[_users[x]].totalClaimableTokenAmountForBusd += tokenAmount;
            }

            address[] memory referrers = IRegistration(register).getReferrerAddresses(_users[x]);

            for (uint8 i = 0; i < REFERRAL_DEEP; i++) {
                if (referrers[i] == address(0)) {
                    break;
                }
                if (!isBlacklisted[referrers[i]]) {
                    uint256 bonus = (_busdAmountsForReward[x] * referralRate[i]) / _MULTIPLER;
                    require(bonus <= busdBalanceForReward, "Not enough funds for reward");

                    unchecked {
                        refRewardByBUSD[referrers[i]] += bonus;
                        busdForOwner -= bonus;
                        busdBalanceForReward -= bonus;
                    }

                    IERC20(busd).transfer(referrers[i], bonus);
                    emit SetRefRewardBUSD(referrers[i], _users[x], uint8(i + 1), uint8(_rounds[x]), bonus);
                }
            }

            busdAmountForOwner += busdForOwner;

            emit TokenPurchaseWithBUSD(_users[x], uint8(_rounds[x]), _busdAmounts[x], busdForOwner);
        }
    }

    function batchAllowanceToNtrUsers(
        address[] memory _users,
        uint256[] memory _ntrAmounts,
        uint256[] memory _rounds,
        uint256 _purchaseTime
    ) external override onlyOwner {
        if (_users.length != _ntrAmounts.length && _users.length != _rounds.length) {
            revert InvalidInputLength();
        }
        uint256 len = _users.length;
        for (uint256 x = 0; x < len; x++) {
            require(_rounds[x] == 0 || _rounds[x] == 1 || _rounds[x] == 2, "Not started any Round.");

            RoundInfo storage info = roundInfo[uint8(_rounds[x])];
            require(info.ntrEnabled, "Not enable to purchase with NTR");

            require(!isBlacklisted[_users[x]], "Blacklisted User");

            require(_ntrAmounts[x] >= info.minContributionForNtr, "Min contribution criteria not met");
            require(_ntrAmounts[x] <= info.maxContributionForNtr, "Max contribution criteria not met");

            require(!userNtrDeposits[_users[x]], "Already Deposited");
            userNtrDeposits[_users[x]] = true;

            info.ntrRaised = info.ntrRaised + _ntrAmounts[x];

            require(!hasSoldOut(uint8(_rounds[x]), false), "Dexa is already sold out!");

            info.contributions[_users[x]].contributedNtrAmount += _ntrAmounts[x];
            if (info.contributions[_users[x]].purchaseTimeForNtr == 0) {
                info.contributions[_users[x]].purchaseTimeForNtr = _purchaseTime;
            }

            uint256 tokenAmount;
            unchecked {
                tokenAmount = (_ntrAmounts[x] * 1e18) / info.priceForNtr;

                info.contributions[_users[x]].totalClaimableTokenAmountForNtr += tokenAmount;
            }

            emit TokenPurchaseWithNTR(_users[x], uint8(_rounds[x]), _ntrAmounts[x], _ntrAmounts[x]);
        }
    }

    function setRoundInfoForBusd(
        uint8 _index,
        uint256 _priceForBusd,
        uint256 _startTime,
        uint256 _endTime,
        uint8 _lockMonths,
        uint256 _maxDexaAmountToSell,
        uint256 _minContributionForBusd,
        uint256 _maxContributionForBusd
    ) external override onlyOwner {
        require(_lockMonths < 36, "Invalid Lock period");
        require(_priceForBusd > 0, "Invalid price rate");
        RoundInfo storage info = roundInfo[_index];
        info.priceForBusd = _priceForBusd;
        info.startTime = _startTime;
        info.endTime = _endTime;
        info.lockMonths = _lockMonths;
        info.maxDexaAmountToSell = _maxDexaAmountToSell;
        info.busdEnabled = true;
        info.minContributionForBusd = _minContributionForBusd;
        info.maxContributionForBusd = _maxContributionForBusd;
    }

    function setRoundInfoForNtr(
        uint8 _index,
        uint256 _priceForNtr,
        uint256 _minContributionForNtr,
        uint256 _maxContributionForNtr
    ) external override onlyOwner {
        require(_priceForNtr > 0, "Invalid price rate");
        RoundInfo storage info = roundInfo[_index];
        require(info.busdEnabled, "Must have round setup for Busd");
        info.priceForNtr = _priceForNtr;
        info.ntrEnabled = true;
        info.minContributionForNtr = _minContributionForNtr;
        info.maxContributionForNtr = _maxContributionForNtr;
    }

    function withdrawBusdForCoreTeam() external override onlyOwner {
        int8 _round = getRound();
        if ((_round == 0 || _round == 1 || _round == 2) && hasSoldOut(uint8(_round), true)) {} else {
            require(_hasEnded(), "Round is not over");
        }
        require(busdAmountForCoreTeam > 0, "Nothing to claim.");
        uint256 amount = busdAmountForCoreTeam;
        busdAmountForCoreTeam = 0;
        IERC20(busd).transfer(coreTeamAddress, amount);
    }

    function withdrawBUSD() external override onlyOwner {
        int8 _round = getRound();
        if ((_round == 0 || _round == 1 || _round == 2) && hasSoldOut(uint8(_round), true)) {} else {
            require(_hasEnded(), "Round is not over");
        }
        uint256 amount = busdAmountForOwner;
        busdAmountForOwner = 0;
        IERC20(busd).transfer(companyAddress, amount);
    }

    function withdrawDexa() external override onlyOwner {
        require(_hasEnded(), "Round is not over");
        uint256 tokens = IERC20(deXa).balanceOf(address(this));
        IERC20(deXa).transfer(msg.sender, tokens);
    }

    function setRateForCoreTeam(uint256 _rate) external override onlyOwner {
        require(_rate < 10001, "Error: not more than 100%");
        emit RateUpdatedForCoreTeam(percentForCoreTeam, _rate);
        percentForCoreTeam = _rate;
    }

    function setReleaseMonths(uint32 _releaseMonths) external override onlyOwner {
        emit ReleaseMonthsUpdated(releaseMonth, _releaseMonths);
        releaseMonth = _releaseMonths;
    }

    function changeRegisterAddress(address _register) external override onlyOwner {
        emit RegistrationContractUpdated(register, _register);
        register = _register;
    }

    function changeDexaAddress(address _deXa) external override onlyOwner {
        emit DexaContractUpdated(deXa, _deXa);
        deXa = _deXa;
    }

    function changeCoreTeamAddress(address _coreTeamAddress) external override onlyOwner {
        emit CoreTeamAccountUpdated(coreTeamAddress, _coreTeamAddress);
        coreTeamAddress = _coreTeamAddress;
    }

    function changeCompanyAddress(address _newAddress) external override onlyOwner {
        companyAddress = _newAddress;
        emit CompanyAccountUpdated(companyAddress, _newAddress);
    }

    function depositBusdForReward(uint256 _busdAmount) external override onlyOwner {
        busdBalanceForReward += _busdAmount;
        IERC20(busd).transferFrom(msg.sender, address(this), _busdAmount);
        emit BusdRewardAmountDeposited(_busdAmount, busdBalanceForReward);
    }

    function withdrawBusdForReward(address _receiver) external override onlyOwner {
        uint256 balance = busdBalanceForReward;
        busdBalanceForReward = 0;
        IERC20(busd).transfer(_receiver, balance);
        emit BusdRewardAmountWithdrawn(balance);
    }

    function setReferralRate(uint16[] memory _rates) external onlyOwner {
        if (_rates.length != REFERRAL_DEEP) {
            revert InvalidInputLength();
        }
        for (uint8 i = 0; i < _rates.length; i++) {
            referralRate[i] = _rates[i];
        }
    }

    function setBlacklistedUsers(address[] memory _blacklisted) external onlyOwner {
        for (uint256 i = 0; i < _blacklisted.length; i++) {
            require(!isBlacklisted[_blacklisted[i]], "");
            isBlacklisted[_blacklisted[i]] = true;
            emit BlacklistedUser(_blacklisted[i], true);
        }
    }

    function getClaimableTokenAmountFromBusd(uint8 _round, address _user) public view returns (uint256) {
        RoundInfo storage info = roundInfo[_round];
        ContributionInfo memory contribution = info.contributions[_user];

        if ((block.timestamp - contribution.purchaseTimeForBusd) / _MONTH > info.lockMonths) {
            uint256 months = (block.timestamp - contribution.purchaseTimeForBusd) / _MONTH - info.lockMonths;

            if (months > releaseMonth) months = releaseMonth;

            uint256 tokenAmount;
            unchecked {
                tokenAmount = (months * contribution.totalClaimableTokenAmountForBusd) / releaseMonth
                    - contribution.claimedTokenAmountForBusd;
            }

            return tokenAmount;
        } else {
            return 0;
        }
    }

    function getClaimableTokenAmountFromNtr(uint8 _round, address _user) public view returns (uint256) {
        RoundInfo storage info = roundInfo[_round];
        ContributionInfo memory contribution = info.contributions[_user];

        if ((block.timestamp - contribution.purchaseTimeForNtr) / _MONTH > info.lockMonths) {
            uint256 months = (block.timestamp - contribution.purchaseTimeForNtr) / _MONTH - info.lockMonths;

            if (months > releaseMonth) months = releaseMonth;

            uint256 tokenAmount;

            unchecked {
                tokenAmount = (months * contribution.totalClaimableTokenAmountForNtr) / releaseMonth
                    - contribution.claimedTokenAmountForNtr;
            }

            return tokenAmount;
        } else {
            return 0;
        }
    }

    function getRound() public view returns (int8) {
        int8 ret = -1;
        uint256 nowTime = block.timestamp;

        if (nowTime < roundInfo[0].startTime) {
            ret = -1; // any round is not started
        } else if (nowTime >= roundInfo[0].startTime && nowTime < roundInfo[0].endTime) {
            ret = 0; // in round 1
        } else if (nowTime >= roundInfo[0].endTime && nowTime < roundInfo[1].startTime) {
            ret = -2; // round 2 is not started
        } else if (nowTime >= roundInfo[1].startTime && nowTime < roundInfo[1].endTime) {
            ret = 1; // in round 2
        } else if (nowTime >= roundInfo[1].endTime && nowTime < roundInfo[2].startTime) {
            ret = -3; // round 3 is not started
        } else if (nowTime >= roundInfo[2].startTime && nowTime < roundInfo[2].endTime) {
            ret = 2; // in round 3
        } else if (nowTime >= roundInfo[2].endTime) {
            ret = -4; // all round is ended
        }
        return ret;
    }

    function hasSoldOut(uint8 _round, bool _isBusd) public view returns (bool) {
        RoundInfo storage info = roundInfo[_round];
        uint256 dexaAmount;
        if (_isBusd) {
            dexaAmount = (info.busdRaised * 1e18) / info.priceForBusd;
        } else {
            dexaAmount = (info.ntrRaised * 1e18) / info.priceForNtr;
        }

        if (dexaAmount > info.maxDexaAmountToSell) return true;
        else return false;
    }

    function getContribute(address _user, uint8 _round) public view returns (ContributionInfo memory) {
        return roundInfo[_round].contributions[_user];
    }

    function getReferralRateAndAddresses()
        public
        view
        returns (
            uint16[REFERRAL_DEEP] memory _referralRate,
            uint256 _percentForCoreTeam,
            address _coreTeamAddress,
            address _companyAddress
        )
    {
        _referralRate = referralRate;
        _percentForCoreTeam = percentForCoreTeam;
        _coreTeamAddress = coreTeamAddress;
        _companyAddress = companyAddress;
    }

    function _hasEnded() internal view returns (bool) {
        int8 _round = getRound();
        if (_round == -2 || _round == -3 || _round == -4) return true;
        else return false;
    }
}
