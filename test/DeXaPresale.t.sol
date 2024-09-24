// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;

// import "forge-std/Test.sol";

// import "../src/DeXaPresale.sol";
// import "../src/utils/Token.sol";
// import "../src/utils/CentherRegistration.sol";

// import "forge-std/console2.sol";

// contract TokenTest is Test {
//     address payable internal owner;
//     address payable internal user1;
//     address payable internal user2;
//     address payable internal other;

//     Token deXa;
//     Token busd;
//     Token wbnb;
//     Token ntr;

//     CentherRegistration register;

//     DeXaPresale deXaPresale;

//     function setUp() public {
//         owner = payable(vm.addr(1));
//         user1 = payable(vm.addr(2));
//         user2 = payable(vm.addr(3));
//         other = payable(vm.addr(4));

//         console2.log(" ---- owner ----", owner);
//         console2.log(" ---- user1 ----", user1);
//         console2.log(" ---- user2 ----", user2);
//         console2.log(" ---- other ----", other);

//         vm.startPrank(owner);
//         deXa = new Token("deXa", "DXC" , type(uint256).max );
//         busd = new Token("Binance USD", "BUSD", type(uint256).max);
//         wbnb = new Token("Wrapped BNB", "WBNB", type(uint256).max);
//         ntr = new Token("NTR Token", "NTR", type(uint256).max);

//         busd.transfer(user1, 500000e18);
//         busd.transfer(user2, 500000e18);

//         wbnb.transfer(user1, 500000e18);
//         wbnb.transfer(user2, 500000e18);

//         ntr.transfer(user1, 500000e18);
//         ntr.transfer(user2, 500000e18);

//         register = new CentherRegistration();
//         register.setOperator(address(owner));

//         address[] memory _users = new address[](3);
//         _users[0] = address(user1);
//         _users[1] = address(user2);
//         _users[2] = address(other);

//         address[] memory _refs = new address[](3);
//         _refs[0] = address(owner);
//         _refs[1] = address(user1);
//         _refs[2] = address(user2);

//         register.registerForOwnerBatch(_users, _refs);

//         address zero = address(0);
//         deXaPresale = new DeXaPresale(
//             address(deXa),
//             address(ntr),
//             address(busd),
//             address(register),
//             address(zero),
//             address(zero)
//         );
//         vm.stopPrank();
//     }

//     function testDeployments() public view {
//         assert(address(deXa) != address(0));
//         assert(address(deXaPresale) != address(0));
//     }

//     function testUserAllowance() public {
//         vm.startPrank(owner);
//         deal({token: address(deXa), to: address(deXaPresale), give: 50000000e18});
//         deXaPresale.setRoundInfoForBusd(
//             0, 800000000000000000, block.timestamp, block.timestamp + 30 days, 1, 50000000e18, 150e18, 1000e18
//         );

//         deXaPresale.allowanceToBusdUser(user1, 150e18, 0, block.timestamp);
//     }

//     function testBusdUsersAllowance() public {
//         vm.startPrank(owner);

//         deal({token: address(deXa), to: address(deXaPresale), give: 50000000e18});
//         deXaPresale.setRoundInfoForBusd(
//             0, 800000000000000000, block.timestamp, block.timestamp + 30 days, 1, 50000000e18, 5e18, 1000e18
//         );
//         uint256 creationTimeOfRound = block.timestamp;

//         address[] memory _users = new address[](2);
//         _users[0] = address(user1);
//         _users[1] = address(user2);

//         uint256[] memory _allowances = new uint256[](2);
//         _allowances[0] = uint256(100e18);
//         _allowances[1] = uint256(10e18);

//         uint256[] memory _rounds = new uint256[](2);
//         _rounds[0] = 0;
//         _rounds[1] = 0;

//         deXaPresale.batchAllowanceToBusdUsers(_users, _allowances, _rounds, _allowances, creationTimeOfRound);
//     }

//     function testNtrUsersAllowance() public {
//         vm.startPrank(owner);

//         deal({token: address(deXa), to: address(deXaPresale), give: 50000000e18});
//         deXaPresale.setRoundInfoForBusd(
//             0, 800000000000000000, block.timestamp, block.timestamp + 30 days, 1, 50000000e18, 5e18, 1000e18
//         );

//         uint256 creationTimeOfRound = block.timestamp;

//         deXaPresale.setRoundInfoForNtr(0, 160000000000000000000, 5e18, 5000e18);

//         address[] memory _users = new address[](2);
//         _users[0] = address(user1);
//         _users[1] = address(user2);

//         uint256[] memory _allowances = new uint256[](2);
//         _allowances[0] = uint256(100e18);
//         _allowances[1] = uint256(10e18);

//         uint256[] memory _rounds = new uint256[](2);
//         _rounds[0] = 0;
//         _rounds[1] = 0;

//         deXaPresale.batchAllowanceToNtrUsers(_users, _allowances, _rounds, creationTimeOfRound);
//     }

//     function testShoulFailedNtrAllowanceMultipleDeposits() public {
//         vm.startPrank(owner);

//         deal({token: address(deXa), to: address(deXaPresale), give: 50000000e18});
//         deXaPresale.setRoundInfoForBusd(
//             0, 800000000000000000, block.timestamp, block.timestamp + 30 days, 1, 50000000e18, 5e18, 1000e18
//         );

//         uint256 creationTimeOfRound = block.timestamp;

//         deXaPresale.setRoundInfoForNtr(0, 160000000000000000000, 5e18, 5000e18);

//         address[] memory _users = new address[](2);
//         _users[0] = address(user1);
//         _users[1] = address(user2);

//         uint256[] memory _allowances = new uint256[](2);
//         _allowances[0] = uint256(100e18);
//         _allowances[1] = uint256(10e18);

//         uint256[] memory _rounds = new uint256[](2);
//         _rounds[0] = 0;
//         _rounds[1] = 0;

//         deXaPresale.batchAllowanceToNtrUsers(_users, _allowances, _rounds, creationTimeOfRound);
//         // vm.expectRevert("Already Deposited");
//         deXaPresale.batchAllowanceToNtrUsers(_users, _allowances, _rounds, creationTimeOfRound);
//     }

//     function testSetRound0AndPurchaseWithMinBUSD() public {
//         vm.startPrank(owner);
//         deal({token: address(deXa), to: address(deXaPresale), give: 50000000e18});
//         deXaPresale.setRoundInfoForBusd(
//             0, 800000000000000000, block.timestamp, block.timestamp + 30 days, 4, 50000000e18, 150e18, 1000e18
//         );

//         changePrank(user1);

//         busd.approve(address(deXaPresale), 1000e18);

//         deXaPresale.tokenPurchaseWithBUSD(150e18);

