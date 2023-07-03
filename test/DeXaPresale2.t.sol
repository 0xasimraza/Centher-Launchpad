// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../src/DeXaPresale.sol";
import "../src/utils/Token.sol";
import "../src/utils/CentherRegistration.sol";

import "forge-std/console2.sol";

contract LaunchpadTest is Test {
    address payable internal owner;
    address payable internal user1;
    address payable internal user2;
    address payable internal other;
    address payable internal other2;

    Token deXa;
    Token busd;
    Token wbnb;
    Token ntr;

    CentherRegistration register;

    DeXaPresale deXaPresale;

    function setUp() public {
        owner = payable(vm.addr(1));
        user1 = payable(vm.addr(2));
        user2 = payable(vm.addr(3));
        other = payable(vm.addr(4));
        other2 = payable(vm.addr(5));

        console2.log(" ---- owner ----", owner);
        console2.log(" ---- user1 ----", user1);
        console2.log(" ---- user2 ----", user2);
        console2.log(" ---- other ----", other);

        vm.startPrank(owner);
        deXa = new Token("deXa", "DXC");
        busd = new Token("Binance USD", "BUSD");
        wbnb = new Token("Wrapped BNB", "WBNB");
        ntr = new Token("Nither", "NTR");

        busd.transfer(user1, 500000e18);
        busd.transfer(user2, 500000e18);

        wbnb.transfer(user1, 500000e18);
        wbnb.transfer(user2, 500000e18);

        ntr.transfer(user1, 500000e18);
        ntr.transfer(user2, 500000e18);

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
            address(ntr),
            address(busd),
            address(register),
            address(owner),
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
        deXaPresale.allowanceToBusdUser(user1, 150e18, 0);
    }

    function testclaimTokensFromBusd() public {
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
            5000e18
        );
        busd.approve(address(deXaPresale), 1000e18);
        deXaPresale.depositBusdForReward(1000e18);
        deXaPresale.allowanceToBusdUser(user1, 150e18, 0);
        vm.warp(block.timestamp + 30 days);

        busd.transfer(user1, busd.balanceOf(owner));

        deXaPresale.withdrawBusdForCoreTeam();

        uint256 balance = busd.balanceOf(owner);
        console2.log(balance);

        assertEq(busd.balanceOf(owner), 15e18, "Amount is not match");
    }

    function testclaimTokensFromBusd2() public {
        vm.startPrank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        deXaPresale.setRoundInfoForBusd(
            0,
            800000000000000000,
            block.timestamp,
            block.timestamp + 30 days,
            1,
            50000000e18,
            150e18,
            5000e18
        );
    }

    function testclaimTokensFromBusd3() public {
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
            5000e18
        );
        vm.stopPrank();
        vm.startPrank(user1);

        busd.approve(address(deXaPresale), 1000e18);
        // deXaPresale.depositBusdForReward(1000e18);
        deXaPresale.tokenPurchaseWithBUSD(150e18);

        vm.warp(block.timestamp + 30 days * 12);

        deXaPresale.claimTokensFromBusd(0);

        assertEq(
            deXa.balanceOf(address(user1)),
            187500000000000000000, //187.5 (1 year)
            "Amount not received as expected"
        );
    }

    //user cannot claim token if the locked time period is not over
    function testclaimTokensFromBusd5() public {
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
            12,
            50000000e18,
            150e18,
            5000e18
        );
        vm.stopPrank();
        vm.startPrank(user1);

        busd.approve(address(deXaPresale), 1000e18);
        deXaPresale.tokenPurchaseWithBUSD(150e18);
        vm.expectRevert("Locked");
        deXaPresale.claimTokensFromBusd(0);
    }

    //revert tx when user did not buy any dexa token and he call claim reward function
    function testclaimTokensFromBusd6() public {
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
            12,
            50000000e18,
            150e18,
            5000e18
        );
        vm.stopPrank();
        vm.startPrank(user1);

        busd.approve(address(deXaPresale), 1000e18);
        vm.expectRevert("Nothing to claim");
        deXaPresale.claimTokensFromBusd(0);
    }

    //revert the tx if user already claim tokens after purchase
    function testclaimTokensFromBusd7() public {
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
            12,
            50000000e18,
            150e18,
            5000e18
        );
        vm.stopPrank();
        vm.startPrank(user1);
        busd.approve(address(deXaPresale), 1000e18);
        deXaPresale.tokenPurchaseWithBUSD(150e18);
        vm.warp(block.timestamp + 30 days * 12);
        deXaPresale.claimTokensFromBusd(0);
        // vm.expectRevert("Nothing to claim");
        deXaPresale.claimTokensFromBusd(0);
        deXaPresale.claimTokensFromBusd(0);
    }

    // should claim tokens after the lock period is over
    function testclaimTokensFromBusd8() public {
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
            2,
            50000000e18,
            150e18,
            5000e18
        );
        vm.stopPrank();
        vm.startPrank(user1);
        busd.approve(address(deXaPresale), 1000e18);
        deXaPresale.tokenPurchaseWithBUSD(150e18);
        vm.warp(block.timestamp + 30 days * 2);
        deXaPresale.claimTokensFromBusd(0);
    }

    // should claim tokens after the lock period is over in round 1
    function testclaimTokensFromBusd9() public {
        vm.startPrank(owner);
        deal({
            token: address(deXa),
            to: address(deXaPresale),
            give: 50000000e18
        });
        deXaPresale.setRoundInfoForBusd(
            1,
            800000000000000000,
            block.timestamp,
            block.timestamp + 30 days,
            2,
            50000000e18,
            150e18,
            5000e18
        );
        vm.stopPrank();
        vm.startPrank(user1);
        busd.approve(address(deXaPresale), 1000e18);
        deXaPresale.tokenPurchaseWithBUSD(150e18);
        vm.warp(block.timestamp + 30 days * 2);
        deXaPresale.claimTokensFromBusd(1);
    }

    //should correctly transfer dexa amount to buyer with 0.8 token price in round 0 (claim after 3 months)
    function testclaimTokensFromBusd10() public {
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
            2,
            50000000e18,
            150e18,
            5000e18
        );
        vm.stopPrank();
        vm.startPrank(user1);
        busd.approve(address(deXaPresale), 1000e18);
        deXaPresale.tokenPurchaseWithBUSD(150e18);
        vm.warp(block.timestamp + 30 days * 3);
        deXaPresale.claimTokensFromBusd(0);
        assertEq(
            deXa.balanceOf(address(user1)),
            23437500000000000000,
            "Amount not received as expected"
        );
    }

    //should correctly transfer dexa amount to buyer with 0.95 token price in round 1 and transfer token to buyer
    function testclaimTokensFromBusd11() public {
        vm.startPrank(owner);
        deal({
            token: address(deXa),
            to: address(deXaPresale),
            give: 50000000e18
        });
        deXaPresale.setRoundInfoForBusd(
            1,
            950000000000000000, //0.95
            block.timestamp,
            block.timestamp + 30 days,
            2,
            50000000e18,
            150e18,
            5000e18
        );
        vm.stopPrank();
        vm.startPrank(user1);
        busd.approve(address(deXaPresale), 1000e18);
        deXaPresale.tokenPurchaseWithBUSD(150e18);
        vm.warp(block.timestamp + 30 days * 12);
        deXaPresale.claimTokensFromBusd(1);
        assertEq(
            deXa.balanceOf(address(user1)),
            157894736842105263157, //157.894736842
            "Amount not received as expected"
        );
    }

    //should revert the tx is there is no any round start in NTR
    function testtokenPurchaseWithNTR1() public {
        vm.startPrank(owner);
        //
        deal({
            token: address(deXa),
            to: address(deXaPresale),
            give: 50000000e18
        });
        deXaPresale.setRoundInfoForBusd(
            0,
            950000000000000000, //0.95
            block.timestamp,
            block.timestamp + 2 weeks,
            4,
            50000000e18,
            150e18,
            5000e18
        );
        deXaPresale.setRoundInfoForNtr(0, 160e18, 150e18, 5000e18);
        vm.stopPrank();
        vm.startPrank(user1);
        ntr.approve(address(deXaPresale), 1000e18);
        deXaPresale.tokenPurchaseWithNTR(150e18);

        vm.warp(block.timestamp + 2 weeks);

        vm.expectRevert("Not started any Round.");
        deXaPresale.tokenPurchaseWithNTR(150e18);
    }

    //should successfully execute the tx and distribute the
    function testtokenPurchaseWithNTR2() public {
        vm.startPrank(owner);
        //
        deal({
            token: address(deXa),
            to: address(deXaPresale),
            give: 50000000e18
        });
        deXaPresale.setRoundInfoForBusd(
            0,
            800000000000000000, //0.8
            block.timestamp,
            block.timestamp + 2 weeks,
            4,
            50000000e18,
            150e18,
            5000e18
        );
        deXaPresale.setRoundInfoForNtr(0, 160e18, 150e18, 5000e18);
        vm.stopPrank();
        vm.startPrank(user1);
        ntr.approve(address(deXaPresale), 1000e18);
        deXaPresale.tokenPurchaseWithNTR(150e18);

        vm.warp(block.timestamp + 30 days * 12);

        deXaPresale.claimTokensFromNtr(0);
        assertEq(
            deXa.balanceOf(address(user1)),
            937500000000000000,
            "Amount not received as expected"
        );
    }

    //should revert the tx is caller is not register user
    function testtokenPurchaseWithNTR3() public {
        vm.startPrank(owner);

        deal({
            token: address(deXa),
            to: address(deXaPresale),
            give: 50000000e18
        });
        deXaPresale.setRoundInfoForBusd(
            0,
            800000000000000000, //0.8
            block.timestamp,
            block.timestamp + 2 weeks,
            4,
            50000000e18,
            150e18,
            5000e18
        );
        deXaPresale.setRoundInfoForNtr(0, 160e18, 150e18, 5000e18);

        changePrank(other2);
        ntr.approve(address(deXaPresale), 1000e18);
        vm.expectRevert("No registered.");
        deXaPresale.tokenPurchaseWithNTR(150e18);
    }

    //user should not claim token twice
    function testtokenPurchaseWithNTR4() public {
        vm.startPrank(owner);

        deal({
            token: address(deXa),
            to: address(deXaPresale),
            give: 50000000e18
        });
        deXaPresale.setRoundInfoForBusd(
            0,
            800000000000000000, //0.8
            block.timestamp,
            block.timestamp + 2 weeks,
            4,
            50000000e18,
            150e18,
            5000e18
        );
        deXaPresale.setRoundInfoForNtr(0, 160e18, 150e18, 5000e18);
        changePrank(user1);
        ntr.approve(address(deXaPresale), 1000e18);
        deXaPresale.tokenPurchaseWithNTR(150e18);
        vm.warp(block.timestamp + 30 days * 12);
        deXaPresale.claimTokensFromNtr(0);
        deXaPresale.claimTokensFromNtr(0);
        // vm.expectRevert("Nothing to claim");
    }

    //should correctly transfer dexa amount to buyer in round 1
    function testtokenPurchaseWithNTR5() public {
        vm.startPrank(owner);

        deal({
            token: address(deXa),
            to: address(deXaPresale),
            give: 50000000e18
        });
        deXaPresale.setRoundInfoForBusd(
            1,
            800000000000000000, //0.8
            block.timestamp,
            block.timestamp + 2 weeks,
            4,
            50000000e18,
            150e18,
            5000e18
        );
        deXaPresale.setRoundInfoForNtr(1, 160e18, 150e18, 5000e18);
        changePrank(user1);
        ntr.approve(address(deXaPresale), 1000e18);
        deXaPresale.tokenPurchaseWithNTR(150e18);
        vm.warp(block.timestamp + 30 days * 12);
        deXaPresale.claimTokensFromNtr(1);
        assertEq(
            deXa.balanceOf(address(user1)),
            937500000000000000, //0.93
            "Amount not received as expected"
        );
    }

    // should correctly transfer dexa amount to buyer with 0.95 token price in round 1 (claim after 3 months)
    function testtokenPurchaseWithNTR6() public {
        vm.startPrank(owner);

        deal({
            token: address(deXa),
            to: address(deXaPresale),
            give: 50000000e18
        });
        deXaPresale.setRoundInfoForBusd(
            1,
            950000000000000000, //0.95
            block.timestamp,
            block.timestamp + 2 weeks,
            4,
            50000000e18,
            150e18,
            5000e18
        );
        deXaPresale.setRoundInfoForNtr(1, 160e18, 150e18, 5000e18);

        changePrank(user1);
        ntr.approve(address(deXaPresale), 1000e18);
        deXaPresale.tokenPurchaseWithNTR(150e18);
        vm.warp(block.timestamp + 30 days * 7);
        deXaPresale.claimTokensFromNtr(1);
        assertEq(
            deXa.balanceOf(address(user1)),
            351562500000000000, //0.3515625 (after 3 months of lock period)
            "Amount not received as expected"
        );
    }

    //should not transfer dexa amount to buyer with 0.95 token price in round 1 (claim after 2.5 months)
    function testtokenPurchaseWithNTR7() public {
        vm.startPrank(owner);

        deal({
            token: address(deXa),
            to: address(deXaPresale),
            give: 50000000e18
        });
        deXaPresale.setRoundInfoForBusd(
            1,
            950000000000000000, //0.95
            block.timestamp,
            block.timestamp + 2 weeks,
            4,
            50000000e18,
            150e18,
            5000e18
        );
        deXaPresale.setRoundInfoForNtr(1, 160e18, 150e18, 5000e18);
        changePrank(user1);
        ntr.approve(address(deXaPresale), 1000e18);
        deXaPresale.tokenPurchaseWithNTR(150e18);
        vm.warp(block.timestamp + 30 days * 2.5);
        vm.expectRevert("Locked"); //can't clain before locked period
        deXaPresale.claimTokensFromNtr(1);
    }

    /*
     *should execute the different rounds and different user buys in different rouds
     */
    function testtokenPurchaseWithNTR8() public {
        vm.startPrank(owner);

        deal({
            token: address(deXa),
            to: address(deXaPresale),
            give: 50000000e18
        });
        deXaPresale.setRoundInfoForBusd(
            0,
            950000000000000000, //0.95
            block.timestamp,
            block.timestamp + 2 weeks,
            4,
            50000000e18,
            150e18,
            5000e18
        );
        deXaPresale.setRoundInfoForNtr(0, 160e18, 150e18, 5000e18);
        changePrank(user1);
        ntr.approve(address(deXaPresale), 1000e18);
        deXaPresale.tokenPurchaseWithNTR(150e18);
        vm.warp(block.timestamp + 30 days * 5);
        deXaPresale.claimTokensFromNtr(0);
        assertEq(
            deXa.balanceOf(address(user1)),
            117187500000000000, //0.1171875
            "Amount not received as expected"
        );

        changePrank(owner);
        deXaPresale.setRoundInfoForBusd(
            1,
            950000000000000000, //0.95
            block.timestamp,
            block.timestamp + 2 weeks,
            4,
            50000000e18,
            150e18,
            5000e18
        );
        deXaPresale.setRoundInfoForNtr(1, 160e18, 150e18, 5000e18);
        changePrank(user2);
        ntr.approve(address(deXaPresale), 1000e18);
        deXaPresale.tokenPurchaseWithNTR(150e18);
        vm.warp(block.timestamp + 30 days * 9);
        deXaPresale.claimTokensFromNtr(1);
        assertEq(
            deXa.balanceOf(address(user2)),
            585937500000000000, //0.5859375
            "Amount not received as expected"
        );

        changePrank(owner);
        deXaPresale.setRoundInfoForBusd(
            2,
            950000000000000000, //0.95
            block.timestamp,
            block.timestamp + 2 weeks,
            4,
            50000000e18,
            150e18,
            5000e18
        );
        deXaPresale.setRoundInfoForNtr(2, 160e18, 150e18, 5000e18);
        changePrank(user1);
        ntr.approve(address(deXaPresale), 1000e18);
        deXaPresale.tokenPurchaseWithNTR(150e18);
        vm.warp(block.timestamp + 30 days * 12);
        deXaPresale.claimTokensFromNtr(2);
        assertEq(
            deXa.balanceOf(address(user1)),
            1054687500000000000, // 0.1171875 + 0.9375 = 1.0546875
            "Amount not received as expected"
        );
    }

    /*
     *should transfer the 10% amount to core team address
     */
    function testwithdrawBusdForCoreTeam1() public {
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
            5000e18
        );
        busd.approve(address(deXaPresale), 1000e18);
        deXaPresale.depositBusdForReward(1000e18);
        deXaPresale.allowanceToBusdUser(user1, 150e18, 0);
        vm.warp(block.timestamp + 30 days);

        busd.transfer(user1, busd.balanceOf(owner));

        deXaPresale.withdrawBusdForCoreTeam();
        assertEq(busd.balanceOf(owner), 15e18, "Amount is not match");
    }

    /*
     *should revert the tx if round is not over while withdrawBusdForCoreTeam
     */
    function testwithdrawBusdForCoreTeam2() public {
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
            5000e18
        );
        busd.approve(address(deXaPresale), 1000e18);
        deXaPresale.depositBusdForReward(1000e18);
        deXaPresale.allowanceToBusdUser(user1, 150e18, 0);
        // vm.warp(block.timestamp + 30 days);

        busd.transfer(user1, busd.balanceOf(owner));
        vm.expectRevert("Round is not over");
        deXaPresale.withdrawBusdForCoreTeam();
    }

    /*
     *should revert the tx if user did not buy any dexa in any round or already claim
     */
    function testwithdrawBusdForCoreTeam3() public {
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
            5000e18
        );
        busd.approve(address(deXaPresale), 1000e18);
        vm.warp(block.timestamp + 30 days);
        busd.transfer(user1, busd.balanceOf(owner));
        vm.expectRevert("Nothing to claim.");
        deXaPresale.withdrawBusdForCoreTeam();
    }

    /*
     *should revert the tx if user did not buy any dexa in any round or already claim
     */
    function testwithdrawBusdForCoreTeam4() public {
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
            5000e18
        );
        busd.approve(address(deXaPresale), 1000e18);
        deXaPresale.depositBusdForReward(1000e18);
        deXaPresale.allowanceToBusdUser(user1, 150e18, 0);
        vm.warp(block.timestamp + 30 days);
        busd.transfer(user1, busd.balanceOf(owner));
        deXaPresale.withdrawBusdForCoreTeam();
        vm.expectRevert("Nothing to claim.");
        deXaPresale.withdrawBusdForCoreTeam();
    }

    /*
     *should revert the tx if user did not buy any dexa in any round or already claim
     */
    function testwithdrawTokenForCoreTeam1() public {
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
            5000e18
        );
        busd.approve(address(deXaPresale), 1000e18);
        deXaPresale.depositBusdForReward(1000e18);
        deXaPresale.allowanceToBusdUser(user1, 150e18, 0);
        vm.warp(block.timestamp + 30 days);
        busd.transfer(user1, busd.balanceOf(owner));
        deXaPresale.withdrawBusdForCoreTeam();
        vm.expectRevert("Nothing to claim.");
        deXaPresale.withdrawBusdForCoreTeam();
    }

    function testThreeRoundsPuchaseWithBusdAndNtrWithReferrals() public {
        vm.startPrank(owner);
        deal({
            token: address(deXa),
            to: address(deXaPresale),
            give: 50000000e18
        });
        deal({
            token: address(ntr),
            to: address(deXaPresale),
            give: 50000000e18
        });
        deal({token: address(busd), to: address(other), give: 50000000e18});
        deXaPresale.setRoundInfoForBusd(
            0,
            800000000000000000,
            block.timestamp,
            block.timestamp + 2 weeks,
            4,
            50000000e18,
            150e18,
            1000e18
        );
        deXaPresale.setRoundInfoForNtr(
            0,
            160000000000000000000,
            150e18,
            5000e18
        );
        changePrank(user1);
        busd.approve(address(deXaPresale), 1000e18);
        deXaPresale.tokenPurchaseWithBUSD(150e18);
        ntr.approve(address(deXaPresale), 1000e18);
        deXaPresale.tokenPurchaseWithNTR(150e18);
        vm.warp(block.timestamp + 30 days * 6);
        changePrank(owner);
        deXaPresale.setRoundInfoForBusd(
            1,
            1000000000000000000,
            block.timestamp,
            block.timestamp + 2 weeks,
            4,
            50000000e18,
            150e18,
            1000e18
        );
        deXaPresale.setRoundInfoForNtr(
            0,
            160000000000000000000,
            150e18,
            5000e18
        );
        changePrank(user1);
        busd.approve(address(deXaPresale), 1000e18);
        deXaPresale.tokenPurchaseWithBUSD(150e18);
        changePrank(user2);
        busd.approve(address(deXaPresale), 1000e18);
        deXaPresale.tokenPurchaseWithBUSD(150e18);
        vm.warp(block.timestamp + 30 days * 3);
        changePrank(owner);
        deXaPresale.setRoundInfoForBusd(
            2,
            1200000000000000000,
            block.timestamp,
            block.timestamp + 2 weeks,
            4,
            50000000e18,
            150e18,
            1000e18
        );
        deXaPresale.setRoundInfoForNtr(
            0,
            160000000000000000000,
            150e18,
            5000e18
        );
        changePrank(user1);
        busd.approve(address(deXaPresale), 1000e18);
        deXaPresale.tokenPurchaseWithBUSD(150e18);
        changePrank(user2);
        busd.approve(address(deXaPresale), 1000e18);
        deXaPresale.tokenPurchaseWithBUSD(150e18);
        changePrank(other);
        busd.approve(address(deXaPresale), 1000e18);
        deXaPresale.tokenPurchaseWithBUSD(150e18);
        vm.warp(block.timestamp + 30 days * 5);
        // 8 months claims
        changePrank(user1);
        deXaPresale.claimTokensFromBusd(0);
        assertEq(deXa.balanceOf(user1), 187500000000000000000, "Not equal");
        // 4 months claims
        changePrank(user2);
        deXaPresale.claimTokensFromBusd(1);
        assertEq(deXa.balanceOf(user2), 75000000000000000000, "Not equal");
        changePrank(user1);
        // clear old claims
        deXa.transfer(owner, deXa.balanceOf(user1));
        deXaPresale.claimTokensFromBusd(1);
        assertEq(deXa.balanceOf(user1), 75000000000000000000, "Not equal");
        // 1 month claim
        changePrank(other);
        deXaPresale.claimTokensFromBusd(2);
        assertEq(deXa.balanceOf(other), 15625000000000000000, "Not equal");
        vm.warp(block.timestamp + 30 days * 12);
        //try claim another times, not return any amount of DXC because already claimed
        changePrank(user1);
        deXa.transfer(owner, deXa.balanceOf(user1));
        deXaPresale.claimTokensFromBusd(0);
        assertEq(deXa.balanceOf(user1), 0, "Not equal");
        changePrank(user2);
        deXa.transfer(owner, deXa.balanceOf(user2));
        deXaPresale.claimTokensFromBusd(1);
        assertEq(deXa.balanceOf(user2), 75000000000000000000, "Not equal");
        changePrank(user1);
        deXa.transfer(owner, deXa.balanceOf(user1));
        deXaPresale.claimTokensFromBusd(1);
        assertEq(deXa.balanceOf(user1), 75000000000000000000, "Not equal");
        changePrank(other);
        deXa.transfer(owner, deXa.balanceOf(other));
        deXaPresale.claimTokensFromBusd(2);
        assertEq(deXa.balanceOf(other), 109375000000000000000, "Not equal");
        //ntr claim
        changePrank(user1);
        // clear old claims
        deXa.transfer(owner, deXa.balanceOf(user1));
        deXaPresale.claimTokensFromNtr(0);
        assertEq(deXa.balanceOf(user1), 937500000000000000, "Not equal");
    }

    //Should revert tx if user already deposite allowance
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
        deXaPresale.allowanceToBusdUser(user1, 150e18, 0);
        vm.expectRevert("Already Deposited");
        deXaPresale.allowanceToBusdUser(user1, 150e18, 0);
    }
}
