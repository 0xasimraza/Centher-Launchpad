const { ethers } = require("hardhat");

const launchpadAbi = require("./utils/Launchpad.json");
const tokenABI = require("./utils/token.json");
const { parseEther, parseUnits, MaxInt256 } = require("ethers");

const launchpad = "0x7Ab704C69618ABbb0bf02E4F00249F86AcF59925"; //testnet

let provider;

let creator = process.env.PRIVATE_KEY;
let buyer1 = process.env.PRIVATE_KEY1;
let buyer2 = process.env.PRIVATE_KEY2;

async function main() {
  //   const presaleToken = "0x17251778DF10EAf734B69E2109e9190cB061F809"; // xyz
  const presaleToken = "0xEF52501F1062dE28106602A7fda41b8A285f8dD9"; //abc
  const usdt = "0x1B855BF0e0eDBF394cB8F74D906d8d93A1C2D6e0";

  //   createPresale Args
  const presaleInfoParams = {
    owner: "0xdD15D2650387Fb6FEDE27ae7392C402a393F8A37",
    token: presaleToken,
    minTokensToSell: parseUnits("50", "ether"), 
    maxTokensToSell: parseUnits("500000", "ether"), 
    roundDeep: 3,
    coinFeeRate: 100,
    tokenFeeRate: 100,
    releaseMonth: 10,
    isRefSupport: false,
    fundType: 1,  
  };

  const roundsParams = [
    {
      startTime: Math.floor(Date.now() / 1000),
      endTime: Math.floor(Date.now() / 1000) + 604800, 
      lockMonths: 3,
      minContribution: parseUnits("5", "ether"), 
      maxContribution: parseUnits("10000", "ether"), 
      tokensToSell: parseUnits("100000", "ether"), 
      pricePerToken: parseUnits("0.8", "ether"), 
    },
    {
      startTime: Math.floor(Date.now() / 1000) + 604800,
      endTime: Math.floor(Date.now() / 1000) + 60480 * 2, 
      lockMonths: 3,
      minContribution: parseUnits("5", "ether"), 
      maxContribution: parseUnits("10000", "ether"), 
      tokensToSell: parseUnits("100000", "ether"), 
      pricePerToken: parseUnits("1", "ether"), 
    },
    {
      startTime: Math.floor(Date.now() / 1000) + 60480 * 2,
      endTime: Math.floor(Date.now() / 1000) + 60480 * 3, 
      lockMonths: 3,
      minContribution: parseUnits("5", "ether"), 
      maxContribution: parseUnits("10000", "ether"), 
      tokensToSell: parseUnits("100000", "ether"),
      pricePerToken: parseUnits("1.2", "ether"),
    },
  ];

  //   let args = [presaleInfoParams, roundsParams];

  //   await createPresale(args, presaleToken);

  //   await updatePresale(args, presaleToken);

  //   await tokenPurchaseWithBUSD(presaleToken, usdt, "2500", buyer2);
}

function getContract(address, abi, user) {
  return new ethers.Contract(address, abi, getSigner(user));
}

function getPrivateKey(user) {
  return user;
}

function getSigner(user) {
  return new ethers.Wallet(getPrivateKey(user), getProvider());
}

function getProvider() {
  if (process.env.NETWORK === "goerli") {
    provider = new ethers.JsonRpcProvider(
      "https://goerli.infura.io/v3/b17715f3b04d4ccb90389a946de9c598"
    );

    return provider;
  } else if (process.env.NETWORK === "bsc") {
    return new ethers.JsonRpcProvider(process.env.BSC_URL);
  } else {
    return "Not Valid Network";
  }
}

async function createPresale(args, _token) {
  console.log("Current Signer: ", await getSigner(creator));

  const token = getContract(_token, tokenABI, creator);

  const contract = getContract(launchpad, launchpadAbi, creator);

  try {
    let approvetx = await token.approve(launchpad, MaxInt256);
    await approvetx.wait();
    console.log("approve txhash: ", await approvetx.hash);

    let tx = await contract.createPresale(args[0], args[1], {
      value: parseUnits("0.001", "ether"),
    });
    await tx.wait();
    console.log("createPresale txhash: ", await tx.hash);
  } catch (error) {
    console.log("error: ", error);
  }
}

async function updatePresale(args, _token) {
  let account = await getSigner(creator);
  console.log("Current Signer: ", account);

  const token = getContract(_token, tokenABI, creator);

  const contract = getContract(launchpad, launchpadAbi, creator);

  try {
    if (Number(await token.allowance(account, launchpad)) <= 0) {
      let approvetx = await token.approve(launchpad, MaxInt256);
      await approvetx.wait();
      console.log("approve txhash: ", await approvetx.hash);
    } else {
      console.log("Already have allowanace");
    }

    await contract.updatePresale.staticCall(args[0], args[1]);

    let tx = await contract.updatePresale(args[0], args[1]);
    await tx.wait();
    console.log("createPresale txhash: ", await tx.hash);
  } catch (error) {
    console.log("error: ", error);
  }
}

async function tokenPurchaseWithBUSD(_presaleToken, _buyToken, _amount, user) {
  let account = await getSigner(user);
  console.log("Current Signer: ", account);

  const token = getContract(_buyToken, tokenABI, user);

  const contract = getContract(launchpad, launchpadAbi, user);

  try {
    if (Number(await token.allowance(account, launchpad)) <= 0) {
      let approvetx = await token.approve(launchpad, MaxInt256);
      await approvetx.wait();
      console.log("approve txhash: ", await approvetx.hash);
    } else {
      console.log("Already have allowanace");
    }

    await contract.tokenPurchaseWithBUSD.staticCall(
      _presaleToken,
      parseUnits(_amount, "ether")
    );

    let tx = await contract.tokenPurchaseWithBUSD(
      _presaleToken,
      parseUnits(_amount, "ether")
    );
    await tx.wait();
    console.log("tokenPurchase txhash: ", await tx.hash);
  } catch (error) {
    console.log("error: ", error);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