//         vm.warp(block.timestamp + 30 days * 12);

//         deXaPresale.claimTokensFromBusd(0);

//         assertEq(deXa.balanceOf(address(user1)), 187500000000000000000, "Amount not received as expected");
//     }

//     function testSetRound0AndPurchaseWithMaxBUSD() public {
//         vm.startPrank(owner);

//         deal({token: address(deXa), to: address(deXaPresale), give: 500000e18});

//         deXaPresale.setRoundInfoForBusd(
//             0, 800000000000000000, block.timestamp, block.timestamp + 30 days, 4, 10000e18, 150e18, 5000e18
//         );

//         vm.stopPrank();
//         vm.startPrank(user1);

//         busd.approve(address(deXaPresale), 4500e18);

//         deXaPresale.tokenPurchaseWithBUSD(4500e18);

//         vm.warp(block.timestamp + 30 days * 12);
//         deXaPresale.claimTokensFromBusd(0);

//         assertEq(deXa.balanceOf(address(user1)), 5625000000000000000000, "Amount not received as expected");
//     }

//     function testSetRound1AndPurchaseWithMaxBUSD() public {
//         vm.startPrank(owner);
//         deal({token: address(deXa), to: address(deXaPresale), give: 50000000e18});
//         deXaPresale.setRoundInfoForBusd(
//             0, 800000000000000000, block.timestamp, block.timestamp + 30 days, 4, 1000e18, 150e18, 5000e18
//         );
//         vm.warp(block.timestamp + 31 days * 4);

//         //round2
//         deXaPresale.setRoundInfoForBusd(
//             1, 800000000000000000, block.timestamp, block.timestamp + 30 days, 4, 50000000e18, 150e18, 5000e18
//         );

//         vm.stopPrank();
//         vm.startPrank(user1);

//         busd.approve(address(deXaPresale), 4500e18);

//         deXaPresale.tokenPurchaseWithBUSD(4500e18);

//         vm.warp(block.timestamp + 30 days * 12);

//         deXaPresale.claimTokensFromBusd(1);

//         assertEq(deXa.balanceOf(address(user1)), 5625000000000000000000, "Amount not received as expected");
//     }

//     function testClaimDXCThroughBusd() public {
//         vm.startPrank(owner);
//         deal({token: address(deXa), to: address(deXaPresale), give: 50000000e18});
//         deXaPresale.setRoundInfoForBusd(
//             0, 800000000000000000, block.timestamp, block.timestamp + 30 days, 4, 50000000e18, 150e18, 1000e18
//         );

//         uint256 creationTimeOfRound = block.timestamp;

//         address[] memory _users = new address[](2);
//         _users[0] = address(user1);
//         _users[1] = address(user2);

//         uint256[] memory _allowances = new uint256[](2);
//         _allowances[0] = uint256(150e18);
//         _allowances[1] = uint256(150e18);

//         uint256[] memory _rounds = new uint256[](2);
//         _rounds[0] = 0;
//         _rounds[1] = 0;

//         deXaPresale.batchAllowanceToBusdUsers(_users, _allowances, _rounds, _allowances, creationTimeOfRound);

//         changePrank(user1);

//         vm.warp(block.timestamp + 30 days * 12);
//         deXaPresale.claimTokensFromBusd(0);

//         assertEq(deXa.balanceOf(user1), 187500000000000000000, "Not received claimable amount");
//     }

//     function testClaimDXCThroughNtr() public {
//         vm.startPrank(owner);

//         deal({token: address(deXa), to: address(deXaPresale), give: 50000000e18});
//         deXaPresale.setRoundInfoForBusd(
//             0, 800000000000000000, block.timestamp, block.timestamp + 30 days, 1, 50000000e18, 5e18, 1000e18
//         );

//         uint256 creationTimeOfRound = block.timestamp;

//         deXaPresale.setRoundInfoForNtr(0, 160000000000000000000, 5e18, 100000e18);

//         address[] memory _users = new address[](2);
//         _users[0] = address(user1);
//         _users[1] = address(user2);

//         uint256[] memory _allowances = new uint256[](2);
//         _allowances[0] = uint256(100000e18);
//         _allowances[1] = uint256(1000e18);

//         uint256[] memory _rounds = new uint256[](2);
//         _rounds[0] = 0;
//         _rounds[1] = 0;

//         deXaPresale.batchAllowanceToNtrUsers(_users, _allowances, _rounds, creationTimeOfRound);

//         vm.warp(block.timestamp + 30 days * 12);
//         changePrank(user1);

//         deXaPresale.claimTokensFromNtr(0);

//         changePrank(user2);
//         deXaPresale.claimTokensFromNtr(0);

//         assertEq(deXa.balanceOf(user1), 625000000000000000000, "Not valid amount received");
//         assertEq(deXa.balanceOf(user2), 6250000000000000000, "Not valid amount received");
//     }

//     function testRewardAmountForReferral() public {
//         //clear balances
//         vm.startPrank(user1);
//         busd.transfer(address(1), 500000 ether);
//         changePrank(user2);
//         busd.transfer(address(1), 500000 ether);

//         changePrank(owner);

//         busd.approve(address(deXaPresale), 10000e18);
//         deXaPresale.depositBusdForReward(10000e18);

//         uint256 ownerDexaBalanceDump = deXa.balanceOf(owner);
//         deXa.transfer(address(1), ownerDexaBalanceDump);

//         uint256 ownerBusdBalanceDump = busd.balanceOf(owner);
//         busd.transfer(address(1), ownerBusdBalanceDump);

//         uint16[] memory _rates = new uint16[](6);
//         _rates[0] = (600);
//         _rates[1] = (400);
//         _rates[2] = (200);
//         _rates[3] = (200);
//         _rates[4] = (200);
//         _rates[5] = (200);
//         deXaPresale.setReferralRate(_rates);
//         deal({token: address(deXa), to: address(deXaPresale), give: 50000000e18});

//         deXaPresale.setRoundInfoForBusd(
//             0, 800000000000000000, block.timestamp, block.timestamp + 30 days, 4, 50000000e18, 150e18, 1000e18
//         );

//         uint256 creationTimeOfRound = block.timestamp;

//         address[] memory _users = new address[](2);
//         _users[0] = address(user1);
//         _users[1] = address(user2);

//         uint256[] memory _allowances = new uint256[](2);
//         _allowances[0] = uint256(150e18);
//         _allowances[1] = uint256(150e18);

//         uint256[] memory _rounds = new uint256[](2);
//         _rounds[0] = 0;
//         _rounds[1] = 0;

//         address[] memory referrerAddresses = register.getReferrerAddresses(user2);

//         deXaPresale.batchAllowanceToBusdUsers(_users, _allowances, _rounds, _allowances, creationTimeOfRound);

