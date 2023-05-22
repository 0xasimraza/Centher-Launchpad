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

    CentherRegistration register;

    DeXaPresale deXaPresale;

    function setUp() public {
        owner = payable(vm.addr(1));
        user1 = payable(vm.addr(2));
        user2 = payable(vm.addr(3));
        other = payable(vm.addr(4));

        vm.startPrank(owner);
        deXa = new Token("deXa", "DXC");
        busd = new Token("Binance USD", "BUSD");

        busd.transfer(user1, 500000e18);

        register = new CentherRegistration();
        register.setOperator(address(owner));

        address[] memory _users = new address[](3);
        _users[0] = address(user1);
        _users[1] = address(user2);
        _users[2] = address(other);

        address[] memory _refs = new address[](3);
        _refs[0] = address(owner);
        _refs[1] = address(owner);
        _refs[2] = address(owner);

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

    function testDeployments() public {
        assert(address(deXa) != address(0));
        assert(address(deXaPresale) != address(0));
    }

    function testUserAllowance() public {
        vm.startPrank(owner);
        deXaPresale.allowanceToUser(user1, 100e18);

        assertEq(
            deXaPresale.claimableTokens(address(user1)),
            100e18,
            "Amount mismatched"
        );
    }

    function testUsersAllowance() public {
        vm.startPrank(owner);

        address[] memory _users = new address[](2);
        _users[0] = address(user1);
        _users[1] = address(user2);

        uint256[] memory _allowances = new uint256[](2);
        _allowances[0] = uint256(100e18);
        _allowances[1] = uint256(10e18);

        deXaPresale.batchAllowanceToUsers(_users, _allowances);

        uint256 _amount0 = deXaPresale.claimableTokens(_users[0]);
        uint256 _amount1 = deXaPresale.claimableTokens(_users[1]);

        assertEq(_amount0, _allowances[0], "Amount mismatched");
        assertEq(_amount1, _allowances[1], "Amount mismatched");
    }

    function testClaimTokens() public {
        vm.startPrank(owner);
        deal({token: address(deXa), to: address(deXaPresale), give: 10000e18});

        address[] memory _users = new address[](2);
        _users[0] = address(user1);
        _users[1] = address(user2);

        uint256[] memory _allowances = new uint256[](2);
        _allowances[0] = uint256(100e18);
        _allowances[1] = uint256(10e18);

        deXaPresale.batchAllowanceToUsers(_users, _allowances);

        uint256 _amount0 = deXaPresale.claimableTokens(_users[0]);
        uint256 _amount1 = deXaPresale.claimableTokens(_users[1]);
        vm.stopPrank();

        vm.startPrank(user1);
        deXaPresale.claimPrebookTokens();

        assertEq(
            deXa.balanceOf(user1),
            100e18,
            "Not received claimable amount"
        );
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
            1,
            50000000e18,
            150e18,
            1000e18
        );

        vm.stopPrank();
        vm.startPrank(user1);

        busd.approve(address(deXaPresale), 1000e18);

        deXaPresale.tokenPurchaseWithBUSD(150e18);

        vm.warp(31 days);
        deXaPresale.claimTokensFromBusd(0);

        assertEq(
            deXa.balanceOf(address(user1)),
            18750000000000000000,
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
            1,
            1000e18,
            150e18,
            5000e18
        );

        vm.stopPrank();
        vm.startPrank(user1);

        busd.approve(address(deXaPresale), 4500e18);

        deXaPresale.tokenPurchaseWithBUSD(4500e18);

        vm.warp(31 days);
        deXaPresale.claimTokensFromBusd(0);

        assertEq(
            deXa.balanceOf(address(user1)),
            562500000000000000000,
            "Amount not received as expected"
        );
    }

    function testSetRound1AndPurchaseWithMaxBUSD() public {
        console2.log("time start: ", block.timestamp);
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
            1000e18,
            150e18,
            5000e18
        );
        vm.warp(31 days);

        //round2
        deXaPresale.setRoundInfoForBusd(
            1,
            800000000000000000,
            block.timestamp,
            block.timestamp + 30 days,
            1,
            50000000e18,
            150e18,
            5000e18
        );

        vm.stopPrank();
        vm.startPrank(user1);

        busd.approve(address(deXaPresale), 4500e18);

        deXaPresale.tokenPurchaseWithBUSD(4500e18);

        vm.warp(33 days);

        deXaPresale.claimTokensFromBusd(1);

        assertEq(
            deXa.balanceOf(address(user1)),
            562500000000000000000,
            "Amount not received as expected"
        );
    }
}
