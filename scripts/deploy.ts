import fs from "fs";
import { promisify } from "util";
import { ethers, run } from "hardhat";
import { PromiseOrValue } from "../typechain-types/common";

async function main() {
  const [signer] = await ethers.getSigners();

  const ADMIN = "0xAdminAdress";
  const MINTER = "0xMinterAdress";
  const VRF_WRAPPER = "0x14632CD5c12eC5875D41350B55e825c54406BaaB";
  const LINK_TOKEN = "0xf97f4df75117a78c1A5a0DBb814Af92458539FB4";

  const lotteryDeployerLibrary = await (await ethers.getContractFactory("LotteryDeployerLibrary")).deploy();
  await lotteryDeployerLibrary.deployed();
  const redemptionDeployerLibrary = await (await ethers.getContractFactory("RedemptionDeployerLibrary")).deploy();
  await redemptionDeployerLibrary.deployed();
  const organizationDeployerLibrary = await (await ethers.getContractFactory("OrganizationDeployerLibrary")).deploy();
  await organizationDeployerLibrary.deployed();
  const campaignDeployerLibrary = await (await ethers.getContractFactory("CampaignDeployerLibrary")).deploy();
  await campaignDeployerLibrary.deployed();
  const ticketDeployerLibrary = await (await ethers.getContractFactory("TicketDeployerLibrary")).deploy();
  await ticketDeployerLibrary.deployed();

  const libraries = {
    LotteryDeployerLibrary: lotteryDeployerLibrary.address,
    RedemptionDeployerLibrary: redemptionDeployerLibrary.address,
    OrganizationDeployerLibrary: organizationDeployerLibrary.address,
    CampaignDeployerLibrary: campaignDeployerLibrary.address,
    TicketDeployerLibrary: ticketDeployerLibrary.address,
  };

  const KarrotFactory = await ethers.getContractFactory("KarrotFactory", { signer, libraries });
  const KarrotPassport = await ethers.getContractFactory("KarrotPassport", signer);
  const TicketMinterFactory = await ethers.getContractFactory("TicketMinter", signer);
  const RandomGetterFactory = await ethers.getContractFactory("RandomGetter", signer);

  async function verifyContract(address: string, constructorArguments: any[]) {
    try {
      await run("verify:verify", {
        address,
        constructorArguments,
      });
    } catch (error) {
      console.error(`Verification failed for ${address}:`, error);
    }
  }

  async function deployKarrotFactory() {
    try {
      const karrotFactory = await KarrotFactory.deploy(ADMIN);
      await karrotFactory.deployed();
      await verifyContract(karrotFactory.address, [ADMIN]);
      return karrotFactory.address;
    } catch (error) {
      console.error(error);
      return deployKarrotFactory();
    }
  }

  async function deployKarrotPassport(ticketMinterAddress: PromiseOrValue<string>) {
    try {
      const karrotPassport = await KarrotPassport.deploy(ADMIN, ticketMinterAddress, "Karrot Passport");
      await karrotPassport.deployed();
      await verifyContract(karrotPassport.address, [ADMIN, ticketMinterAddress, "Karrot Passport"]);
      return karrotPassport.address;
    } catch (error) {
      console.error(error);
      return deployKarrotPassport(ticketMinterAddress);
    }
  }

  async function deployTicketMinter(karrotFactoryAddress: PromiseOrValue<string>) {
    try {
      const ticketMinter = await TicketMinterFactory.deploy(ADMIN, MINTER, karrotFactoryAddress);
      await ticketMinter.deployed();
      await verifyContract(ticketMinter.address, [ADMIN, MINTER, karrotFactoryAddress]);
      return ticketMinter.address;
    } catch (error) {
      console.error(error);
      return deployTicketMinter(karrotFactoryAddress);
    }
  }

  async function deployRandomGetter(karrotFactoryAddress: PromiseOrValue<string>) {
    try {
      const randomGetter = await RandomGetterFactory.deploy(LINK_TOKEN, VRF_WRAPPER, karrotFactoryAddress, ADMIN);
      await randomGetter.deployed();
      await verifyContract(randomGetter.address, [LINK_TOKEN, VRF_WRAPPER, karrotFactoryAddress, ADMIN]);
      return randomGetter.address;
    } catch (error) {
      console.error(error);
      return deployRandomGetter(karrotFactoryAddress);
    }
  }

  async function deployAll() {
    const karrotFactoryAddress = await deployKarrotFactory();
    const ticketMinterAddress = await deployTicketMinter(karrotFactoryAddress);
    const karrotPassportAddress = await deployKarrotPassport(ticketMinterAddress);
    const randomGetterAddress = await deployRandomGetter(karrotFactoryAddress);

    const addresses = {
      karrotFactory: karrotFactoryAddress,
      karrotPassport: karrotPassportAddress,
      ticketMinter: ticketMinterAddress,
      randomGetter: randomGetterAddress,
    };

    const writeFileAsync = promisify(fs.writeFile);
    await writeFileAsync("deployed-addresses.json", JSON.stringify(addresses, null, 2));
  }

  deployAll();
}

main().catch((error) => {
  console.error("or this", error);
});