//         // level1 amount check
//         assertEq(busd.balanceOf(referrerAddresses[0]), 9000000000000000000, "Amount not match");
//         // level2 amount check
//         assertEq(busd.balanceOf(referrerAddresses[1]), 15000000000000000000, "Amount not match");
//     }

//     function testBigRewardAmountForReferral() public {
//         vm.startPrank(user1);
//         busd.transfer(address(1), 500000 ether);
//         changePrank(user2);
//         busd.transfer(address(1), 500000 ether);
//         changePrank(owner);

//         busd.approve(address(deXaPresale), 10000e18);
//         deXaPresale.depositBusdForReward(10000e18);

//         uint256 ownerDexaBalanceDump = deXa.balanceOf(owner);
//         deXa.transfer(address(1), ownerDexaBalanceDump);

//         uint256 ownerBusdBalanceDump = busd.balanceOf(owner);
//         busd.transfer(address(1), ownerBusdBalanceDump);

//         uint16[] memory _rates = new uint16[](6);
//         _rates[0] = (600);
//         _rates[1] = (400);
//         _rates[2] = (200);
//         _rates[3] = (200);
//         _rates[4] = (200);
//         _rates[5] = (200);
//         deXaPresale.setReferralRate(_rates);
//         deal({token: address(deXa), to: address(deXaPresale), give: 50000000e18});

//         deXaPresale.setRoundInfoForBusd(
//             0, 800000000000000000, block.timestamp, block.timestamp + 30 days, 4, 50000000e18, 150e18, 1500e18
//         );

//         uint256 creationTimeOfRound = block.timestamp;

//         address[] memory _users = new address[](2);
//         _users[0] = address(user1);
//         _users[1] = address(user2);

//         uint256[] memory _allowances = new uint256[](2);
//         _allowances[0] = uint256(1500e18);
//         _allowances[1] = uint256(1500e18);

//         uint256[] memory _rounds = new uint256[](2);
//         _rounds[0] = 0;
//         _rounds[1] = 0;

//         address[] memory referrerAddresses = register.getReferrerAddresses(user2);

//         deXaPresale.batchAllowanceToBusdUsers(_users, _allowances, _rounds, _allowances, creationTimeOfRound);

//         // level1 amount check
//         assertEq(busd.balanceOf(referrerAddresses[0]), 90000000000000000000, "Amount not match");
//         // level2 amount check
//         assertEq(busd.balanceOf(referrerAddresses[1]), 150000000000000000000, "Amount not match");
//     }

//     function testSetReferralRateshouldFailInvalidInput() public {
//         bytes4 selector = bytes4(keccak256("InvalidInputLength()"));
//         vm.expectRevert(abi.encodeWithSelector(selector));
//         vm.startPrank(owner);
//         uint16[] memory _rates = new uint16[](8);
//         _rates[0] = (600);
//         _rates[1] = (400);
//         _rates[2] = (200);
//         _rates[3] = (200);
//         deXaPresale.setReferralRate(_rates);
//     }

//     function testDexaClaimWithMinNTR() public {
//         vm.startPrank(owner);
//         deal({token: address(deXa), to: address(deXaPresale), give: 10000000e18});

//         deXaPresale.setRoundInfoForBusd(
//             0, 800000000000000000, block.timestamp, block.timestamp + 30 days, 4, 50000000e18, 150e18, 1500e18
//         );

//         deXaPresale.setRoundInfoForNtr(0, 160000000000000000000, 150e18, 5000e18);

//         changePrank(user1);

//         ntr.approve(address(deXaPresale), 4500e18);

//         deXaPresale.tokenPurchaseWithNTR(150e18);

//         vm.warp(block.timestamp + 30 days * 12);
//         deXaPresale.claimTokensFromNtr(0);

//         assertEq(deXa.balanceOf(address(user1)), 937500000000000000, "Amount not received as expected");
//     }

//     function testDexaClaimWithMaxNTR() public {
//         vm.startPrank(owner);
//         deal({token: address(deXa), to: address(deXaPresale), give: 10000000e18});

//         deXaPresale.setRoundInfoForBusd(
//             0, 800000000000000000, block.timestamp, block.timestamp + 30 days, 4, 50000000e18, 150e18, 1500e18
//         );

//         deXaPresale.setRoundInfoForNtr(0, 160000000000000000000, 150e18, 5000e18);

//         changePrank(user1);

//         ntr.approve(address(deXaPresale), 4500e18);

//         deXaPresale.tokenPurchaseWithNTR(4500e18);

//         vm.warp(block.timestamp + 30 days * 12);
//         deXaPresale.claimTokensFromNtr(0);

//         assertEq(deXa.balanceOf(address(user1)), 28125000000000000000, "Amount not received as expected");
//     }

//     //After Bug report and its fixes
//     function testReinvestForUserByOwner() public {
//         vm.startPrank(user1);
//         busd.transfer(address(1), 500000 ether);
//         changePrank(user2);
//         busd.transfer(address(1), 500000 ether);
//         changePrank(owner);

//         busd.approve(address(deXaPresale), 10000e18);
//         deXaPresale.depositBusdForReward(10000e18);

//         uint256 ownerDexaBalanceDump = deXa.balanceOf(owner);
//         deXa.transfer(address(1), ownerDexaBalanceDump);

//         uint256 ownerBusdBalanceDump = busd.balanceOf(owner);
//         busd.transfer(address(1), ownerBusdBalanceDump);

//         uint16[] memory _rates = new uint16[](6);
//         _rates[0] = (600);
//         _rates[1] = (400);
//         _rates[2] = (200);
//         _rates[3] = (200);
//         _rates[4] = (200);
//         _rates[5] = (200);
//         deXaPresale.setReferralRate(_rates);
//         deal({token: address(deXa), to: address(deXaPresale), give: 50000000e18});

//         deXaPresale.setRoundInfoForBusd(
//             0, 800000000000000000, block.timestamp, block.timestamp + 30 days, 4, 50000000e18, 150e18, 1500e18
//         );

//         uint256 creationTimeOfRound = block.timestamp;

//         address[] memory _users = new address[](2);
//         _users[0] = address(user1);
//         _users[1] = address(user2);

//         uint256[] memory _allowances = new uint256[](2);
//         _allowances[0] = uint256(1500e18);
//         _allowances[1] = uint256(1500e18);

//         uint256[] memory _rounds = new uint256[](2);
//         _rounds[0] = 0;
//         _rounds[1] = 0;

//         deXaPresale.batchAllowanceToBusdUsers(_users, _allowances, _rounds, _allowances, creationTimeOfRound);

//         // vm.expectRevert("Already Deposited");
//         deXaPresale.batchAllowanceToBusdUsers(_users, _allowances, _rounds, _allowances, creationTimeOfRound);
//     }

