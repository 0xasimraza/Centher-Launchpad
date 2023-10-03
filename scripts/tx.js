const { ethers } = require("hardhat");

const launchpadAbi = require("./utils/DeXaPresale.json");
const { parseEther } = require("ethers");

const launchpad = "0x5Eaf2D08FA62220AC064Df5e47521cB7cc16F964"; //testnet
// const launchpad = "" //mainnet

let provider;

async function main() {
    //   await createAllowanceForBusdUsers();
    await createAllowanceForNtrUsers();
}

function getContract(address, abi) {
    return new ethers.Contract(address, abi, getSigner());
}

function getPrivateKey() {
    return process.env.PRIVATE_KEY;
}

function getSigner() {
    return new ethers.Wallet(getPrivateKey(), getProvider());
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

async function createAllowanceForBusdUsers() {
    console.log("Current Signer: ", await getSigner());

    const contract = getContract(launchpad, launchpadAbi);

    try {
        let tx = await contract.batchAllowanceToBusdUsers(
            ["0xF4988Cad71BDd524bb613c499dcb0e296617253f"],
            [parseEther("1500")],
            [0]
        );
        await tx.wait();
        console.log("hash: ", await tx.hash);
    } catch (error) {
        console.log("error: ", error);
    }
}

async function createAllowanceForNtrUsers() {
    console.log("Current Signer: ", await getSigner());

    const contract = getContract(launchpad, launchpadAbi);

    try {
        let tx = await contract.batchAllowanceToNtrUsers(
            ["0xF4988Cad71BDd524bb613c499dcb0e296617253f"],
            [parseEther("1000")],
            [0]
        );
        await tx.wait();
        console.log("hash: ", await tx.hash);
    } catch (error) {
        console.log("error: ", error);
    }
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
