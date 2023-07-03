const { expect } = require("chai");
const { ethers, userConfig } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe("Centher launchpad", function () {
  let owner;
  let tokenAddress;
  let busd;
  let coreTeamAddress;
  let CompanyAddress;
  let dexa;
  let centherRegister, dexaPresale;

  beforeEach(async () => {
    [owner, coreTeamAddress, CompanyAddress, user1, user2] =
      await ethers.getSigners();

    const Dexa = await ethers.getContractFactory("Token");
    dexa = await Dexa.deploy("Dexa", "DXC");
    await dexa.deployed();

    const TokenAddress = await ethers.getContractFactory("Token");
    tokenAddress = await TokenAddress.deploy("token", "T");
    await tokenAddress.deployed();

    const Busd = await ethers.getContractFactory("Token");
    busd = await Busd.deploy("busd", "BUSD");
    await busd.deployed();

    const CentherRegiter = await ethers.getContractFactory(
      "CentherRegistration"
    );
    centherRegister = await CentherRegiter.deploy();
    await centherRegister.deployed();

    const DeXaPresale = await ethers.getContractFactory("DeXaPresale");
    dexaPresale = await DeXaPresale.connect(owner).deploy(
      dexa.address,
      tokenAddress.address,
      busd.address,
      centherRegister.address,
      coreTeamAddress.address,
      CompanyAddress.address
    );
    await dexaPresale.deployed();

    await busd.transfer(user1.address, ethers.utils.parseEther("1500"));
    await busd.transfer(user2.address, ethers.utils.parseEther("1500"));

    await centherRegister.connect(user1).registerWithoutReferrer({
      value: ethers.utils.parseEther("0.025"),
    });
    await centherRegister.connect(owner).registerWithoutReferrer({
      value: ethers.utils.parseEther("0.025"),
    });
  });

  describe("tokenPurchaseWithBUSD", () => {
    it("Should set round 1 successfully", async () => {
      let blockTimestamp = await time.increase(3600);
      await dexaPresale
        .connect(owner)
        .setRoundInfoForBusd(
          0,
          ethers.utils.parseEther("0.08"),
          blockTimestamp,
          blockTimestamp + 2629743,
          4,
          ethers.utils.parseUnits("1000", 18),
          ethers.utils.parseUnits("150", 18),
          ethers.utils.parseUnits("5000", 18)
        );
    });
    it("should purchase tokens with BUSD", async () => {
      let blockTimestamp = await time.increase(3600);
      const busdAmount = ethers.utils.parseUnits("100", 18);
      await dexaPresale
        .connect(owner)
        .setRoundInfoForBusd(
          0,
          ethers.utils.parseEther("0.08"),
          blockTimestamp,
          blockTimestamp + 2629743,
          4,
          ethers.utils.parseUnits("1000", 18),
          ethers.utils.parseUnits("100", 18),
          ethers.utils.parseUnits("5000", 18)
        );
      await busd.connect(user1).approve(dexaPresale.address, busdAmount);
      await dexaPresale.connect(user1).tokenPurchaseWithBUSD(busdAmount);
      expect(await busd.balanceOf(dexaPresale.address)).to.equal(busdAmount);
    });
  });

  describe("claimTokensFromBusd", () => {
    it("11", async () => {
      // await busd
      // .connect(owner)
      // .transfer(owner, ethers.utils.parseEther("2000"));
      const tokenAmount = ethers.utils.parseEther("2000", 18);
      let blockTimestamp = await time.increase(3600);
      await dexaPresale
        .connect(owner)
        .setRoundInfoForBusd(
          0,
          ethers.utils.parseEther("0.08"),
          blockTimestamp,
          blockTimestamp + 2629743,
          4,
          ethers.utils.parseUnits("1000", 18),
          ethers.utils.parseUnits("150", 18),
          ethers.utils.parseUnits("5000", 18)
        );
      let round = await dexaPresale.getRound();
      await busd.connect(owner).approve(dexaPresale.address, tokenAmount);
      await dexaPresale.connect(owner).depositBusdForReward(tokenAmount);
      await dexaPresale
        .connect(owner)
        .allowanceToUser(user1.address, tokenAmount, round);

      blockTimestamp = await time.increase(2629743);
      await dexaPresale.connect(owner).withdrawBusdForCoreTeam();

      let coreTeamAddress = await dexaPresale.coreTeamAddress();
      console.log("ba: ", coreTeamAddress);
      let balance = await busd.balanceOf(coreTeamAddress);
      console.log("balance: ", balance);
      // await balance.balanceOf(coreTeamAddress.address);

      // let b = await busd.balanceOf(owner);
      // console.log("b: ", b);
    });
  });
});