//     function testReinvestForUsersByOwner() public {
//         vm.startPrank(user1);
//         busd.transfer(address(1), 500000 ether);
//         changePrank(user2);
//         busd.transfer(address(1), 500000 ether);
//         changePrank(owner);

//         busd.approve(address(deXaPresale), 10000e18);
//         deXaPresale.depositBusdForReward(10000e18);

//         uint256 ownerDexaBalanceDump = deXa.balanceOf(owner);
//         deXa.transfer(address(1), ownerDexaBalanceDump);

//         uint256 ownerBusdBalanceDump = busd.balanceOf(owner);
//         busd.transfer(address(1), ownerBusdBalanceDump);

//         uint16[] memory _rates = new uint16[](6);
//         _rates[0] = (600);
//         _rates[1] = (400);
//         _rates[2] = (200);
//         _rates[3] = (200);
//         _rates[4] = (200);
//         _rates[5] = (200);
//         deXaPresale.setReferralRate(_rates);
//         deal({token: address(deXa), to: address(deXaPresale), give: 50000000e18});

//         deXaPresale.setRoundInfoForBusd(
//             0, 800000000000000000, block.timestamp, block.timestamp + 30 days, 4, 50000000e18, 150e18, 1500e18
//         );
//         deXaPresale.allowanceToBusdUser(user1, 150e18, 0, block.timestamp);

//         // vm.expectRevert("Already Deposited");
//         deXaPresale.allowanceToBusdUser(user1, 150e18, 0, block.timestamp);
//     }

//     function testSoldOutCheck() public {
//         vm.startPrank(owner);
//         deal({token: address(deXa), to: address(deXaPresale), give: 50000000e18});
//         deXaPresale.setRoundInfoForBusd(
//             0, 800000000000000000, block.timestamp, block.timestamp + 30 days, 4, 250e18, 100e18, 1000e18
//         );

//         changePrank(user1);

//         busd.approve(address(deXaPresale), 1000e18);

//         deXaPresale.tokenPurchaseWithBUSD(100e18);

//         vm.expectRevert("Dexa is already sold out!");
//         deXaPresale.tokenPurchaseWithBUSD(500e18);
//     }

//     function testShouldFailedOnMultipleClaims() public {
//         vm.startPrank(owner);
//         deal({token: address(deXa), to: address(deXaPresale), give: 50000000e18});

//         uint16[] memory _rates = new uint16[](6);
//         _rates[0] = (600);
//         _rates[1] = (400);
//         _rates[2] = (200);
//         _rates[3] = (200);
//         _rates[4] = (200);
//         _rates[5] = (200);
//         deXaPresale.setReferralRate(_rates);

//         deXaPresale.setRoundInfoForBusd(
//             0, 800000000000000000, block.timestamp, block.timestamp + 30 days, 4, 50000000e18, 150e18, 1000e18
//         );

//         changePrank(user1);

//         busd.approve(address(deXaPresale), 1000e18);

//         deXaPresale.tokenPurchaseWithBUSD(150e18);

//         vm.warp(block.timestamp + 30 days * 12);

//         deXaPresale.claimTokensFromBusd(0);
//         // vm.expectRevert("Already Claimed");
//         deXaPresale.claimTokensFromBusd(0);
//     }

//     function testFuzzClaimDXCWithMonths(uint256 _months, uint256 _amounts) public {
//         vm.assume(_amounts > 1e18 && _amounts < busd.balanceOf(user1));
//         vm.assume(_amounts != 0);

//         vm.assume(_months < 9);
//         vm.assume(_months != 0);

//         vm.startPrank(owner);
//         deal({token: address(deXa), to: address(deXaPresale), give: 50000000e18});

//         deXaPresale.setRoundInfoForBusd(
//             0,
//             800000000000000000,
//             block.timestamp,
//             block.timestamp + 2 weeks,
//             4,
//             50000000e18,
//             _amounts,
//             busd.balanceOf(user1)
//         );

//         vm.startPrank(user1);
//         busd.approve(address(deXaPresale), _amounts);
//         deXaPresale.tokenPurchaseWithBUSD(_amounts);
//         vm.warp(block.timestamp + 30 days * 4);
//         vm.warp(block.timestamp + 30 days * _months);

//         uint256 balance = deXaPresale.getClaimableTokenAmountFromBusd(0, user1);

//         deXaPresale.claimTokensFromBusd(0);
//         assertEq(deXa.balanceOf(user1), balance, "Not Equal");
//     }

//     function testFuzzClaimDXC(uint256 _amounts) public {
//         vm.assume(_amounts > 10e18 && _amounts < 40000000e18);
//         vm.assume(_amounts != 0);

//         vm.startPrank(owner);
//         deal({token: address(deXa), to: address(deXaPresale), give: type(uint256).max});

//         deal({token: address(busd), to: address(user1), give: type(uint256).max});

//         deXaPresale.setRoundInfoForBusd(
//             0,
//             800000000000000000,
//             block.timestamp,
//             block.timestamp + 2 weeks,
//             4,
//             50000000e18,
//             _amounts,
//             type(uint256).max
//         );

//         vm.startPrank(user1);
//         busd.approve(address(deXaPresale), _amounts);
//         deXaPresale.tokenPurchaseWithBUSD(_amounts);

//         vm.warp(block.timestamp + 30 days * 12);

//         uint256 totalClaimableAmount = (_amounts * 1e18) / 800000000000000000;
//         deXaPresale.claimTokensFromBusd(0);
//         assertEq(deXa.balanceOf(user1), totalClaimableAmount, "Not Equal");
//     }

//     function testFuzzClaimDXCThroughOwnerAllowance(uint256 _amounts) public {
//         vm.assume(_amounts > 10e18 && _amounts < 40000000e18);
//         vm.assume(_amounts != 0);

//         vm.startPrank(owner);
//         deal({token: address(deXa), to: address(deXaPresale), give: type(uint256).max});

//         deal({token: address(busd), to: address(user1), give: type(uint256).max});

//         deXaPresale.setRoundInfoForBusd(
//             0,
//             800000000000000000,
//             block.timestamp,
//             block.timestamp + 2 weeks,
//             4,
//             100000000e18,
//             _amounts,
//             type(uint256).max
//         );

//         uint256 creationTimeOfRound = block.timestamp;

//         vm.startPrank(owner);
//         busd.approve(address(deXaPresale), _amounts);
//         deXaPresale.depositBusdForReward(_amounts);

//         address[] memory _users = new address[](2);
//         _users[0] = address(user1);
//         _users[1] = address(user2);

//         uint256[] memory _allowances = new uint256[](2);
//         _allowances[0] = uint256(_amounts);
//         _allowances[1] = uint256(_amounts);

