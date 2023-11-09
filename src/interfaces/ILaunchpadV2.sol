// SPDX-License-Identifier: LICENSED
pragma solidity 0.8.19;

interface IRegistration {
    function isRegistered(address _user) external view returns (bool);
    function getReferrerAddresses(address _user) external view returns (address[] memory _referrers);
}

interface ILaunchpadV2 {
    error UnregisteredUser();
    error AlreadyCreated();
    error InsufficientFees();
    error MaxValueGreaterThanMin();
    error InsufficientTokens();
    error CallerMustBeOwner();
    error IncorrectRoundsCount();
    error IncorrectAmountToSell();
    error NotCreated();
    error SaleAlreadyLive();
    error NotOwner();
    error TokensAlreadySold();
    error PurchaseWithOnlyBUSD();
    error IncorrectMinContribution();
    error IncorrectMaxContribution();
    error PurchaseWithOnlyBNB();
    error SellLimitExceeding();
    error CannotClaim();
    error NoTokensToClaim();
    error Locked();
    error NotCreator();
    error PresaleNotOver();
    error NoFundsToClaim();
    error FailedToWithdrawTokens();
    error PresaleNotFailed();
    error FailedToWithdrawFunds();
    error FailedToWithdrawFee();
    error RoundNotOver();
    error NoRewardsToClaim();
    error NotSupportedForRefReward();
    error AffiliateStatusIsPending();
    error AlreadyAffiliateSettingUpdated();
    error ZeroBNB();

    event CreatePresale(address indexed token, address creator, PresaleInfoParams infoParams, RoundInfo[] roundsParams);
    event UpdatePresale(address indexed token, PresaleInfoParams infoParams, RoundInfo[] roundsParams);
    event AffiliateSettingSet(address, AffiliateSetting[] affiliateSetting, AffiliateStatus isActive);
    event TokenPurchaseWithBNB(
        address indexed token, address indexed beneficiary, uint8 round, uint256 bnbAmount, uint256 bnbAmountForOwner
    );
    event TokenPurchaseWithBUSD(
        address indexed token, address indexed beneficiary, uint8 round, uint256 busdAmount, uint256 busdAmountForOwner
    );
    event TokenClaim(address indexed token, address indexed beneficiary, uint8 round, uint256 tokenAmount);
    event RefRewardClaim(address indexed token, address indexed referrer, FundType fundType, uint256 amount);
    event SetRefReward(
        address indexed token,
        address indexed referrer,
        address indexed user,
        uint8 level,
        uint8 round,
        FundType fundType,
        uint256 amount
    );
    event WithdrawFundsForFee(address indexed token, FundType fundType, uint256 amount);
    event WithdrawTokensForFee(address indexed token, uint256 amount);
    event WithdrawCreateFee(address indexed receiver, uint256 amount);
    event WithdrawFundsForCreator(address indexed token, address indexed creator, FundType fundType, uint256 amount);
    event WithdrawTokensForCreator(address indexed token, address indexed creator, uint256 amount);
    event Refund(address indexed token, address indexed buyer, FundType fundType, uint256 amount);
    event UpdatedFee(uint256 oldFee, uint256 newFee);

    struct ContributionInfo {
        uint256 contributedFund;
        uint256 purchaseTime;
        uint256 claimedToken;
        uint256 totalClaimableToken;
        uint256 lastClaimedTime;
    }

    enum FundType {
        BNB,
        BUSD
    }

    enum AffiliateStatus {
        NoRefReward,
        Pending,
        Active
    }

    struct RoundInfo {
        uint256 startTime;
        uint256 endTime;
        uint256 lockMonths;
        uint256 minContribution;
        uint256 maxContribution;
        uint256 tokensToSell;
        uint256 pricePerToken;
    }

    struct PresaleInfoParams {
        address owner;
        address token;
        uint256 minTokensToSell;
        uint256 maxTokensToSell;
        uint256 roundDeep;
        uint256 coinFeeRate;
        uint256 tokenFeeRate;
        uint256 releaseMonth;
        bool isRefSupport;
        FundType fundType;
    }

    struct PresaleInfo {
        PresaleInfoParams params;
        uint256 raisingFundForPresale;
        uint256 fundForFee;
        uint256 tokenForFee;
        uint256 fundForCreator;
        AffiliateStatus affiliateSetup;
        RoundInfo[] roundsInfo;
        mapping(address => uint256) fundForReferrer;
        mapping(uint8 => uint256) fundRaised;
        mapping(uint8 => mapping(address => ContributionInfo)) contributions;
    }

    struct AffiliateSettingInput {
        uint256 levelOne;
        uint256 levelTwo;
        uint256 levelThree;
        uint256 levelFour;
        uint256 levelFive;
        uint256 levelSix;
    }

    struct AffiliateSetting {
        uint256 level;
        uint256 percent;
    }

    function createPresale(PresaleInfoParams calldata _infoParams, RoundInfo[] memory _roundsParams) external payable;
    function updatePresale(PresaleInfoParams memory _infoParams, RoundInfo[] memory _roundsParams) external;
    function setAffiliateSetting(address token, AffiliateSettingInput memory _setting) external;
    function tokenPurchaseWithBUSD(address _token, uint256 _busdAmount) external;
    function tokenPurchaseWithBNB(address _token) external payable;
    function claimTokens(address _token, uint8 _round) external;
    function changeCreateFee(uint256 _newValue) external;
    function withdrawFundsForFee(address _token) external;
    function claimRefReward(address _token) external;
    function refund(address _token) external;
    function withdrawTokensForCreator(address _token) external;
    function withdrawFundsForCreator(address _token) external;
    function withdrawCreateFee() external;
}
