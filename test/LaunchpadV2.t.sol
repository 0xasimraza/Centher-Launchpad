// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import "../src/utils/Token.sol";

import "../src/interfaces/ILaunchpadV2.sol";

import "../src/utils/CentherRegistration.sol";
import "../src/LaunchpadV2.sol";

contract LaunchpadV2Test is Test {
    address payable public owner;
    address payable public admin;
    address payable public user1;
    address payable public user2;
    address payable public user3;
    address payable public user4;
    address payable public other;

    Token public deXa;
    Token public busd;
    Token public wbnb;
    Token public ntr;

    CentherRegistration public register;
    LaunchpadV2 public instance;

    function setUp() public {
        admin = payable(vm.addr(1));
        owner = payable(vm.addr(2));
        user1 = payable(vm.addr(3));
        user2 = payable(vm.addr(4));
        user3 = payable(vm.addr(5));
        user4 = payable(vm.addr(6));
        other = payable(vm.addr(7));

        console2.log(" ---- admin ----", admin);
        console2.log(" ---- owner ----", owner);
        console2.log(" ---- user1 ----", user1);
        console2.log(" ---- user2 ----", user2);
        console2.log(" ---- user3 ----", user3);
        console2.log(" ---- user4 ----", user4);
        console2.log(" ---- other ----", other);

        vm.startPrank(owner);
        deXa = new Token("deXa", "DXC", 50000000e18 );
        busd = new Token("Binance USD", "BUSD", 25000000e18);
        wbnb = new Token("Wrapped BNB", "WBNB", 50000000e18);
        ntr = new Token("NTR Token", "NTR", 25000000e18);

        busd.transfer(user1, 500000e18);
        busd.transfer(user2, 500000e18);

        wbnb.transfer(user1, 500000e18);
        wbnb.transfer(user2, 500000e18);

        ntr.transfer(user1, 500000e18);
        ntr.transfer(user2, 500000e18);

        register = new CentherRegistration();
        register.setOperator(address(owner));

        address[] memory _users = new address[](4);
        _users[0] = address(user1);
        _users[1] = address(user2);
        _users[2] = address(user3);
        _users[3] = address(other);

        address[] memory _refs = new address[](4);
        _refs[0] = address(owner);
        _refs[1] = address(user1);
        _refs[2] = address(user2);
        _refs[3] = address(user3);

        register.registerForOwnerBatch(_users, _refs);

        instance = new LaunchpadV2(
        address(register),
        address(busd)
        );
        vm.stopPrank();
    }

    function testDeployments() public view {
        assert(address(deXa) != address(0));
        assert(address(instance) != address(0));
    }

    // TestCases:: For Create Presale
    function testShouldCreatePresaleForDexaAgainstBUSD() public {
        deal({token: address(deXa), to: address(user1), give: 50000000e18});

        deal(user1, 5 ether);

        vm.startPrank(user1);

        ILaunchpadV2.PresaleInfoParams memory _infoParams = ILaunchpadV2.PresaleInfoParams({
            owner: user1,
            token: address(deXa),
            minTokensToSell: 500000e18,
            maxTokensToSell: 1000000e18,
            roundDeep: 3,
            coinFeeRate: 100,
            tokenFeeRate: 100,
            releaseMonth: 10,
            fundType: ILaunchpadV2.FundType.BUSD
        });

        ILaunchpadV2.RoundInfo[] memory _roundsParams = new ILaunchpadV2.RoundInfo[](3);
        _roundsParams[0] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 86400),
            endTime: (block.timestamp + 12 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 50000e18,
            pricePerToken: 1e18
        });
        _roundsParams[1] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 12 weeks),
            endTime: (block.timestamp + 24 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 25000e18,
            pricePerToken: 1e18
        });
        _roundsParams[2] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 24 weeks),
            endTime: (block.timestamp + 36 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 10000e18,
            pricePerToken: 1e18
        });
        deXa.approve(address(instance), 1500000e18);
        instance.createPresale{value: 0.001 ether}(_infoParams, _roundsParams);

        assertEq(instance.createdPresale(_infoParams.token), true, "Not Created");
    }

    function testShouldCreatePresaleForDexaAgainstBNB() public {
        deal({token: address(deXa), to: address(user1), give: 50000000e18});

        deal(user1, 5 ether);

        vm.startPrank(user1);

        ILaunchpadV2.PresaleInfoParams memory _infoParams = ILaunchpadV2.PresaleInfoParams({
            owner: user1,
            token: address(deXa),
            minTokensToSell: 500000e18,
            maxTokensToSell: 1000000e18,
            roundDeep: 3,
            coinFeeRate: 100,
            tokenFeeRate: 100,
            releaseMonth: 10,
            fundType: ILaunchpadV2.FundType.BNB
        });

        ILaunchpadV2.RoundInfo[] memory _roundsParams = new ILaunchpadV2.RoundInfo[](3);
        _roundsParams[0] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 86400),
            endTime: (block.timestamp + 12 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 50000e18,
            pricePerToken: 1e18
        });
        _roundsParams[1] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 12 weeks),
            endTime: (block.timestamp + 24 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 25000e18,
            pricePerToken: 1e18
        });
        _roundsParams[2] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 24 weeks),
            endTime: (block.timestamp + 36 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 10000e18,
            pricePerToken: 1e18
        });
        deXa.approve(address(instance), 1500000e18);
        instance.createPresale{value: 0.001 ether}(_infoParams, _roundsParams);

        assertEq(instance.createdPresale(_infoParams.token), true, "Not Created");
    }

    function testShouldNotCreatePresaleDueToInsufficientFees() public {
        deal({token: address(deXa), to: address(user1), give: 50000000e18});

        deal(user1, 5 ether);

        vm.startPrank(user1);

        ILaunchpadV2.PresaleInfoParams memory _infoParams = ILaunchpadV2.PresaleInfoParams({
            owner: user1,
            token: address(deXa),
            minTokensToSell: 500000e18,
            maxTokensToSell: 1000000e18,
            roundDeep: 3,
            coinFeeRate: 100,
            tokenFeeRate: 100,
            releaseMonth: 10,
            fundType: ILaunchpadV2.FundType.BUSD
        });

        ILaunchpadV2.RoundInfo[] memory _roundsParams = new ILaunchpadV2.RoundInfo[](3);
        _roundsParams[0] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 86400),
            endTime: (block.timestamp + 12 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 50000e18,
            pricePerToken: 1e18
        });
        _roundsParams[1] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 12 weeks),
            endTime: (block.timestamp + 24 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 25000e18,
            pricePerToken: 1e18
        });
        _roundsParams[2] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 24 weeks),
            endTime: (block.timestamp + 36 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 10000e18,
            pricePerToken: 1e18
        });
        deXa.approve(address(instance), 1500000e18);

        bytes4 selector = bytes4(keccak256("InsufficientFees()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        instance.createPresale(_infoParams, _roundsParams);

        assertEq(instance.createdPresale(_infoParams.token), false, "Created");
    }

    function testShouldNotCreatePresaleDueToInsufficientTokens() public {
        deal({token: address(deXa), to: address(user1), give: 1000e18});

        deal(user1, 5 ether);

        vm.startPrank(user1);

        ILaunchpadV2.PresaleInfoParams memory _infoParams = ILaunchpadV2.PresaleInfoParams({
            owner: user1,
            token: address(deXa),
            minTokensToSell: 500000e18,
            maxTokensToSell: 1000000e18,
            roundDeep: 3,
            coinFeeRate: 100,
            tokenFeeRate: 100,
            releaseMonth: 10,
            fundType: ILaunchpadV2.FundType.BUSD
        });

        ILaunchpadV2.RoundInfo[] memory _roundsParams = new ILaunchpadV2.RoundInfo[](3);
        _roundsParams[0] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 86400),
            endTime: (block.timestamp + 12 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 50000e18,
            pricePerToken: 1e18
        });
        _roundsParams[1] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 12 weeks),
            endTime: (block.timestamp + 24 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 25000e18,
            pricePerToken: 1e18
        });
        _roundsParams[2] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 24 weeks),
            endTime: (block.timestamp + 36 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 10000e18,
            pricePerToken: 1e18
        });
        deXa.approve(address(instance), 1500000e18);

        bytes4 selector = bytes4(keccak256("InsufficientTokens()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        instance.createPresale{value: 0.001 ether}(_infoParams, _roundsParams);

        assertEq(instance.createdPresale(_infoParams.token), false, " Created");
    }

    function testShouldNotCreatePresaleDueToIncorrectMaxSellValue() public {
        deal({token: address(deXa), to: address(user1), give: 50000000e18});

        deal(user1, 5 ether);

        vm.startPrank(user1);

        ILaunchpadV2.PresaleInfoParams memory _infoParams = ILaunchpadV2.PresaleInfoParams({
            owner: user1,
            token: address(deXa),
            minTokensToSell: 500000e18,
            maxTokensToSell: 1000e18,
            roundDeep: 3,
            coinFeeRate: 100,
            tokenFeeRate: 100,
            releaseMonth: 10,
            fundType: ILaunchpadV2.FundType.BUSD
        });

        ILaunchpadV2.RoundInfo[] memory _roundsParams = new ILaunchpadV2.RoundInfo[](3);
        _roundsParams[0] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 86400),
            endTime: (block.timestamp + 12 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 50000e18,
            pricePerToken: 1e18
        });
        _roundsParams[1] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 12 weeks),
            endTime: (block.timestamp + 24 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 25000e18,
            pricePerToken: 1e18
        });
        _roundsParams[2] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 24 weeks),
            endTime: (block.timestamp + 36 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 10000e18,
            pricePerToken: 1e18
        });
        deXa.approve(address(instance), 1500000e18);
        bytes4 selector = bytes4(keccak256("MaxValueGreaterThanMin()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        instance.createPresale{value: 0.001 ether}(_infoParams, _roundsParams);

        assertEq(instance.createdPresale(_infoParams.token), false, " Created");
    }

    function testShouldNotCreatePresaleDueToMismatchOwner() public {
        deal({token: address(deXa), to: address(user1), give: 50000000e18});

        deal(user1, 5 ether);

        vm.startPrank(user1);

        ILaunchpadV2.PresaleInfoParams memory _infoParams = ILaunchpadV2.PresaleInfoParams({
            owner: user2,
            token: address(deXa),
            minTokensToSell: 500000e18,
            maxTokensToSell: 1000000e18,
            roundDeep: 3,
            coinFeeRate: 100,
            tokenFeeRate: 100,
            releaseMonth: 10,
            fundType: ILaunchpadV2.FundType.BUSD
        });

        ILaunchpadV2.RoundInfo[] memory _roundsParams = new ILaunchpadV2.RoundInfo[](3);
        _roundsParams[0] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 86400),
            endTime: (block.timestamp + 12 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 50000e18,
            pricePerToken: 1e18
        });
        _roundsParams[1] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 12 weeks),
            endTime: (block.timestamp + 24 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 25000e18,
            pricePerToken: 1e18
        });
        _roundsParams[2] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 24 weeks),
            endTime: (block.timestamp + 36 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 10000e18,
            pricePerToken: 1e18
        });
        deXa.approve(address(instance), 1500000e18);
        bytes4 selector = bytes4(keccak256("CallerMustBeOwner()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        instance.createPresale{value: 0.001 ether}(_infoParams, _roundsParams);

        assertEq(instance.createdPresale(_infoParams.token), false, " Created");
    }

    function testShouldNotCreatePresaleDueToIncorrectRoundCount() public {
        deal({token: address(deXa), to: address(user1), give: 50000000e18});

        deal(user1, 5 ether);

        vm.startPrank(user1);

        ILaunchpadV2.PresaleInfoParams memory _infoParams = ILaunchpadV2.PresaleInfoParams({
            owner: user1,
            token: address(deXa),
            minTokensToSell: 500000e18,
            maxTokensToSell: 1000000e18,
            roundDeep: 5,
            coinFeeRate: 100,
            tokenFeeRate: 100,
            releaseMonth: 10,
            fundType: ILaunchpadV2.FundType.BUSD
        });

        ILaunchpadV2.RoundInfo[] memory _roundsParams = new ILaunchpadV2.RoundInfo[](3);
        _roundsParams[0] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 86400),
            endTime: (block.timestamp + 12 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 50000e18,
            pricePerToken: 1e18
        });
        _roundsParams[1] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 12 weeks),
            endTime: (block.timestamp + 24 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 25000e18,
            pricePerToken: 1e18
        });
        _roundsParams[2] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 24 weeks),
            endTime: (block.timestamp + 36 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 10000e18,
            pricePerToken: 1e18
        });
        deXa.approve(address(instance), 1500000e18);
        bytes4 selector = bytes4(keccak256("IncorrectRoundsCount()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        instance.createPresale{value: 0.001 ether}(_infoParams, _roundsParams);

        assertEq(instance.createdPresale(_infoParams.token), false, " Created");
    }

    function testShouldNotCreatePresaleDueToIncorrectRoundSellValue1() public {
        deal({token: address(deXa), to: address(user1), give: 50000000e18});

        deal(user1, 5 ether);

        vm.startPrank(user1);

        ILaunchpadV2.PresaleInfoParams memory _infoParams = ILaunchpadV2.PresaleInfoParams({
            owner: user1,
            token: address(deXa),
            minTokensToSell: 500000e18,
            maxTokensToSell: 1000000e18,
            roundDeep: 3,
            coinFeeRate: 100,
            tokenFeeRate: 100,
            releaseMonth: 10,
            fundType: ILaunchpadV2.FundType.BUSD
        });

        ILaunchpadV2.RoundInfo[] memory _roundsParams = new ILaunchpadV2.RoundInfo[](3);
        _roundsParams[0] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 86400),
            endTime: (block.timestamp + 12 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 5000000000e18,
            pricePerToken: 1e18
        });
        _roundsParams[1] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 12 weeks),
            endTime: (block.timestamp + 24 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 25000e18,
            pricePerToken: 1e18
        });
        _roundsParams[2] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 24 weeks),
            endTime: (block.timestamp + 36 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 10000e18,
            pricePerToken: 1e18
        });
        deXa.approve(address(instance), 1500000e18);
        bytes4 selector = bytes4(keccak256("IncorrectAmountToSell()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        instance.createPresale{value: 0.001 ether}(_infoParams, _roundsParams);

        assertEq(instance.createdPresale(_infoParams.token), false, " Created");
    }

    function testShouldNotCreatePresaleDueToIncorrectRoundSellValue2() public {
        deal({token: address(deXa), to: address(user1), give: 50000000e18});

        deal(user1, 5 ether);

        vm.startPrank(user1);

        ILaunchpadV2.PresaleInfoParams memory _infoParams = ILaunchpadV2.PresaleInfoParams({
            owner: user1,
            token: address(deXa),
            minTokensToSell: 500000e18,
            maxTokensToSell: 1000000e18,
            roundDeep: 3,
            coinFeeRate: 100,
            tokenFeeRate: 100,
            releaseMonth: 10,
            fundType: ILaunchpadV2.FundType.BUSD
        });

        ILaunchpadV2.RoundInfo[] memory _roundsParams = new ILaunchpadV2.RoundInfo[](3);
        _roundsParams[0] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 86400),
            endTime: (block.timestamp + 12 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 50000e18,
            pricePerToken: 1e18
        });
        _roundsParams[1] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 12 weeks),
            endTime: (block.timestamp + 24 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 2500000000000e18,
            pricePerToken: 1e18
        });
        _roundsParams[2] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 24 weeks),
            endTime: (block.timestamp + 36 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 10000e18,
            pricePerToken: 1e18
        });
        deXa.approve(address(instance), 1500000e18);
        bytes4 selector = bytes4(keccak256("IncorrectAmountToSell()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        instance.createPresale{value: 0.001 ether}(_infoParams, _roundsParams);

        assertEq(instance.createdPresale(_infoParams.token), false, " Created");
    }

    function testShouldNotCreatePresaleDueToIncorrectRoundSellValue3() public {
        deal({token: address(deXa), to: address(user1), give: 50000000e18});

        deal(user1, 5 ether);

        vm.startPrank(user1);

        ILaunchpadV2.PresaleInfoParams memory _infoParams = ILaunchpadV2.PresaleInfoParams({
            owner: user1,
            token: address(deXa),
            minTokensToSell: 500000e18,
            maxTokensToSell: 1000000e18,
            roundDeep: 3,
            coinFeeRate: 100,
            tokenFeeRate: 100,
            releaseMonth: 10,
            fundType: ILaunchpadV2.FundType.BUSD
        });

        ILaunchpadV2.RoundInfo[] memory _roundsParams = new ILaunchpadV2.RoundInfo[](3);
        _roundsParams[0] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 86400),
            endTime: (block.timestamp + 12 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 50000e18,
            pricePerToken: 1e18
        });
        _roundsParams[1] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 12 weeks),
            endTime: (block.timestamp + 24 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 250000e18,
            pricePerToken: 1e18
        });
        _roundsParams[2] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 24 weeks),
            endTime: (block.timestamp + 36 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 10000000000e18,
            pricePerToken: 1e18
        });
        deXa.approve(address(instance), 1500000e18);
        bytes4 selector = bytes4(keccak256("IncorrectAmountToSell()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        instance.createPresale{value: 0.001 ether}(_infoParams, _roundsParams);

        assertEq(instance.createdPresale(_infoParams.token), false, " Created");
    }

    // TestCases:: For Update Presale
    function testShouldNotUpdatePresaleForDexaAgainstBUSD() public {
        deal({token: address(deXa), to: address(user1), give: 50000000e18});

        deal(user1, 5 ether);

        vm.startPrank(user1);

        ILaunchpadV2.PresaleInfoParams memory _infoParams = ILaunchpadV2.PresaleInfoParams({
            owner: user1,
            token: address(deXa),
            minTokensToSell: 500000e18,
            maxTokensToSell: 1000000e18,
            roundDeep: 3,
            coinFeeRate: 100,
            tokenFeeRate: 100,
            releaseMonth: 10,
            fundType: ILaunchpadV2.FundType.BUSD
        });

        ILaunchpadV2.RoundInfo[] memory _roundsParams = new ILaunchpadV2.RoundInfo[](3);
        _roundsParams[0] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 86400),
            endTime: (block.timestamp + 12 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 50000e18,
            pricePerToken: 1e18
        });
        _roundsParams[1] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 12 weeks),
            endTime: (block.timestamp + 24 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 25000e18,
            pricePerToken: 1e18
        });
        _roundsParams[2] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 24 weeks),
            endTime: (block.timestamp + 36 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 10000e18,
            pricePerToken: 1e18
        });
        deXa.approve(address(instance), 1500000e18);
        instance.createPresale{value: 0.001 ether}(_infoParams, _roundsParams);

        assertEq(instance.createdPresale(_infoParams.token), true, "Not Created");

        ILaunchpadV2.PresaleInfoParams memory _infoParams1 = ILaunchpadV2.PresaleInfoParams({
            owner: user1,
            token: address(deXa),
            minTokensToSell: 5000000e18,
            maxTokensToSell: 1000000e18,
            roundDeep: 3,
            coinFeeRate: 100,
            tokenFeeRate: 100,
            releaseMonth: 10,
            fundType: ILaunchpadV2.FundType.BUSD
        });
        bytes4 selector = bytes4(keccak256("MaxValueGreaterThanMin()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        instance.updatePresale(_infoParams1, _roundsParams);
    }

    function testShouldNotUpdatePresaleDueToIncorrectSellValue() public {
        deal({token: address(deXa), to: address(user1), give: 50000000e18});

        deal(user1, 5 ether);

        vm.startPrank(user1);

        ILaunchpadV2.PresaleInfoParams memory _infoParams = ILaunchpadV2.PresaleInfoParams({
            owner: user1,
            token: address(deXa),
            minTokensToSell: 500000e18,
            maxTokensToSell: 1000000e18,
            roundDeep: 3,
            coinFeeRate: 100,
            tokenFeeRate: 100,
            releaseMonth: 10,
            fundType: ILaunchpadV2.FundType.BUSD
        });

        ILaunchpadV2.RoundInfo[] memory _roundsParams = new ILaunchpadV2.RoundInfo[](3);
        _roundsParams[0] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 86400),
            endTime: (block.timestamp + 12 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 50000e18,
            pricePerToken: 1e18
        });
        _roundsParams[1] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 12 weeks),
            endTime: (block.timestamp + 24 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 25000e18,
            pricePerToken: 1e18
        });
        _roundsParams[2] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 24 weeks),
            endTime: (block.timestamp + 36 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 10000e18,
            pricePerToken: 1e18
        });
        deXa.approve(address(instance), 1500000e18);
        instance.createPresale{value: 0.001 ether}(_infoParams, _roundsParams);

        assertEq(instance.createdPresale(_infoParams.token), true, "Not Created");

        ILaunchpadV2.PresaleInfoParams memory _infoParams1 = ILaunchpadV2.PresaleInfoParams({
            owner: user1,
            token: address(deXa),
            minTokensToSell: 5000e18,
            maxTokensToSell: 10000e18,
            roundDeep: 3,
            coinFeeRate: 100,
            tokenFeeRate: 100,
            releaseMonth: 10,
            fundType: ILaunchpadV2.FundType.BUSD
        });
        bytes4 selector = bytes4(keccak256("IncorrectAmountToSell()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        instance.updatePresale(_infoParams1, _roundsParams);
    }

    // TestCases:: For BUSD purchases
    function testShouldPurchase() public {
        deal({token: address(deXa), to: address(user1), give: 50000000e18});

        deal(user1, 5 ether);

        vm.startPrank(user1);

        ILaunchpadV2.PresaleInfoParams memory _infoParams = ILaunchpadV2.PresaleInfoParams({
            owner: user1,
            token: address(deXa),
            minTokensToSell: 500000e18,
            maxTokensToSell: 1000000e18,
            roundDeep: 3,
            coinFeeRate: 100,
            tokenFeeRate: 100,
            releaseMonth: 10,
            fundType: ILaunchpadV2.FundType.BUSD
        });

        ILaunchpadV2.RoundInfo[] memory _roundsParams = new ILaunchpadV2.RoundInfo[](3);
        _roundsParams[0] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 86400),
            endTime: (block.timestamp + 12 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 50000e18,
            pricePerToken: 1e18
        });
        _roundsParams[1] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 12 weeks),
            endTime: (block.timestamp + 24 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 25000e18,
            pricePerToken: 1e18
        });
        _roundsParams[2] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 24 weeks),
            endTime: (block.timestamp + 36 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 10000e18,
            pricePerToken: 1e18
        });
        deXa.approve(address(instance), 1500000e18);
        instance.createPresale{value: 0.001 ether}(_infoParams, _roundsParams);

        assertEq(instance.createdPresale(_infoParams.token), true, "Not Created");

        vm.warp(block.timestamp + 86400);
        changePrank(user2);

        IERC20(busd).approve(address(instance), 1000e18);
        instance.tokenPurchaseWithBUSD(_infoParams.token, 1000e18);

        (, uint256 raisingFundForPresale,,,) = instance.presaleInfo(address(deXa));

        assertEq(raisingFundForPresale, 1000e18, "Not equal");
    }

    function testShouldNotPurchaseDueToMinContribution() public {
        deal({token: address(deXa), to: address(user1), give: 50000000e18});

        deal(user1, 5 ether);

        vm.startPrank(user1);

        ILaunchpadV2.PresaleInfoParams memory _infoParams = ILaunchpadV2.PresaleInfoParams({
            owner: user1,
            token: address(deXa),
            minTokensToSell: 500000e18,
            maxTokensToSell: 1000000e18,
            roundDeep: 3,
            coinFeeRate: 100,
            tokenFeeRate: 100,
            releaseMonth: 10,
            fundType: ILaunchpadV2.FundType.BUSD
        });

        ILaunchpadV2.RoundInfo[] memory _roundsParams = new ILaunchpadV2.RoundInfo[](3);
        _roundsParams[0] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 86400),
            endTime: (block.timestamp + 12 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 50000e18,
            pricePerToken: 1e18
        });
        _roundsParams[1] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 12 weeks),
            endTime: (block.timestamp + 24 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 25000e18,
            pricePerToken: 1e18
        });
        _roundsParams[2] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 24 weeks),
            endTime: (block.timestamp + 36 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 10000e18,
            pricePerToken: 1e18
        });
        deXa.approve(address(instance), 1500000e18);
        instance.createPresale{value: 0.001 ether}(_infoParams, _roundsParams);

        assertEq(instance.createdPresale(_infoParams.token), true, "Not Created");

        vm.warp(block.timestamp + 86400);
        changePrank(user2);

        IERC20(busd).approve(address(instance), 1000e18);

        bytes4 selector = bytes4(keccak256("IncorrectMinContribution()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        instance.tokenPurchaseWithBUSD(_infoParams.token, 100e18);
    }

    function testShouldNotPurchaseDueToMaxContribution() public {
        deal({token: address(deXa), to: address(user1), give: 50000000e18});

        deal(user1, 5 ether);

        vm.startPrank(user1);

        ILaunchpadV2.PresaleInfoParams memory _infoParams = ILaunchpadV2.PresaleInfoParams({
            owner: user1,
            token: address(deXa),
            minTokensToSell: 500000e18,
            maxTokensToSell: 1000000e18,
            roundDeep: 3,
            coinFeeRate: 100,
            tokenFeeRate: 100,
            releaseMonth: 10,
            fundType: ILaunchpadV2.FundType.BUSD
        });

        ILaunchpadV2.RoundInfo[] memory _roundsParams = new ILaunchpadV2.RoundInfo[](3);
        _roundsParams[0] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 86400),
            endTime: (block.timestamp + 12 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 800e18,
            tokensToSell: 50000e18,
            pricePerToken: 1e18
        });
        _roundsParams[1] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 12 weeks),
            endTime: (block.timestamp + 24 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 25000e18,
            pricePerToken: 1e18
        });
        _roundsParams[2] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 24 weeks),
            endTime: (block.timestamp + 36 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 10000e18,
            pricePerToken: 1e18
        });
        deXa.approve(address(instance), 1500000e18);
        instance.createPresale{value: 0.001 ether}(_infoParams, _roundsParams);

        assertEq(instance.createdPresale(_infoParams.token), true, "Not Created");

        vm.warp(block.timestamp + 86400);
        changePrank(user2);

        IERC20(busd).approve(address(instance), 1000e18);

        bytes4 selector = bytes4(keccak256("IncorrectMaxContribution()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        instance.tokenPurchaseWithBUSD(_infoParams.token, 1000e18);
    }

    function testShouldNotPurchaseDueToSellLimitExceeding() public {
        deal({token: address(deXa), to: address(user1), give: 50000000e18});

        deal(user1, 5 ether);

        vm.startPrank(user1);

        ILaunchpadV2.PresaleInfoParams memory _infoParams = ILaunchpadV2.PresaleInfoParams({
            owner: user1,
            token: address(deXa),
            minTokensToSell: 100e18,
            maxTokensToSell: 1500e18,
            roundDeep: 3,
            coinFeeRate: 100,
            tokenFeeRate: 100,
            releaseMonth: 10,
            fundType: ILaunchpadV2.FundType.BUSD
        });

        ILaunchpadV2.RoundInfo[] memory _roundsParams = new ILaunchpadV2.RoundInfo[](3);
        _roundsParams[0] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 86400),
            endTime: (block.timestamp + 12 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 500e18,
            pricePerToken: 1e18
        });
        _roundsParams[1] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 12 weeks),
            endTime: (block.timestamp + 24 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 500e18,
            pricePerToken: 1e18
        });
        _roundsParams[2] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 24 weeks),
            endTime: (block.timestamp + 36 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 500e18,
            pricePerToken: 1e18
        });
        deXa.approve(address(instance), 1500000e18);
        instance.createPresale{value: 0.001 ether}(_infoParams, _roundsParams);

        assertEq(instance.createdPresale(_infoParams.token), true, "Not Created");

        vm.warp(block.timestamp + 86400);
        changePrank(user2);

        IERC20(busd).approve(address(instance), 10000e18);

        bytes4 selector = bytes4(keccak256("SellLimitExceeding()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        instance.tokenPurchaseWithBUSD(_infoParams.token, 5000e18);

        (, uint256 raisingFundForPresale,,,) = instance.presaleInfo(address(deXa));

        assertEq(raisingFundForPresale, 0, "Not equal");
    }

    function testShouldNotPurchaseDueToTokensAlreadySold() public {
        deal({token: address(deXa), to: address(user1), give: 511500e18});
        deal({token: address(busd), to: address(user2), give: 50000e18});
        deal({token: address(busd), to: address(user3), give: 50000e18});

        deal(user1, 5 ether);

        vm.startPrank(user1);

        ILaunchpadV2.PresaleInfoParams memory _infoParams = ILaunchpadV2.PresaleInfoParams({
            owner: user1,
            token: address(deXa),
            minTokensToSell: 100e18,
            maxTokensToSell: 1500e18,
            roundDeep: 3,
            coinFeeRate: 100,
            tokenFeeRate: 100,
            releaseMonth: 10,
            fundType: ILaunchpadV2.FundType.BUSD
        });

        ILaunchpadV2.RoundInfo[] memory _roundsParams = new ILaunchpadV2.RoundInfo[](3);
        _roundsParams[0] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 86400),
            endTime: (block.timestamp + 12 weeks),
            lockMonths: 3,
            minContribution: 50e18,
            maxContribution: 10000000000e18,
            tokensToSell: 500e18,
            pricePerToken: 1e18
        });
        _roundsParams[1] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 12 weeks),
            endTime: (block.timestamp + 24 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 500e18,
            pricePerToken: 1e18
        });
        _roundsParams[2] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 24 weeks),
            endTime: (block.timestamp + 36 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 500e18,
            pricePerToken: 1e18
        });
        deXa.approve(address(instance), 1500000e18);
        instance.createPresale{value: 0.001 ether}(_infoParams, _roundsParams);

        assertEq(instance.createdPresale(_infoParams.token), true, "Not Created");

        vm.warp(block.timestamp + 86400);
        changePrank(user2);

        IERC20(busd).approve(address(instance), 10000e18);

        instance.tokenPurchaseWithBUSD(_infoParams.token, 450e18);

        changePrank(user3);

        IERC20(busd).approve(address(instance), 10000e18);

        bytes4 selector = bytes4(keccak256("TokensAlreadySold()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        instance.tokenPurchaseWithBUSD(_infoParams.token, 100e18);

        (, uint256 raisingFundForPresale,,,) = instance.presaleInfo(address(deXa));

        assertEq(raisingFundForPresale, 450e18, "Not equal");
    }

    function testShouldNotPurchaseDueToRoundNotStarted() public {
        deal({token: address(deXa), to: address(user1), give: 50000000e18});

        deal(user1, 5 ether);

        vm.startPrank(user1);

        ILaunchpadV2.PresaleInfoParams memory _infoParams = ILaunchpadV2.PresaleInfoParams({
            owner: user1,
            token: address(deXa),
            minTokensToSell: 500000e18,
            maxTokensToSell: 1000000e18,
            roundDeep: 3,
            coinFeeRate: 100,
            tokenFeeRate: 100,
            releaseMonth: 10,
            fundType: ILaunchpadV2.FundType.BUSD
        });

        ILaunchpadV2.RoundInfo[] memory _roundsParams = new ILaunchpadV2.RoundInfo[](3);
        _roundsParams[0] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 86400),
            endTime: (block.timestamp + 12 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 50000e18,
            pricePerToken: 1e18
        });
        _roundsParams[1] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 12 weeks),
            endTime: (block.timestamp + 24 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 25000e18,
            pricePerToken: 1e18
        });
        _roundsParams[2] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 24 weeks),
            endTime: (block.timestamp + 36 weeks),
            lockMonths: 3,
            minContribution: 500e18,
            maxContribution: 10000000000e18,
            tokensToSell: 10000e18,
            pricePerToken: 1e18
        });
        deXa.approve(address(instance), 1500000e18);

        instance.createPresale{value: 0.001 ether}(_infoParams, _roundsParams);

        assertEq(instance.createdPresale(_infoParams.token), true, "Not Created");

        changePrank(user2);

        IERC20(busd).approve(address(instance), 1000e18);
        bytes4 selector = bytes4(keccak256("IncorrectRoundsCount()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        instance.tokenPurchaseWithBUSD(_infoParams.token, 1000e18);

        (, uint256 raisingFundForPresale,,,) = instance.presaleInfo(address(deXa));

        assertEq(raisingFundForPresale, 0, "Not equal");
    }

    // TestCases:: For BNB purchases
    function testShouldPurchaseForDexaAgainstBNB() public {
        deal({token: address(deXa), to: address(user1), give: 50000000e18});

        deal(user1, 5 ether);

        vm.startPrank(user1);

        ILaunchpadV2.PresaleInfoParams memory _infoParams = ILaunchpadV2.PresaleInfoParams({
            owner: user1,
            token: address(deXa),
            minTokensToSell: 500000e18,
            maxTokensToSell: 1000000e18,
            roundDeep: 3,
            coinFeeRate: 100,
            tokenFeeRate: 100,
            releaseMonth: 10,
            fundType: ILaunchpadV2.FundType.BNB
        });

        ILaunchpadV2.RoundInfo[] memory _roundsParams = new ILaunchpadV2.RoundInfo[](3);
        _roundsParams[0] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 86400),
            endTime: (block.timestamp + 12 weeks),
            lockMonths: 3,
            minContribution: 1e18,
            maxContribution: 10000000000e18,
            tokensToSell: 50000e18,
            pricePerToken: 50000000000000000
        });
        _roundsParams[1] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 12 weeks),
            endTime: (block.timestamp + 24 weeks),
            lockMonths: 3,
            minContribution: 1e18,
            maxContribution: 10000000000e18,
            tokensToSell: 25000e18,
            pricePerToken: 75000000000000000
        });
        _roundsParams[2] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 24 weeks),
            endTime: (block.timestamp + 36 weeks),
            lockMonths: 3,
            minContribution: 1e18,
            maxContribution: 10000000000e18,
            tokensToSell: 10000e18,
            pricePerToken: 1e18
        });
        deXa.approve(address(instance), 1500000e18);
        instance.createPresale{value: 0.001 ether}(_infoParams, _roundsParams);

        assertEq(instance.createdPresale(_infoParams.token), true, "Not Created");

        vm.warp(block.timestamp + 86400);
        changePrank(user2);
        deal(user2, 5 ether);

        instance.tokenPurchaseWithBNB{value: 3 ether}(_infoParams.token);

        (, uint256 raisingFundForPresale,,,) = instance.presaleInfo(address(deXa));

        assertEq(raisingFundForPresale, 3 ether, "Not equal");
    }

    function testShouldNotPurchaseDueToAlreadySoldUsingBNB() public {
        deal({token: address(deXa), to: address(user1), give: 50000000e18});

        deal(user1, 5 ether);

        vm.startPrank(user1);

        ILaunchpadV2.PresaleInfoParams memory _infoParams = ILaunchpadV2.PresaleInfoParams({
            owner: user1,
            token: address(deXa),
            minTokensToSell: 1e18,
            maxTokensToSell: 10000e18,
            roundDeep: 3,
            coinFeeRate: 100,
            tokenFeeRate: 100,
            releaseMonth: 10,
            fundType: ILaunchpadV2.FundType.BNB
        });

        ILaunchpadV2.RoundInfo[] memory _roundsParams = new ILaunchpadV2.RoundInfo[](3);
        _roundsParams[0] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 86400),
            endTime: (block.timestamp + 12 weeks),
            lockMonths: 3,
            minContribution: 1e18,
            maxContribution: 10e18,
            tokensToSell: 30e18,
            pricePerToken: 50000000000000000
        });
        _roundsParams[1] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 12 weeks),
            endTime: (block.timestamp + 24 weeks),
            lockMonths: 3,
            minContribution: 1e18,
            maxContribution: 10e18,
            tokensToSell: 30e18,
            pricePerToken: 75000000000000000
        });
        _roundsParams[2] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 24 weeks),
            endTime: (block.timestamp + 36 weeks),
            lockMonths: 3,
            minContribution: 1e18,
            maxContribution: 10e18,
            tokensToSell: 30e18,
            pricePerToken: 1e18
        });
        deXa.approve(address(instance), 1500000e18);
        instance.createPresale{value: 0.001 ether}(_infoParams, _roundsParams);

        assertEq(instance.createdPresale(_infoParams.token), true, "Not Created");

        vm.warp(block.timestamp + 86400);
        changePrank(user2);
        deal(user2, 15 ether);

        bytes4 selector = bytes4(keccak256("TokensAlreadySold()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        instance.tokenPurchaseWithBNB{value: 10 ether}(_infoParams.token);
    }

    function testShouldNotPurchaseDueToMinContributionUsingBNB() public {
        deal({token: address(deXa), to: address(user1), give: 50000000e18});

        deal(user1, 5 ether);
        deal(user2, 5 ether);

        vm.startPrank(user1);

        ILaunchpadV2.PresaleInfoParams memory _infoParams = ILaunchpadV2.PresaleInfoParams({
            owner: user1,
            token: address(deXa),
            minTokensToSell: 500000e18,
            maxTokensToSell: 1000000e18,
            roundDeep: 3,
            coinFeeRate: 100,
            tokenFeeRate: 100,
            releaseMonth: 10,
            fundType: ILaunchpadV2.FundType.BNB
        });

        ILaunchpadV2.RoundInfo[] memory _roundsParams = new ILaunchpadV2.RoundInfo[](3);
        _roundsParams[0] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 86400),
            endTime: (block.timestamp + 12 weeks),
            lockMonths: 3,
            minContribution: 3e18,
            maxContribution: 10000000000e18,
            tokensToSell: 50000e18,
            pricePerToken: 50000000000000000
        });
        _roundsParams[1] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 12 weeks),
            endTime: (block.timestamp + 24 weeks),
            lockMonths: 3,
            minContribution: 1e18,
            maxContribution: 10000000000e18,
            tokensToSell: 25000e18,
            pricePerToken: 75000000000000000
        });
        _roundsParams[2] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 24 weeks),
            endTime: (block.timestamp + 36 weeks),
            lockMonths: 3,
            minContribution: 1e18,
            maxContribution: 10000000000e18,
            tokensToSell: 10000e18,
            pricePerToken: 1e18
        });
        deXa.approve(address(instance), 1500000e18);
        instance.createPresale{value: 0.001 ether}(_infoParams, _roundsParams);

        assertEq(instance.createdPresale(_infoParams.token), true, "Not Created");

        vm.warp(block.timestamp + 86400);
        changePrank(user2);

        IERC20(busd).approve(address(instance), 1000e18);

        bytes4 selector = bytes4(keccak256("IncorrectMinContribution()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        instance.tokenPurchaseWithBNB{value: 1 ether}(_infoParams.token);
    }

    function testShouldNotPurchaseDueToMaxContributionUsingBNB() public {
        deal({token: address(deXa), to: address(user1), give: 50000000e18});

        deal(user1, 5 ether);
        deal(user2, 5 ether);

        vm.startPrank(user1);

        ILaunchpadV2.PresaleInfoParams memory _infoParams = ILaunchpadV2.PresaleInfoParams({
            owner: user1,
            token: address(deXa),
            minTokensToSell: 500000e18,
            maxTokensToSell: 1000000e18,
            roundDeep: 3,
            coinFeeRate: 100,
            tokenFeeRate: 100,
            releaseMonth: 10,
            fundType: ILaunchpadV2.FundType.BNB
        });

        ILaunchpadV2.RoundInfo[] memory _roundsParams = new ILaunchpadV2.RoundInfo[](3);
        _roundsParams[0] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 86400),
            endTime: (block.timestamp + 12 weeks),
            lockMonths: 3,
            minContribution: 1e18,
            maxContribution: 3e18,
            tokensToSell: 50000e18,
            pricePerToken: 50000000000000000
        });
        _roundsParams[1] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 12 weeks),
            endTime: (block.timestamp + 24 weeks),
            lockMonths: 3,
            minContribution: 1e18,
            maxContribution: 10000000000e18,
            tokensToSell: 25000e18,
            pricePerToken: 75000000000000000
        });
        _roundsParams[2] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 24 weeks),
            endTime: (block.timestamp + 36 weeks),
            lockMonths: 3,
            minContribution: 1e18,
            maxContribution: 10000000000e18,
            tokensToSell: 10000e18,
            pricePerToken: 1e18
        });
        deXa.approve(address(instance), 1500000e18);
        instance.createPresale{value: 0.001 ether}(_infoParams, _roundsParams);

        assertEq(instance.createdPresale(_infoParams.token), true, "Not Created");

        vm.warp(block.timestamp + 86400);
        changePrank(user2);

        IERC20(busd).approve(address(instance), 1000e18);

        bytes4 selector = bytes4(keccak256("IncorrectMaxContribution()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        instance.tokenPurchaseWithBNB{value: 5 ether}(_infoParams.token);
    }

    function testShouldPurchaseDueToRoundNotStartedUsingBNB() public {
        deal({token: address(deXa), to: address(user1), give: 50000000e18});

        deal(user1, 5 ether);

        vm.startPrank(user1);

        ILaunchpadV2.PresaleInfoParams memory _infoParams = ILaunchpadV2.PresaleInfoParams({
            owner: user1,
            token: address(deXa),
            minTokensToSell: 500000e18,
            maxTokensToSell: 1000000e18,
            roundDeep: 3,
            coinFeeRate: 100,
            tokenFeeRate: 100,
            releaseMonth: 10,
            fundType: ILaunchpadV2.FundType.BNB
        });

        ILaunchpadV2.RoundInfo[] memory _roundsParams = new ILaunchpadV2.RoundInfo[](3);
        _roundsParams[0] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 86400),
            endTime: (block.timestamp + 12 weeks),
            lockMonths: 3,
            minContribution: 1e18,
            maxContribution: 10000000000e18,
            tokensToSell: 50000e18,
            pricePerToken: 50000000000000000
        });
        _roundsParams[1] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 12 weeks),
            endTime: (block.timestamp + 24 weeks),
            lockMonths: 3,
            minContribution: 1e18,
            maxContribution: 10000000000e18,
            tokensToSell: 25000e18,
            pricePerToken: 75000000000000000
        });
        _roundsParams[2] = ILaunchpadV2.RoundInfo({
            startTime: (block.timestamp + 24 weeks),
            endTime: (block.timestamp + 36 weeks),
            lockMonths: 3,
            minContribution: 1e18,
            maxContribution: 10000000000e18,
            tokensToSell: 10000e18,
            pricePerToken: 1e18
        });
        deXa.approve(address(instance), 1500000e18);
        instance.createPresale{value: 0.001 ether}(_infoParams, _roundsParams);

        assertEq(instance.createdPresale(_infoParams.token), true, "Not Created");

        changePrank(user2);
        deal(user2, 5 ether);

        bytes4 selector = bytes4(keccak256("IncorrectRoundsCount()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        instance.tokenPurchaseWithBNB{value: 3 ether}(_infoParams.token);

        (, uint256 raisingFundForPresale,,,) = instance.presaleInfo(address(deXa));

        assertEq(raisingFundForPresale, 0, "Not equal");
    }
}