//         uint256[] memory _rounds = new uint256[](2);
//         _rounds[0] = 0;
//         _rounds[1] = 0;

//         deXaPresale.batchAllowanceToBusdUsers(_users, _allowances, _rounds, _allowances, creationTimeOfRound);

//         vm.warp(block.timestamp + 30 days * 12);
//         uint256 totalClaimableAmount = (_amounts * 1e18) / 800000000000000000;
//         changePrank(user1);
//         deXaPresale.claimTokensFromBusd(0);
//         assertEq(deXa.balanceOf(user1), totalClaimableAmount, "Not Equal");

//         changePrank(user2);
//         deXaPresale.claimTokensFromBusd(0);
//         assertEq(deXa.balanceOf(user2), totalClaimableAmount, "Not Equal");
//     }

//     function testThreeRoundsPuchaseWithBusdAndNtrWithReferrals() public {
//         vm.startPrank(owner);
//         deal({token: address(deXa), to: address(deXaPresale), give: 50000000e18});

//         deal({token: address(ntr), to: address(deXaPresale), give: 50000000e18});

//         deal({token: address(busd), to: address(other), give: 50000000e18});

//         deXaPresale.setRoundInfoForBusd(
//             0, 800000000000000000, block.timestamp, block.timestamp + 2 weeks, 4, 50000000e18, 150e18, 1000e18
//         );

//         deXaPresale.setRoundInfoForNtr(0, 160000000000000000000, 150e18, 5000e18);

//         changePrank(user1);

//         busd.approve(address(deXaPresale), 1000e18);

//         deXaPresale.tokenPurchaseWithBUSD(150e18);

//         ntr.approve(address(deXaPresale), 1000e18);
//         deXaPresale.tokenPurchaseWithNTR(150e18);

//         vm.warp(block.timestamp + 30 days * 6);

//         changePrank(owner);
//         deXaPresale.setRoundInfoForBusd(
//             1, 1000000000000000000, block.timestamp, block.timestamp + 2 weeks, 4, 50000000e18, 150e18, 1000e18
//         );

//         deXaPresale.setRoundInfoForNtr(0, 160000000000000000000, 150e18, 5000e18);

//         changePrank(user1);
//         busd.approve(address(deXaPresale), 1000e18);
//         deXaPresale.tokenPurchaseWithBUSD(150e18);

//         changePrank(user2);
//         busd.approve(address(deXaPresale), 1000e18);
//         deXaPresale.tokenPurchaseWithBUSD(150e18);

//         vm.warp(block.timestamp + 30 days * 3);

//         changePrank(owner);
//         deXaPresale.setRoundInfoForBusd(
//             2, 1200000000000000000, block.timestamp, block.timestamp + 2 weeks, 4, 50000000e18, 150e18, 1000e18
//         );

//         deXaPresale.setRoundInfoForNtr(0, 160000000000000000000, 150e18, 5000e18);

//         changePrank(user1);
//         busd.approve(address(deXaPresale), 1000e18);
//         deXaPresale.tokenPurchaseWithBUSD(150e18);

//         changePrank(user2);
//         busd.approve(address(deXaPresale), 1000e18);
//         deXaPresale.tokenPurchaseWithBUSD(150e18);

//         changePrank(other);
//         busd.approve(address(deXaPresale), 1000e18);
//         deXaPresale.tokenPurchaseWithBUSD(150e18);

//         vm.warp(block.timestamp + 30 days * 5);

//         // 8 months claims
//         changePrank(user1);
//         deXaPresale.claimTokensFromBusd(0);
//         assertEq(deXa.balanceOf(user1), 187500000000000000000, "Not equal");

//         // 4 months claims
//         changePrank(user2);
//         deXaPresale.claimTokensFromBusd(1);
//         assertEq(deXa.balanceOf(user2), 75000000000000000000, "Not equal");

//         changePrank(user1);
//         // clear old claims
//         deXa.transfer(owner, deXa.balanceOf(user1));
//         deXaPresale.claimTokensFromBusd(1);
//         assertEq(deXa.balanceOf(user1), 75000000000000000000, "Not equal");

//         // 1 month claim
//         changePrank(other);
//         deXaPresale.claimTokensFromBusd(2);
//         assertEq(deXa.balanceOf(other), 15625000000000000000, "Not equal");

//         vm.warp(block.timestamp + 30 days * 12);

//         //try claim another times, not return any amount of DXC because already claimed
//         changePrank(user1);
//         deXa.transfer(owner, deXa.balanceOf(user1));
//         deXaPresale.claimTokensFromBusd(0);
//         assertEq(deXa.balanceOf(user1), 0, "Not equal");

//         changePrank(user2);
//         deXa.transfer(owner, deXa.balanceOf(user2));
//         deXaPresale.claimTokensFromBusd(1);
//         assertEq(deXa.balanceOf(user2), 75000000000000000000, "Not equal");
//         changePrank(user1);
//         deXa.transfer(owner, deXa.balanceOf(user1));
//         deXaPresale.claimTokensFromBusd(1);
//         assertEq(deXa.balanceOf(user1), 75000000000000000000, "Not equal");

//         changePrank(other);
//         deXa.transfer(owner, deXa.balanceOf(other));
//         deXaPresale.claimTokensFromBusd(2);
//         assertEq(deXa.balanceOf(other), 109375000000000000000, "Not equal");

//         //ntr claim
//         changePrank(user1);
//         // clear old claims
//         deXa.transfer(owner, deXa.balanceOf(user1));
//         deXaPresale.claimTokensFromNtr(0);
//         assertEq(deXa.balanceOf(user1), 937500000000000000, "Not equal");
//     }

//     function testBlacklistingFeature1() public {
//         vm.startPrank(owner);
//         address[] memory blacklisted = new address[](1);
//         blacklisted[0] = (0x2B5AD5c4795c026514f8317c7a215E218DcCD6cF);
//         deXaPresale.setBlacklistedUsers(blacklisted);

//         changePrank(user1);
//         busd.transfer(address(1), 500000 ether);
//         changePrank(user2);
//         busd.transfer(address(1), 500000 ether);
//         changePrank(owner);

//         busd.approve(address(deXaPresale), 10000e18);
//         deXaPresale.depositBusdForReward(10000e18);

//         uint256 ownerDexaBalanceDump = deXa.balanceOf(owner);
//         deXa.transfer(address(1), ownerDexaBalanceDump);

//         uint256 ownerBusdBalanceDump = busd.balanceOf(owner);
//         busd.transfer(address(1), ownerBusdBalanceDump);

//         uint16[] memory _rates = new uint16[](6);
//         _rates[0] = (600);
//         _rates[1] = (400);
//         _rates[2] = (200);
//         _rates[3] = (200);
//         _rates[4] = (200);
//         _rates[5] = (200);
//         deXaPresale.setReferralRate(_rates);
//         deal({token: address(deXa), to: address(deXaPresale), give: 50000000e18});

