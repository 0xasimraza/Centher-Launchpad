// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IDeXaPresale {
    error BookingNotFound();
    error InvalidInputValue();
    error InvalidInputLength();

    event TokenPurchaseWithNTR(
        address indexed beneficiary,
        uint8 round,
        uint256 ntrAmount,
        uint256 ntrAmountForOwner
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
    event RefRewardClaimNTR(address indexed referrer, uint256 amount);
    event SetRefRewardBUSD(
        address indexed referrer,
        address indexed user,
        uint8 level,
        uint8 round,
        uint256 amount
    );
    event SetRefRewardNTR(
        address indexed referrer,
        address indexed user,
        uint8 level,
        uint8 round,
        uint256 amount
    );

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
        uint256 minContributionForNtr;
        uint256 maxContributionForBusd;
        uint256 maxContributionForNtr;
        mapping(address => ContributionInfo) contributions;
    }

    // function claimPrebookTokens() external;

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
