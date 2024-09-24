import { HardhatRuntimeEnvironment } from "hardhat/types/runtime";

// export default async function deploy(
//   params: any,
//   hre: HardhatRuntimeEnvironment
// ): Promise<void> {
//   const ethers = hre.ethers;
//   const upgrades = hre.upgrades;

//   const [account] = await ethers.getSigners();
//   console.log("connected account: ", account.address);

//   const DeXaPresale = await ethers.getContractFactory("DeXaPresale");

//   //testnet:: goerli
//   // let args = [
//   //   "0x935ACed044481cAd3d48d051e65a851Cd9Cb76f7", // dexa
//   //   "0x82844F286e6f441827610D9f06E6831635bE252c", // ntr
//   //   "0x1B855BF0e0eDBF394cB8F74D906d8d93A1C2D6e0", // usdt
//   //   "0x538584360a8ec67338Ce73721585aC386d7a4e6E", // centher registration
//   //   "0xdD15D2650387Fb6FEDE27ae7392C402a393F8A37", // wallet address
//   //   "0xdD15D2650387Fb6FEDE27ae7392C402a393F8A37", // company address
//   // ];

//   //testnet:: sepolia
//   let args = [
//     "0x38d5bfEB6A7F1b755217dB6D1E713BEeF2A6fdAb", // dexa
//     "0x38d5bfEB6A7F1b755217dB6D1E713BEeF2A6fdAb", // ntr
//     "0x37D6Eb070d29B503e4fc882F6Dc47F2DD201E016", // usdt
//     "0xE90352E7166f8Ed132b629EC6D3aCA4d14816404", // centher registration
//     "0xdD15D2650387Fb6FEDE27ae7392C402a393F8A37", // wallet address
//     "0xdD15D2650387Fb6FEDE27ae7392C402a393F8A37", // company address
//   ];

//   ////mainnet
//   // let args = [
//   //   "", // dexa
//   //   "", // ntr
//   //   "", // usdt
//   //   "", // centher registration
//   //   "", // wallet address
//   //   "", // company address
//   // ];

//   const instance = await upgrades.deployProxy(DeXaPresale, args, {
//     initializer: "initialize",
//   });
//   await instance.waitForDeployment();

//   await delay(26000);
//   console.log("Deployed Address", instance.target);

//   // Upgrading
//   // const DeXaPresaleV2 = await ethers.getContractFactory("DeXaPresale");
//   // const instance = await upgrades.upgradeProxy(
//   //   "0x5Eaf2D08FA62220AC064Df5e47521cB7cc16F964",
//   //   DeXaPresaleV2
//   // ); //testnet
//   // console.log("Deployed Address", instance.target);

//   if (hre.network.name != "hardhat") {
//     await hre.run("verify:verify", {
//       address: instance.target,
//       constructorArguments: [],
//     });
//   }
// }

export default async function deploy2(
  params: any,
  hre: HardhatRuntimeEnvironment
): Promise<void> {
  const ethers = hre.ethers;
  const upgrades = hre.upgrades;
  console.log("CALLING Deploy2");

  const [account] = await ethers.getSigners();
  console.log("connected account: ", account.address);

  const LaunchpadV2 = await ethers.getContractFactory("LaunchpadV2");

  // //testnet: goerli
  // let args = [
  //   "0x538584360a8ec67338Ce73721585aC386d7a4e6E", // centher registration
  //   "0x1B855BF0e0eDBF394cB8F74D906d8d93A1C2D6e0", // usdt
  // ];

  //testnet: sepolia
  let args = [
    "0xE90352E7166f8Ed132b629EC6D3aCA4d14816404", // centher registration
    "0x37D6Eb070d29B503e4fc882F6Dc47F2DD201E016", // usdt
  ];

  ////mainnet
  // let args = [
  //   "", // dexa
  //   "", // ntr
  //   "", // usdt
  //   "", // centher registration
  //   "", // wallet address
  //   "", // company address
  // ];

  // const instance = await upgrades.deployProxy(LaunchpadV2, args, {
  //   initializer: "initialize",
  //   // txOverrides: { maxFeePerGas: 65e9 },
  // });
  // await instance.waitForDeployment();

  // await delay(26000);
  // console.log("Deployed Address", instance.target);

  // Upgrading  //"0xEB18eC8c89FFd3129c9779e20Ec9d6877b1F7d1d",
  const DeXaPresaleV2 = await ethers.getContractFactory("LaunchpadV2");
  const instance = await upgrades.upgradeProxy(
    "0x8544884E25fC204272B19C193F9E3d37Eb5b672b",
    LaunchpadV2
  ); //testnet
  console.log("Deployed Address", instance.target);

  if (hre.network.name != "hardhat") {
    await hre.run("verify:verify", {
      address: instance.target,
      constructorArguments: [],
    });
  }
}

function delay(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
//proxy 0x719b7451Bc4247cd4424d92a6D441FFAEDD50d34
//implementation 0x78F2dC02452367114F7e59FaCd41653DFBBF9Ae8

// Object.values({
//   dexa: args[0],
//   token: args[1],
//   busd: args[2],
//   registration: args[3],
//   _coreTeam: args[4],
//   _company: args[5],
// }),
// new proxy: 0xaeC113a50703BD248712C42e74f35E51968c2b90 //mainnet copy
// another proxy: 0x1Ee9fD67ceA1E5Ea130a6ceAAe51EA8c7BF65Ec8 // 15mins = month

// proxy with usdt: 0x5Eaf2D08FA62220AC064Df5e47521cB7cc16F964