//         deXaPresale.setRoundInfoForBusd(
//             0, 800000000000000000, block.timestamp, block.timestamp + 30 days, 4, 50000000e18, 150e18, 1500e18
//         );

//         uint256 creationTimeOfRound = block.timestamp;

//         address[] memory _users = new address[](1);
//         // _users[0] = address(user1);
//         _users[0] = address(user2);

//         uint256[] memory _allowances = new uint256[](1);
//         // _allowances[0] = uint256(1500e18);
//         _allowances[0] = uint256(1500e18);

//         uint256[] memory _rounds = new uint256[](1);
//         _rounds[0] = 0;
//         // _rounds[1] = 0;

//         address[] memory referrerAddresses = register.getReferrerAddresses(user2);

//         deXaPresale.batchAllowanceToBusdUsers(_users, _allowances, _rounds, _allowances, creationTimeOfRound);

//         // level1 amount check
//         assertEq(busd.balanceOf(referrerAddresses[0]), 0, "Amount not match");
//         // level2 amount check
//         assertEq(busd.balanceOf(referrerAddresses[1]), 60000000000000000000, "Amount not match");
//     }

//     function testBlacklistingFeature2() public {
//         vm.startPrank(owner);
//         address[] memory blacklisted = new address[](1);
//         blacklisted[0] = (0x2B5AD5c4795c026514f8317c7a215E218DcCD6cF);
//         deXaPresale.setBlacklistedUsers(blacklisted);

//         changePrank(user1);
//         busd.transfer(address(1), 500000 ether);
//         changePrank(user2);
//         busd.transfer(address(1), 500000 ether);
//         changePrank(owner);

//         busd.approve(address(deXaPresale), 10000e18);
//         deXaPresale.depositBusdForReward(10000e18);

//         uint256 ownerDexaBalanceDump = deXa.balanceOf(owner);
//         deXa.transfer(address(1), ownerDexaBalanceDump);

//         uint256 ownerBusdBalanceDump = busd.balanceOf(owner);
//         busd.transfer(address(1), ownerBusdBalanceDump);

//         uint16[] memory _rates = new uint16[](6);
//         _rates[0] = (600);
//         _rates[1] = (400);
//         _rates[2] = (200);
//         _rates[3] = (200);
//         _rates[4] = (200);
//         _rates[5] = (200);
//         deXaPresale.setReferralRate(_rates);
//         deal({token: address(deXa), to: address(deXaPresale), give: 50000000e18});

//         deXaPresale.setRoundInfoForBusd(
//             0, 800000000000000000, block.timestamp, block.timestamp + 30 days, 4, 50000000e18, 150e18, 1500e18
//         );

//         uint256 creationTimeOfRound = block.timestamp;

//         address[] memory _users = new address[](2);
//         _users[0] = address(user1);
//         _users[1] = address(user2);

//         uint256[] memory _allowances = new uint256[](2);
//         _allowances[0] = uint256(1500e18);
//         _allowances[1] = uint256(1500e18);

//         uint256[] memory _rounds = new uint256[](2);
//         _rounds[0] = 0;
//         _rounds[1] = 1;

//         vm.expectRevert("Blacklisted User");
//         deXaPresale.batchAllowanceToBusdUsers(_users, _allowances, _rounds, _allowances, creationTimeOfRound);
//     }

//     function testBlacklistingFeature3() public {
//         vm.startPrank(owner);
//         address[] memory blacklisted = new address[](1);
//         blacklisted[0] = (0x2B5AD5c4795c026514f8317c7a215E218DcCD6cF);
//         deXaPresale.setBlacklistedUsers(blacklisted);

//         changePrank(user1);
//         busd.transfer(address(1), 500000 ether);
//         changePrank(user2);
//         busd.transfer(address(1), 500000 ether);
//         changePrank(owner);

//         busd.approve(address(deXaPresale), 10000e18);
//         deXaPresale.depositBusdForReward(10000e18);

//         uint256 ownerDexaBalanceDump = deXa.balanceOf(owner);
//         deXa.transfer(address(1), ownerDexaBalanceDump);

//         uint256 ownerBusdBalanceDump = busd.balanceOf(owner);
//         busd.transfer(address(1), ownerBusdBalanceDump);

//         uint16[] memory _rates = new uint16[](6);
//         _rates[0] = (600);
//         _rates[1] = (400);
//         _rates[2] = (200);
//         _rates[3] = (200);
//         _rates[4] = (200);
//         _rates[5] = (200);
//         deXaPresale.setReferralRate(_rates);
//         deal({token: address(deXa), to: address(deXaPresale), give: 50000000e18});

//         deXaPresale.setRoundInfoForBusd(
//             0, 800000000000000000, block.timestamp, block.timestamp + 30 days, 4, 50000000e18, 150e18, 1500e18
//         );

//         uint256 creationTimeOfRound = block.timestamp;

//         vm.expectRevert("Blacklisted User");
//         deXaPresale.allowanceToBusdUser(user1, 1500e18, 0, creationTimeOfRound);
//     }

//     // function testBlacklistingFeature4() public {
//     //     vm.startPrank(owner);
//     //     address[] memory blacklisted = new address[](1);
//     //     blacklisted[0] = (0x2B5AD5c4795c026514f8317c7a215E218DcCD6cF);
//     //     deXaPresale.setBlacklistedUsers(blacklisted);

//     //     changePrank(user1);
//     //     busd.transfer(address(1), 500000 ether);
//     //     changePrank(user2);
//     //     busd.transfer(address(1), 500000 ether);
//     //     changePrank(owner);

//     //     busd.approve(address(deXaPresale), 10000e18);
//     //     deXaPresale.depositBusdForReward(10000e18);

//     //     uint256 ownerDexaBalanceDump = deXa.balanceOf(owner);
//     //     deXa.transfer(address(1), ownerDexaBalanceDump);

//     //     uint256 ownerBusdBalanceDump = busd.balanceOf(owner);
//     //     busd.transfer(address(1), ownerBusdBalanceDump);

//     //     uint16[] memory _rates = new uint16[](6);
//     //     _rates[0] = (600);
//     //     _rates[1] = (400);
//     //     _rates[2] = (200);
//     //     _rates[3] = (200);
//     //     _rates[4] = (200);
//     //     _rates[5] = (200);
//     //     deXaPresale.setReferralRate(_rates);
//     //     deal({token: address(deXa), to: address(deXaPresale), give: 50000000e18});

//     //     deXaPresale.setRoundInfoForBusd(
//     //         0, 800000000000000000, block.timestamp, block.timestamp + 30 days, 4, 50000000e18, 150e18, 1500e18
//     //     );

