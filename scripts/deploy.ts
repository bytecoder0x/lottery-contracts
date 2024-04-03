import hre, { ethers, tenderly } from "hardhat";
// import { REGISTRY_SEPOLIA_ADDRESS } from "./constants";
// import { verifyContract } from "./verify";
// import { PromiseOrValue } from "../typechain-types/common";

async function main() {
  const KARROT = await ethers.getContractFactory("Karrot");
  

  async function deployKarrot() {
    try {
      const karrot = await KARROT.deploy('0xEa770D20e3bD5fB576776D0797926cA11B44CeCD', '0xEa770D20e3bD5fB576776D0797926cA11B44CeCD');
      await karrot.deployed();
      return karrot.address;
    } catch (error) {
      console.error(error);
      return deployKarrot();
    }
  }


  async function deployAll() {
    const karrotAddress = await deployKarrot();
    await tenderly.verify({
      name: "Karrot",
      address: karrotAddress,
    });
  }

  deployAll();

}

main().catch((error) => {
  console.error("or this", error);
});
