// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IDeXaPresale {
    error InvalidInputValue();
    error InvalidInputLength();

    event TokenPurchaseWithBUSD(
        address indexed beneficiary, uint8 round, uint256 busdAmount, uint256 busdAmountForOwner
    );
    event TokenPurchaseWithNTR(
        address indexed beneficiary, uint8 round, uint256 busdAmount, uint256 busdAmountForOwner
    );
    event TokenClaim(address indexed beneficiary, uint8 round, uint256 tokenAmount);
    event RefRewardClaimBUSD(address indexed referrer, uint256 amount);

    event SetRefRewardBUSD(address indexed referrer, address indexed user, uint8 level, uint8 round, uint256 amount);

    event RateUpdatedForCoreTeam(uint256 oldRate, uint256 newRate);
    event ReleaseMonthsUpdated(uint32 releaseMonth, uint32 _releaseMonths);
    event RegistrationContractUpdated(address register, address _register);
    event DexaContractUpdated(address deXa, address _deXa);
    event CoreTeamAccountUpdated(address oldCoreTeamAddress, address newCoreTeamAddress);
    event CompanyAccountUpdated(address oldCompanyAccount, address newCompanyAccount);

    event BusdRewardAmountDeposited(uint256 depositedAmount, uint256 currentBalance);
    event BusdRewardAmountWithdrawn(uint256 withdrawnAmount);

    struct ContributionInfo {
        uint256 contributedBusdAmount;
        uint256 contributedNtrAmount;
        uint256 purchaseTimeForBusd;
        uint256 purchaseTimeForNtr;
        uint256 claimedTokenAmountForBusd;
        uint256 claimedTokenAmountForNtr;
        uint256 totalClaimableTokenAmountForBusd;
        uint256 totalClaimableTokenAmountForNtr;
        uint256 lastClaimedTimeForBusd;
        uint256 lastClaimedTimeForNtr;
    }

    struct RoundInfo {
        uint256 priceForBusd;
        uint256 priceForNtr;
        uint256 startTime;
        uint256 endTime;
        uint8 lockMonths;
        uint256 maxDexaAmountToSell;
        bool busdEnabled;
        bool ntrEnabled;
        uint256 busdRaised;
        uint256 ntrRaised;
        uint256 minContributionForBusd;
        uint256 maxContributionForBusd;
        uint256 minContributionForNtr;
        uint256 maxContributionForNtr;
        mapping(address => ContributionInfo) contributions;
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
    ) external;

    function setRoundInfoForNtr(
        uint8 _index,
        uint256 _priceForNtr,
        uint256 _minContributionForNtr,
        uint256 _maxContributionForNtr
    ) external;

    function tokenPurchaseWithBUSD(uint256 _busdAmount) external;

    function tokenPurchaseWithNTR(uint256 _ntrAmount) external;

    function claimTokensFromBusd(uint8 _round) external;

    function claimTokensFromNtr(uint8 _round) external;

    function setReferralRate(uint16[] memory _rates) external;

    function withdrawBusdForCoreTeam() external;

    function withdrawBUSD() external;

    function withdrawDexa() external;

    function setRateForCoreTeam(uint256 _rate) external;

    function setReleaseMonths(uint32 _releaseMonths) external;

    function changeRegisterAddress(address _register) external;

    function changeDexaAddress(address _deXa) external;

    function changeCoreTeamAddress(address _coreTeamAddress) external;

    function changeCompanyAddress(address _newAddress) external;

    function depositBusdForReward(uint256 _busdAmount) external;

    function withdrawBusdForReward(address _receiver) external;

    function allowanceToBusdUser(address _user, uint256 _busdAmount, uint256 _round, uint256 _purchaseTime) external;

    function allowanceToNtrUser(address _user, uint256 _ntrAmount, uint256 _round, uint256 _purchaseTime) external;

    function batchAllowanceToBusdUsers(
        address[] calldata _user,
        uint256[] calldata _amount,
        uint256[] memory _rounds,
        uint256 _purchaseTime
    ) external;

    function batchAllowanceToNtrUsers(
        address[] memory _users,
        uint256[] memory _busdAmounts,
        uint256[] memory _rounds,
        uint256 _purchaseTime
    ) external;
}