//     //     // vm.expectRevert("Blacklisted User");

//     //     changePrank(user1);
//     //     deXaPresale.tokenPurchaseWithBUSD(1500e18);
//     // }

//     function testBlacklistingFeature5() public {
//         vm.startPrank(owner);

//         address[] memory blacklisted = new address[](2);
//         blacklisted[0] = (user1);
//         blacklisted[1] = (user2);
//         deXaPresale.setBlacklistedUsers(blacklisted);

//         changePrank(user1);
//         busd.transfer(address(1), 500000 ether);
//         changePrank(user2);
//         busd.transfer(address(1), 500000 ether);
//         changePrank(owner);

//         busd.approve(address(deXaPresale), 10000e18);
//         deXaPresale.depositBusdForReward(10000e18);

//         uint256 ownerDexaBalanceDump = deXa.balanceOf(owner);
//         deXa.transfer(address(1), ownerDexaBalanceDump);

//         uint256 ownerBusdBalanceDump = busd.balanceOf(owner);
//         busd.transfer(address(1), ownerBusdBalanceDump);

//         uint16[] memory _rates = new uint16[](6);
//         _rates[0] = (600);
//         _rates[1] = (400);
//         _rates[2] = (200);
//         _rates[3] = (200);
//         _rates[4] = (200);
//         _rates[5] = (200);
//         deXaPresale.setReferralRate(_rates);
//         deal({token: address(deXa), to: address(deXaPresale), give: 50000000e18});

//         deXaPresale.setRoundInfoForBusd(
//             0, 800000000000000000, block.timestamp, block.timestamp + 30 days, 4, 50000000e18, 150e18, 1500e18
//         );

//         uint256 creationTimeOfRound = block.timestamp;

//         address[] memory _users = new address[](1);
//         // _users[0] = address(user1);
//         _users[0] = address(other);

//         uint256[] memory _allowances = new uint256[](1);
//         // _allowances[0] = uint256(1500e18);
//         _allowances[0] = uint256(1500e18);

//         uint256[] memory _rounds = new uint256[](1);
//         _rounds[0] = 0;
//         // _rounds[1] = 0;

//         address[] memory referrerAddresses = register.getReferrerAddresses(user2);

//         deXaPresale.batchAllowanceToBusdUsers(_users, _allowances, _rounds, _allowances, creationTimeOfRound);

//         // level1 amount check
//         assertEq(busd.balanceOf(referrerAddresses[0]), 0, "Amount not match");

//         // // level2 amount check
//         assertEq(busd.balanceOf(referrerAddresses[1]), 30000000000000000000, "Amount not match");
//     }

//     function testBatchBusdTransfers1() public {
//         vm.startPrank(owner);

//         changePrank(user1);
//         busd.transfer(address(1), 500000 ether);
//         changePrank(user2);
//         busd.transfer(address(1), 500000 ether);
//         changePrank(owner);

//         busd.approve(address(deXaPresale), 10000e18);
//         deXaPresale.depositBusdForReward(10000e18);

//         uint256 ownerDexaBalanceDump = deXa.balanceOf(owner);
//         deXa.transfer(address(1), ownerDexaBalanceDump);

//         uint256 ownerBusdBalanceDump = busd.balanceOf(owner);
//         busd.transfer(address(1), ownerBusdBalanceDump);

//         uint16[] memory _rates = new uint16[](6);
//         _rates[0] = (600);
//         _rates[1] = (400);
//         _rates[2] = (200);
//         _rates[3] = (200);
//         _rates[4] = (200);
//         _rates[5] = (200);

//         deXaPresale.setReferralRate(_rates);
//         deal({token: address(deXa), to: address(deXaPresale), give: 50000000e18});

//         deXaPresale.setRoundInfoForBusd(
//             0, 800000000000000000, block.timestamp, block.timestamp + 30 days, 4, 50000000e18, 150e18, 1500e18
//         );

//         uint256 creationTimeOfRound = block.timestamp;

//         address[] memory _users = new address[](2);
//         _users[0] = address(user1);
//         _users[1] = address(other);

//         uint256[] memory _allowances = new uint256[](2);
//         _allowances[0] = uint256(1500e18);
//         _allowances[1] = uint256(1500e18);

//         uint256[] memory _rounds = new uint256[](2);
//         _rounds[0] = 0;
//         _rounds[1] = 0;

//         uint256[] memory _amountForReward = new uint256[](2);
//         _amountForReward[0] = uint256(0);
//         _amountForReward[1] = uint256(0);

//         address[] memory referrerAddresses = register.getReferrerAddresses(user2);

//         deXaPresale.batchAllowanceToBusdUsers(_users, _allowances, _rounds, _amountForReward, creationTimeOfRound);

//         // level1 amount check
//         assertEq(busd.balanceOf(referrerAddresses[0]), 0, "Amount not match");

//         // // level2 amount check
//         assertEq(busd.balanceOf(referrerAddresses[1]), 0, "Amount not match");
//     }

//     function testBatchBusdTransfers2() public {
//         vm.startPrank(owner);

//         changePrank(user1);
//         busd.transfer(address(1), 500000 ether);
//         changePrank(user2);
//         busd.transfer(address(1), 500000 ether);
//         changePrank(owner);

//         busd.approve(address(deXaPresale), 10000e18);
//         deXaPresale.depositBusdForReward(10000e18);

//         uint256 ownerDexaBalanceDump = deXa.balanceOf(owner);
//         deXa.transfer(address(1), ownerDexaBalanceDump);

//         uint256 ownerBusdBalanceDump = busd.balanceOf(owner);
//         busd.transfer(address(1), ownerBusdBalanceDump);

//         uint16[] memory _rates = new uint16[](6);
//         _rates[0] = (600);
//         _rates[1] = (400);
//         _rates[2] = (200);
//         _rates[3] = (200);
//         _rates[4] = (200);
//         _rates[5] = (200);

//         deXaPresale.setReferralRate(_rates);
//         deal({token: address(deXa), to: address(deXaPresale), give: 50000000e18});

//         deXaPresale.setRoundInfoForBusd(
//             0, 800000000000000000, block.timestamp, block.timestamp + 30 days, 4, 50000000e18, 150e18, 1500e18
//         );

//         uint256 creationTimeOfRound = block.timestamp;

//         address[] memory _users = new address[](2);
//         _users[0] = address(user1);
//         _users[1] = address(other);

//         uint256[] memory _allowances = new uint256[](2);
//         _allowances[0] = uint256(1500e18);
//         _allowances[1] = uint256(1500e18);

//         uint256[] memory _rounds = new uint256[](2);
//         _rounds[0] = 0;
//         _rounds[1] = 0;

