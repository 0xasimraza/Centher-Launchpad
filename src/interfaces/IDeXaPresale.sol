// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IDeXaPresale {
    error BookingNotFound();
    error InvalidInputValue();
    error InvalidInputLength();

    event TokenPurchaseWithToken(
        address indexed beneficiary,
        uint8 round,
        uint256 tokenAmount,
        uint256 tokenAmountForOwner
    );
    event TokenPurchaseWithBUSD(
        address indexed beneficiary,
        uint8 round,
        uint256 busdAmount,
        uint256 busdAmountForOwner
    );
    event TokenClaim(
        address indexed beneficiary,
        uint8 round,
        uint256 tokenAmount
    );
    event RefRewardClaimBUSD(address indexed referrer, uint256 amount);
    event RefRewardClaimToken(address indexed referrer, uint256 amount);
    event SetRefRewardBUSD(
        address indexed referrer,
        address indexed user,
        uint8 level,
        uint8 round,
        uint256 amount
    );
    event SetRefRewardToken(
        address indexed referrer,
        address indexed user,
        uint8 level,
        uint8 round,
        uint256 amount
    );

    struct ContributionInfo {
        uint256 contributedBusdAmount;
        uint256 contributedTokenAmount;
        uint256 purchaseTimeForBusd;
        uint256 purchaseTimeForToken;
        uint256 claimedTokenAmountForBusd;
        uint256 claimedTokenAmountForToken;
        uint256 totalClaimableTokenAmountForBusd;
        uint256 totalClaimableTokenAmountForToken;
        uint256 lastClaimedTimeForBusd;
    }

    struct RoundInfo {
        uint256 priceForBusd;
        uint256 priceForToken;
        uint256 startTime;
        uint256 endTime;
        uint8 lockMonths;
        uint256 maxDexaAmountToSell;
        bool busdEnabled;
        bool tokenEnabled;
        uint256 busdRaised;
        uint256 tokenRaised;
        uint256 minContributionForBusd;
        uint256 minContributionForToken;
        uint256 maxContributionForBusd;
        uint256 maxContributionForToken;
        mapping(address => ContributionInfo) contributions;
    }

    function allowanceToUser(
        address _user,
        uint256 _busdAmount,
        uint256 _round
    ) external;

    function batchAllowanceToUsers(
        address[] calldata _user,
        uint256[] calldata _amount,
        uint256[] memory _rounds
    ) external;
}
