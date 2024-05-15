import { ethers, tenderly } from "hardhat";
// import { REGISTRY_SEPOLIA_ADDRESS } from "./constants";
// import { verifyContract } from "./verify";
import { PromiseOrValue } from "../typechain-types/common";

async function main() {
  const [signer] = await ethers.getSigners();

  const DEFAULT_ADMIN = "0xEa770D20e3bD5fB576776D0797926cA11B44CeCD";
  const VRF_WRAPPER = "0x14632CD5c12eC5875D41350B55e825c54406BaaB";
  const LINK_TOKEN = "0xf97f4df75117a78c1A5a0DBb814Af92458539FB4";
  
  const lotteryDeployerLibrary = await (await ethers.getContractFactory("LotteryDeployerLibrary")).deploy();
  const redemptionDeployerLibrary = await (await ethers.getContractFactory("RedemptionDeployerLibrary")).deploy();
  const organizationDeployerLibrary = await (await ethers.getContractFactory("OrganizationDeployerLibrary")).deploy();
  const campaignDeployerLibrary = await (await ethers.getContractFactory("CampaignDeployerLibrary")).deploy();
  const ticketDeployerLibrary = await (await ethers.getContractFactory("TicketDeployerLibrary")).deploy();
  const libraries = {
    LotteryDeployerLibrary: lotteryDeployerLibrary.address,
    RedemptionDeployerLibrary: redemptionDeployerLibrary.address,
    OrganizationDeployerLibrary: organizationDeployerLibrary.address,
    CampaignDeployerLibrary: campaignDeployerLibrary.address,
    TicketDeployerLibrary: ticketDeployerLibrary.address
  }

  const KarrotFactory = await ethers.getContractFactory("KarrotFactory", { signer, libraries });
  const TicketMinterFactory =  await ethers.getContractFactory("TicketMinter", signer);
  const RandomGetterFactory =  await ethers.getContractFactory("RandomGetter", signer); 

  async function deployKarrotFactory() {
    try {
      const karrotFactory = await KarrotFactory.deploy(DEFAULT_ADMIN);
      await karrotFactory.deployed();
      return karrotFactory.address;
    } catch (error) {
      console.error(error);
      return deployKarrotFactory();
    }
  }

  async function deployTicketMinter(karrotFactoryAddress: PromiseOrValue<string>) {
    try {
      const ticketMinter = await TicketMinterFactory.deploy(DEFAULT_ADMIN, DEFAULT_ADMIN, karrotFactoryAddress);
      await ticketMinter.deployed();
      return ticketMinter.address;
    } catch (error) {
      console.error(error);
      return deployTicketMinter(karrotFactoryAddress);
    }
  }

  async function deployRandomGetter(karrotFactoryAddress: PromiseOrValue<string>) {
    try {
      const randomGetter = await RandomGetterFactory.deploy(LINK_TOKEN, VRF_WRAPPER, karrotFactoryAddress, DEFAULT_ADMIN);
      await randomGetter.deployed();
      return randomGetter.address;
    } catch (error) {
      console.error(error);
      return deployRandomGetter(karrotFactoryAddress);
    }
  }


  async function deployAll() {
    const karrotFactoryAddress = await deployKarrotFactory();
    const ticketMinterAddress = await deployTicketMinter(karrotFactoryAddress);
    const randomGetterAddress = await deployRandomGetter(karrotFactoryAddress);

    await tenderly.verify(
      {
        name: "KarrotFactory",
        address: karrotFactoryAddress,
      },
      {
        name: "TicketMinter",
        address: ticketMinterAddress,
      },
      {
        name: "RandomGetter",
        address: randomGetterAddress,
      }
    );
  }

  deployAll();

}

main().catch((error) => {
  console.error("or this", error);
});