//         uint256[] memory _amountForReward = new uint256[](2);
//         _amountForReward[0] = uint256(750e18);
//         _amountForReward[1] = uint256(0);

//         address[] memory referrerAddresses = register.getReferrerAddresses(user2);

//         deXaPresale.batchAllowanceToBusdUsers(_users, _allowances, _rounds, _amountForReward, creationTimeOfRound);

//         assertEq(busd.balanceOf(referrerAddresses[0]), 0, "Amount not match");
//         assertEq(busd.balanceOf(referrerAddresses[1]), 45e18, "Amount not match");
//     }

//     // function testThreeRoundsPuchaseWithBusdAndNtrWithTenMonthsRelease() public {
//     //     vm.startPrank(owner);
//     //     deal({token: address(deXa), to: address(deXaPresale), give: 50000000e18});

//     //     deal({token: address(ntr), to: address(deXaPresale), give: 50000000e18});

//     //     deal({token: address(busd), to: address(other), give: 50000000e18});

//     //     deXaPresale.setRoundInfoForBusd(
//     //         0, 800000000000000000, block.timestamp, block.timestamp + 2 weeks, 4, 50000000e18, 150e18, 1000e18
//     //     );

//     //     deXaPresale.setRoundInfoForNtr(0, 160000000000000000000, 150e18, 5000e18);

//     //     changePrank(user1);

//     //     busd.approve(address(deXaPresale), 1000e18);

//     //     deXaPresale.tokenPurchaseWithBUSD(150e18);

//     //     ntr.approve(address(deXaPresale), 1000e18);
//     //     deXaPresale.tokenPurchaseWithNTR(150e18);

//     //     vm.warp(block.timestamp + 30 days * 6);

//     //     changePrank(owner);
//     //     deXaPresale.setRoundInfoForBusd(
//     //         1, 1000000000000000000, block.timestamp, block.timestamp + 2 weeks, 4, 50000000e18, 150e18, 1000e18
//     //     );

//     //     deXaPresale.setRoundInfoForNtr(0, 160000000000000000000, 150e18, 5000e18);

//     //     changePrank(user1);
//     //     busd.approve(address(deXaPresale), 1000e18);
//     //     deXaPresale.tokenPurchaseWithBUSD(150e18);

//     //     changePrank(user2);
//     //     busd.approve(address(deXaPresale), 1000e18);
//     //     deXaPresale.tokenPurchaseWithBUSD(150e18);

//     //     vm.warp(block.timestamp + 30 days * 3);

//     //     changePrank(owner);
//     //     deXaPresale.setRoundInfoForBusd(
//     //         2, 1200000000000000000, block.timestamp, block.timestamp + 2 weeks, 4, 50000000e18, 150e18, 1000e18
//     //     );

//     //     deXaPresale.setRoundInfoForNtr(0, 160000000000000000000, 150e18, 5000e18);

//     //     changePrank(user1);
//     //     busd.approve(address(deXaPresale), 1000e18);
//     //     deXaPresale.tokenPurchaseWithBUSD(150e18);

//     //     changePrank(user2);
//     //     busd.approve(address(deXaPresale), 1000e18);
//     //     deXaPresale.tokenPurchaseWithBUSD(150e18);

//     //     changePrank(other);
//     //     busd.approve(address(deXaPresale), 1000e18);
//     //     deXaPresale.tokenPurchaseWithBUSD(150e18);

//     //     vm.warp(block.timestamp + 30 days * 5);

//     //     // 14 months claims
//     //     changePrank(user1);
//     //     deXaPresale.claimTokensFromBusd(0);
//     //     assertEq(deXa.balanceOf(user1), 187500000000000000000, "Not equal");

//     //     // 4 months claims
//     //     changePrank(user2);
//     //     deXaPresale.claimTokensFromBusd(1);
//     //     assertEq(deXa.balanceOf(user2), 60000000000000000000, "Not equal");

//     //     changePrank(user1);
//     //     // clear old claims
//     //     deXa.transfer(owner, deXa.balanceOf(user1));
//     //     deXaPresale.claimTokensFromBusd(1);
//     //     assertEq(deXa.balanceOf(user1), 60000000000000000000, "Not equal");

//     //     // 1 month claim
//     //     changePrank(other);
//     //     deXaPresale.claimTokensFromBusd(2);
//     //     assertEq(deXa.balanceOf(other), 12500000000000000000, "Not equal");

//     //     vm.warp(block.timestamp + 30 days * 12);

//     //     //try claim another times, not return any amount of DXC because already claimed
//     //     changePrank(user1);
//     //     deXa.transfer(owner, deXa.balanceOf(user1));
//     //     deXaPresale.claimTokensFromBusd(0);
//     //     assertEq(deXa.balanceOf(user1), 0, "Not equal");

//     //     changePrank(user2);
//     //     deXa.transfer(owner, deXa.balanceOf(user2));
//     //     deXaPresale.claimTokensFromBusd(1);
//     //     assertEq(deXa.balanceOf(user2), 90000000000000000000, "Not equal");
//     //     changePrank(user1);
//     //     deXa.transfer(owner, deXa.balanceOf(user1));
//     //     deXaPresale.claimTokensFromBusd(1);
//     //     assertEq(deXa.balanceOf(user1), 90000000000000000000, "Not equal");

//     //     changePrank(other);
//     //     deXa.transfer(owner, deXa.balanceOf(other));
//     //     deXaPresale.claimTokensFromBusd(2);
//     //     assertEq(deXa.balanceOf(other), 112500000000000000000, "Not equal");

//     //     //ntr claim
//     //     changePrank(user1);
//     //     // clear old claims
//     //     deXa.transfer(owner, deXa.balanceOf(user1));
//     //     deXaPresale.claimTokensFromNtr(0);
//     //     assertEq(deXa.balanceOf(user1), 937500000000000000, "Not equal");
//     // }

//     // test according in minutes
//     // function testSetRound0AndPurchaseWithMinBUSD() public {
//     //     vm.startPrank(owner);
//     //     deal({token: address(deXa), to: address(deXaPresale), give: 50000000e18});
//     //     deXaPresale.setRoundInfoForBusd(
//     //         0, 800000000000000000, block.timestamp, block.timestamp + 30 days, 4, 50000000e18, 150e18, 1000e18
//     //     );

//     //     changePrank(user1);

//     //     busd.approve(address(deXaPresale), 1000e18);

//     //     deXaPresale.tokenPurchaseWithBUSD(150e18);

//     //     vm.warp(block.timestamp + 3 hours);

//     //     deXaPresale.claimTokensFromBusd(0);

//     //     assertEq(deXa.balanceOf(address(user1)), 187500000000000000000, "Amount not received as expected");
//     // }
// }
