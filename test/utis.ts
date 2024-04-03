import { ethers } from "hardhat";

export async function deployFactoryAndMinter() {
    const [owner, minter, user1, user2] = await ethers.getSigners();

    const organizationDeployerLibrary = await (await ethers.getContractFactory("OrganizationDeployerLibrary")).deploy();
    const campaignDeployerLibrary = await (await ethers.getContractFactory("CampaignDeployerLibrary")).deploy();
    const ticketDeployerLibrary = await (await ethers.getContractFactory("TicketDeployerLibrary")).deploy();
    const karrotFactory = await (await ethers.getContractFactory("KarrotFactory", {
        libraries: {
            OrganizationDeployerLibrary: organizationDeployerLibrary.address,
            CampaignDeployerLibrary: campaignDeployerLibrary.address,
            TicketDeployerLibrary: ticketDeployerLibrary.address
        }
    })).deploy(owner.address);
    const ticketMinter = await (await ethers.getContractFactory("TicketMinter")).deploy(owner.address, minter.address, karrotFactory.address);
    await karrotFactory.setMinterContract(ticketMinter.address);

    return { karrotFactory, ticketMinter, owner, minter, user1, user2 };
}

export async function deployBasicContracts() {
    const { karrotFactory, ticketMinter, owner, minter, user1, user2 } = await deployFactoryAndMinter();

    await karrotFactory.deployLotteryContract(
        owner.address,
        +(((new Date().getTime()) / 1000).toFixed(0)) + 1000,
        +(((new Date().getTime()) / 1000).toFixed(0)) + 2000,
        +(((new Date().getTime()) / 1000).toFixed(0)) + 3000,
    );
    const lotteryAddress = await karrotFactory.lotteries(0);

    await karrotFactory.deployOrganizationAndCampaigns(
        owner.address,
        lotteryAddress,
        "Test Organization 1",
        ["Campaign 1", "Campaign 1"]
    );
    const organizationAddress = await karrotFactory.organizations(0);
    const campaignsAddresses = await karrotFactory.getAllCampaigns();

    return { karrotFactory, ticketMinter, organizationAddress, campaignsAddresses, lotteryAddress, owner, minter, user1, user2 };
}