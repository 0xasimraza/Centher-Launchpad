import { HardhatRuntimeEnvironment } from "hardhat/types/runtime";

export default async function deploy(
  params: any,
  hre: HardhatRuntimeEnvironment
): Promise<void> {
  const ethers = hre.ethers;
  const upgrades = hre.upgrades;

  const [account] = await ethers.getSigners();

  console.log(
    `Balance for 1st account ${await account.getAddress()}: ${await account.getBalance()}`
  );

  const DeXaPresale = await ethers.getContractFactory("DeXaPresale");

  let args = [
    "0x935ACed044481cAd3d48d051e65a851Cd9Cb76f7",
    "0x82844F286e6f441827610D9f06E6831635bE252c",
    "0x143c4546F845d3883B16dd2D90CfA371A2bB3EB9",
    "0x538584360a8ec67338Ce73721585aC386d7a4e6E",
    "0xdD15D2650387Fb6FEDE27ae7392C402a393F8A37",
    "0xdD15D2650387Fb6FEDE27ae7392C402a393F8A37",
  ];

  const instance = await upgrades.deployProxy(DeXaPresale, args, {
    initializer: "initialize",
  });
  await instance.deployed();
  await delay(26000);
  console.log("Deployed Address", instance.address);

  // Upgrading
  //   const DeXaPresaleV2 = await ethers.getContractFactory("DeXaPresale");
  //   const upgraded = await upgrades.upgradeProxy(
  //     "0x719b7451Bc4247cd4424d92a6D441FFAEDD50d34",
  //     DeXaPresaleV2
  //   );
  //   console.log("Deployed Address", upgraded.address);

  if (hre.network.name != "hardhat") {
    await hre.run("verify:verify", {
      address: instance.address,
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
