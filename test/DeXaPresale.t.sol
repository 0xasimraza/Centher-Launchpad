// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../src/DeXaPresale.sol";
import "../src/utils/Token.sol";
import "../src/utils/CentherRegistration.sol";

import "forge-std/console2.sol";

contract TokenTest is Test {
    address payable internal owner;
    address payable internal user1;
    address payable internal user2;
    address payable internal other;

    Token deXa;
    Token busd;
    Token wbnb;

    CentherRegistration register;

    DeXaPresale deXaPresale;

    function setUp() public {
        owner = payable(vm.addr(1));
        user1 = payable(vm.addr(2));
        user2 = payable(vm.addr(3));
        other = payable(vm.addr(4));

        console2.log(" ---- owner ----", owner);
        console2.log(" ---- user1 ----", user1);
        console2.log(" ---- user2 ----", user2);
        console2.log(" ---- other ----", other);

        vm.startPrank(owner);
        deXa = new Token("deXa", "DXC");
        busd = new Token("Binance USD", "BUSD");
        wbnb = new Token("Wrapped BNB", "WBNB");

        busd.transfer(user1, 500000e18);
        busd.transfer(user2, 500000e18);

        wbnb.transfer(user1, 500000e18);
        wbnb.transfer(user2, 500000e18);

        register = new CentherRegistration();
        register.setOperator(address(owner));

        address[] memory _users = new address[](3);
        _users[0] = address(user1);
        _users[1] = address(user2);
        _users[2] = address(other);

        address[] memory _refs = new address[](3);
        _refs[0] = address(owner);
        _refs[1] = address(user1);
        _refs[2] = address(user2);

        register.registerForOwnerBatch(_users, _refs);

        address zero = address(0);
        deXaPresale = new DeXaPresale(
            address(deXa),
            address(zero),
            address(busd),
            address(register),
            address(zero),
            address(zero)
        );
        vm.stopPrank();
    }

    function testDeployments() public view {
        assert(address(deXa) != address(0));
        assert(address(deXaPresale) != address(0));
    }

    function testUserAllowance() public {
        vm.startPrank(owner);
        deal({
            token: address(deXa),
            to: address(deXaPresale),
            give: 50000000e18
        });
        deXaPresale.setRoundInfoForBusd(
            0,
            800000000000000000,
            block.timestamp,
            block.timestamp + 30 days,
            1,
            50000000e18,
            150e18,
            1000e18
        );

        deXaPresale.allowanceToUser(user1, 150e18, 0);

        // assertEq(
        //     deXaPresale.claimableTokens(address(user1)),
        //     150e18,
        //     "Amount mismatched"
        // );
    }

    function testUsersAllowance() public {
        vm.startPrank(owner);

        deal({
            token: address(deXa),
            to: address(deXaPresale),
            give: 50000000e18
        });
        deXaPresale.setRoundInfoForBusd(
            0,
            800000000000000000,
            block.timestamp,
            block.timestamp + 30 days,
            1,
            50000000e18,
            5e18,
            1000e18
        );

        address[] memory _users = new address[](2);
        _users[0] = address(user1);
        _users[1] = address(user2);

        uint256[] memory _allowances = new uint256[](2);
        _allowances[0] = uint256(100e18);
        _allowances[1] = uint256(10e18);

        uint256[] memory _rounds = new uint256[](2);
        _rounds[0] = 0;
        _rounds[1] = 0;

        deXaPresale.batchAllowanceToUsers(_users, _allowances, _rounds);

        // uint256 _amount0 = deXaPresale.claimableTokens(_users[0]);
        // uint256 _amount1 = deXaPresale.claimableTokens(_users[1]);

        // assertEq(_amount0, _allowances[0], "Amount mismatched");
        // assertEq(_amount1, _allowances[1], "Amount mismatched");
    }

    function testSetRound0AndPurchaseWithMinBUSD() public {
        vm.startPrank(owner);
        deal({
            token: address(deXa),
            to: address(deXaPresale),
            give: 50000000e18
        });
        deXaPresale.setRoundInfoForBusd(
            0,
            800000000000000000,
            block.timestamp,
            block.timestamp + 30 days,
            4,
            50000000e18,
            150e18,
            1000e18
        );

        changePrank(user1);

        busd.approve(address(deXaPresale), 1000e18);

        deXaPresale.tokenPurchaseWithBUSD(150e18);

        vm.warp(block.timestamp + 30 days * 12);

        deXaPresale.claimTokensFromBusd(0);

        assertEq(
            deXa.balanceOf(address(user1)),
            187500000000000000000,
            "Amount not received as expected"
        );
    }

    function testSetRound0AndPurchaseWithMaxBUSD() public {
        vm.startPrank(owner);

        deal({token: address(deXa), to: address(deXaPresale), give: 500000e18});

        deXaPresale.setRoundInfoForBusd(
            0,
            800000000000000000,
            block.timestamp,
            block.timestamp + 30 days,
            4,
            10000e18,
            150e18,
            5000e18
        );

        vm.stopPrank();
        vm.startPrank(user1);

        busd.approve(address(deXaPresale), 4500e18);

        deXaPresale.tokenPurchaseWithBUSD(4500e18);

        vm.warp(block.timestamp + 30 days * 12);
        deXaPresale.claimTokensFromBusd(0);

        assertEq(
            deXa.balanceOf(address(user1)),
            5625000000000000000000,
            "Amount not received as expected"
        );
    }

    function testSetRound1AndPurchaseWithMaxBUSD() public {
        vm.startPrank(owner);
        deal({
            token: address(deXa),
            to: address(deXaPresale),
            give: 50000000e18
        });
        deXaPresale.setRoundInfoForBusd(
            0,
            800000000000000000,
            block.timestamp,
            block.timestamp + 30 days,
            4,
            1000e18,
            150e18,
            5000e18
        );
        vm.warp(block.timestamp + 31 days * 4);

        //round2
        deXaPresale.setRoundInfoForBusd(
            1,
            800000000000000000,
            block.timestamp,
            block.timestamp + 30 days,
            4,
            50000000e18,
            150e18,
            5000e18
        );

        vm.stopPrank();
        vm.startPrank(user1);

        busd.approve(address(deXaPresale), 4500e18);

        deXaPresale.tokenPurchaseWithBUSD(4500e18);

        vm.warp(block.timestamp + 30 days * 12);

        deXaPresale.claimTokensFromBusd(1);

        assertEq(
            deXa.balanceOf(address(user1)),
            5625000000000000000000,
            "Amount not received as expected"
        );
    }

    function testClaimTokens() public {
        vm.startPrank(owner);
        deal({
            token: address(deXa),
            to: address(deXaPresale),
            give: 50000000e18
        });
        deXaPresale.setRoundInfoForBusd(
            0,
            800000000000000000,
            block.timestamp,
            block.timestamp + 30 days,
            4,
            50000000e18,
            150e18,
            1000e18
        );

        address[] memory _users = new address[](2);
        _users[0] = address(user1);
        _users[1] = address(user2);

        uint256[] memory _allowances = new uint256[](2);
        _allowances[0] = uint256(150e18);
        _allowances[1] = uint256(150e18);

        uint256[] memory _rounds = new uint256[](2);
        _rounds[0] = 0;
        _rounds[1] = 0;

        deXaPresale.batchAllowanceToUsers(_users, _allowances, _rounds);

        changePrank(user1);

        vm.warp(block.timestamp + 30 days * 12);
        deXaPresale.claimTokensFromBusd(0);

        assertEq(
            deXa.balanceOf(user1),
            187500000000000000000,
            "Not received claimable amount"
        );
    }

    // wbnb cases
    function testSetRound0AndPurchaseWithMaxWBNB() public {
        vm.startPrank(owner);
        deXaPresale.changeTokenAddress(address(wbnb));

        deal({
            token: address(deXa),
            to: address(deXaPresale),
            give: 10000000e18
        });

        deXaPresale.setRoundInfoForERC20(
            0,
            6230000000000000,
            block.timestamp,
            block.timestamp + 30 days,
            4,
            1000e18,
            150e18,
            5000e18
        );

        changePrank(user1);

        wbnb.approve(address(deXaPresale), 4500e18);

        deXaPresale.tokenPurchaseWithERC20(4500e18);

        vm.warp(block.timestamp + 30 days * 12);
        deXaPresale.claimTokensFromERC20(0);

        assertEq(
            deXa.balanceOf(address(user1)),
            722311396468699839486356,
            "Amount not received as expected"
        );
    }

    // wbnb cases
    function testClaimDexaTwoTimesWithMaxWBNB() public {
        vm.startPrank(owner);
        deXaPresale.changeTokenAddress(address(wbnb));

        deal({
            token: address(deXa),
            to: address(deXaPresale),
            give: 10000000e18
        });

        deXaPresale.setRoundInfoForERC20(
            0,
            6230000000000000,
            block.timestamp,
            block.timestamp + 30 days,
            4,
            1000e18,
            150e18,
            5000e18
        );

        vm.stopPrank();
        vm.startPrank(user1);

        wbnb.approve(address(deXaPresale), 4500e18);

        deXaPresale.tokenPurchaseWithERC20(4500e18);

        vm.warp(block.timestamp + 30 days * 5);
        deXaPresale.claimTokensFromERC20(0);
        uint256 balanceAfter1stClaim = deXa.balanceOf(address(user1));
        assertEq(
            balanceAfter1stClaim,
            90288924558587479935794,
            "Amount not received as expected"
        );
        vm.warp(block.timestamp + 30 days);
        deXaPresale.claimTokensFromERC20(0);
        uint256 balanceAfter2ndClaim = deXa.balanceOf(address(user1));
        assertEq(
            balanceAfter2ndClaim,
            180577849117174959871589,
            "Amount not received as expected"
        );
    }

    function testRewardAmountForReferral() public {
        //clear balances
        vm.startPrank(user1);
        busd.transfer(address(1), 500000 ether);
        changePrank(user2);
        busd.transfer(address(1), 500000 ether);

        changePrank(owner);

        busd.approve(address(deXaPresale), 10000e18);
        deXaPresale.depositBusdForReward(10000e18);

        uint256 ownerDexaBalanceDump = deXa.balanceOf(owner);
        deXa.transfer(address(1), ownerDexaBalanceDump);

        uint256 ownerBusdBalanceDump = busd.balanceOf(owner);
        busd.transfer(address(1), ownerBusdBalanceDump);

        uint16[] memory _rates = new uint16[](6);
        _rates[0] = (600);
        _rates[1] = (400);
        _rates[2] = (200);
        _rates[3] = (200);
        _rates[4] = (200);
        _rates[5] = (200);
        deXaPresale.setReferralRate(_rates);
        deal({
            token: address(deXa),
            to: address(deXaPresale),
            give: 50000000e18
        });

        deXaPresale.setRoundInfoForBusd(
            0,
            800000000000000000,
            block.timestamp,
            block.timestamp + 30 days,
            4,
            50000000e18,
            150e18,
            1000e18
        );

        address[] memory _users = new address[](2);
        _users[0] = address(user1);
        _users[1] = address(user2);

        uint256[] memory _allowances = new uint256[](2);
        _allowances[0] = uint256(150e18);
        _allowances[1] = uint256(150e18);

        uint256[] memory _rounds = new uint256[](2);
        _rounds[0] = 0;
        _rounds[1] = 0;

        address[] memory referrerAddresses = register.getReferrerAddresses(
            user2
        );

        deXaPresale.batchAllowanceToUsers(_users, _allowances, _rounds);

        // level1 amount check
        assertEq(
            busd.balanceOf(referrerAddresses[0]),
            9000000000000000000,
            "Amount not match"
        );
        // level2 amount check
        assertEq(
            busd.balanceOf(referrerAddresses[1]),
            15000000000000000000,
            "Amount not match"
        );
    }

    function testBigRewardAmountForReferral() public {
        vm.startPrank(user1);
        busd.transfer(address(1), 500000 ether);
        changePrank(user2);
        busd.transfer(address(1), 500000 ether);
        changePrank(owner);

        busd.approve(address(deXaPresale), 10000e18);
        deXaPresale.depositBusdForReward(10000e18);

        uint256 ownerDexaBalanceDump = deXa.balanceOf(owner);
        deXa.transfer(address(1), ownerDexaBalanceDump);

        uint256 ownerBusdBalanceDump = busd.balanceOf(owner);
        busd.transfer(address(1), ownerBusdBalanceDump);

        uint16[] memory _rates = new uint16[](6);
        _rates[0] = (600);
        _rates[1] = (400);
        _rates[2] = (200);
        _rates[3] = (200);
        _rates[4] = (200);
        _rates[5] = (200);
        deXaPresale.setReferralRate(_rates);
        deal({
            token: address(deXa),
            to: address(deXaPresale),
            give: 50000000e18
        });

        deXaPresale.setRoundInfoForBusd(
            0,
            800000000000000000,
            block.timestamp,
            block.timestamp + 30 days,
            4,
            50000000e18,
            150e18,
            1500e18
        );

        address[] memory _users = new address[](2);
        _users[0] = address(user1);
        _users[1] = address(user2);

        uint256[] memory _allowances = new uint256[](2);
        _allowances[0] = uint256(1500e18);
        _allowances[1] = uint256(1500e18);

        uint256[] memory _rounds = new uint256[](2);
        _rounds[0] = 0;
        _rounds[1] = 0;

        address[] memory referrerAddresses = register.getReferrerAddresses(
            user2
        );

        deXaPresale.batchAllowanceToUsers(_users, _allowances, _rounds);

        // level1 amount check
        assertEq(
            busd.balanceOf(referrerAddresses[0]),
            90000000000000000000,
            "Amount not match"
        );
        // level2 amount check
        assertEq(
            busd.balanceOf(referrerAddresses[1]),
            150000000000000000000,
            "Amount not match"
        );
    }

    function testSetReferralRateshouldFailInvalidInput() public {
        bytes4 selector = bytes4(keccak256("InvalidInputLength()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        vm.startPrank(owner);
        uint16[] memory _rates = new uint16[](8);
        _rates[0] = (600);
        _rates[1] = (400);
        _rates[2] = (200);
        _rates[3] = (200);
        deXaPresale.setReferralRate(_rates);
    }

    //After Bug report and its fixes
    function testReinvestForUserByOwner() public {
        vm.startPrank(user1);
        busd.transfer(address(1), 500000 ether);
        changePrank(user2);
        busd.transfer(address(1), 500000 ether);
        changePrank(owner);

        busd.approve(address(deXaPresale), 10000e18);
        deXaPresale.depositBusdForReward(10000e18);

        uint256 ownerDexaBalanceDump = deXa.balanceOf(owner);
        deXa.transfer(address(1), ownerDexaBalanceDump);

        uint256 ownerBusdBalanceDump = busd.balanceOf(owner);
        busd.transfer(address(1), ownerBusdBalanceDump);

        uint16[] memory _rates = new uint16[](6);
        _rates[0] = (600);
        _rates[1] = (400);
        _rates[2] = (200);
        _rates[3] = (200);
        _rates[4] = (200);
        _rates[5] = (200);
        deXaPresale.setReferralRate(_rates);
        deal({
            token: address(deXa),
            to: address(deXaPresale),
            give: 50000000e18
        });

        deXaPresale.setRoundInfoForBusd(
            0,
            800000000000000000,
            block.timestamp,
            block.timestamp + 30 days,
            4,
            50000000e18,
            150e18,
            1500e18
        );

        address[] memory _users = new address[](2);
        _users[0] = address(user1);
        _users[1] = address(user2);

        uint256[] memory _allowances = new uint256[](2);
        _allowances[0] = uint256(1500e18);
        _allowances[1] = uint256(1500e18);

        uint256[] memory _rounds = new uint256[](2);
        _rounds[0] = 0;
        _rounds[1] = 0;

        deXaPresale.batchAllowanceToUsers(_users, _allowances, _rounds);

        vm.expectRevert("Already Deposited");
        deXaPresale.batchAllowanceToUsers(_users, _allowances, _rounds);
    }

    function testReinvestForUsersByOwner() public {
        vm.startPrank(user1);
        busd.transfer(address(1), 500000 ether);
        changePrank(user2);
        busd.transfer(address(1), 500000 ether);
        changePrank(owner);

        busd.approve(address(deXaPresale), 10000e18);
        deXaPresale.depositBusdForReward(10000e18);

        uint256 ownerDexaBalanceDump = deXa.balanceOf(owner);
        deXa.transfer(address(1), ownerDexaBalanceDump);

        uint256 ownerBusdBalanceDump = busd.balanceOf(owner);
        busd.transfer(address(1), ownerBusdBalanceDump);

        uint16[] memory _rates = new uint16[](6);
        _rates[0] = (600);
        _rates[1] = (400);
        _rates[2] = (200);
        _rates[3] = (200);
        _rates[4] = (200);
        _rates[5] = (200);
        deXaPresale.setReferralRate(_rates);
        deal({
            token: address(deXa),
            to: address(deXaPresale),
            give: 50000000e18
        });

        deXaPresale.setRoundInfoForBusd(
            0,
            800000000000000000,
            block.timestamp,
            block.timestamp + 30 days,
            4,
            50000000e18,
            150e18,
            1500e18
        );
        deXaPresale.allowanceToUser(user1, 150e18, 0);

        vm.expectRevert("Already Deposited");
        deXaPresale.allowanceToUser(user1, 150e18, 0);
    }

    function testSoldOutCheck() public {
        vm.startPrank(owner);
        deal({
            token: address(deXa),
            to: address(deXaPresale),
            give: 50000000e18
        });
        deXaPresale.setRoundInfoForBusd(
            0,
            800000000000000000,
            block.timestamp,
            block.timestamp + 30 days,
            4,
            250e18,
            100e18,
            1000e18
        );

        changePrank(user1);

        busd.approve(address(deXaPresale), 1000e18);

        deXaPresale.tokenPurchaseWithBUSD(100e18);

        vm.expectRevert("Dexa is already sold out!");
        deXaPresale.tokenPurchaseWithBUSD(500e18);
    }
}
