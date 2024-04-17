import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { KarrotFactory, TicketMinter, KarrotOrganization, RewardTokenMintableMock } from "../typechain-types";
import { ethers, network } from "hardhat";
import { expect } from "chai";
import { deployBasicContracts } from "./utis";

describe("KarrotFactory", async () => {
    let hardhatSnapshotId: string;
    let karrotFactory: KarrotFactory
    let ticketMinter: TicketMinter;
    let organizationAddress: string;
    let campaignsAddresses: string[];
    let owner: SignerWithAddress, minter: SignerWithAddress, user1: SignerWithAddress, user2: SignerWithAddress;
    let organization: KarrotOrganization;
    let rewardTokenMintableMock: RewardTokenMintableMock;
    let lotteryAddress: string;
    before(async function () {
        hardhatSnapshotId = await network.provider.send('evm_snapshot')
    });

    beforeEach("Init test environment", async () => {
        const fixture = await loadFixture(deployBasicContracts);
        karrotFactory = fixture.karrotFactory;
        owner = fixture.owner;
        minter = fixture.minter;
        organizationAddress = fixture.organizationAddress;
        campaignsAddresses = fixture.campaignsAddresses;
        user1 = fixture.user1;
        user2 = fixture.user2;
        ticketMinter = fixture.ticketMinter;
        lotteryAddress = fixture.lotteryAddress;
    });

    it("Should deploy organization", async function () {
        expect((await (karrotFactory.getAllOrganizations())).length).to.be.eq(1);
        await karrotFactory.connect(owner).deployOrganizationContract(owner.address, "Test Organization");
        expect((await (karrotFactory.getAllOrganizations())).length).to.be.eq(2);
        expect((await karrotFactory.getAllLotteries()).length).to.be.eq(1);
    });

    it("Should deploy Campaign And Ticket Contracts", async function () {
        const allCampaigns = await karrotFactory.getAllCampaigns();
        const allTickets = await karrotFactory.getAllTickets()

        await karrotFactory.connect(owner).deployCampaignAndTicketContract(owner.address, lotteryAddress, organizationAddress, "Test Campaign");
        const newValueofAllCampaigns = await karrotFactory.getAllCampaigns();
        const newValueofAllTickets = await karrotFactory.getAllTickets();

        expect(newValueofAllCampaigns.length).to.be.eq(allCampaigns.length + 1);
        expect(newValueofAllTickets.length).to.be.eq(allTickets.length + 1);

    });

    it("Should not allow to deploy Campaign And Ticket Contracts with invalid values", async function () {

        await expect(karrotFactory.connect(owner).deployCampaignAndTicketContract(owner.address, lotteryAddress, lotteryAddress, "Test Campaign")).to.be.revertedWith("Not valid organization contract");
        await expect(karrotFactory.connect(owner).deployCampaignAndTicketContract(owner.address, organizationAddress, organizationAddress, "Test Campaign")).to.be.revertedWith("Not valid lottery contract");
        await expect(karrotFactory.connect(owner).deployCampaignAndTicketContract(owner.address, lotteryAddress, organizationAddress, "")).to.be.revertedWith("Campaign name is empty");

        await ethers.provider.send("evm_increaseTime", [2000]);
        await expect(karrotFactory.connect(owner).deployCampaignAndTicketContract(owner.address, lotteryAddress, organizationAddress, "Test Campaign")).to.be.revertedWith("Mint deadline is in the past");

    });

    it("Should test all functions with 'onlyRole' modifier with negative scenario", async function () {
        const DEFAULT_ADMIN_ROLE = ethers.constants.AddressZero;
        await expect(karrotFactory.connect(user1).setMinterContract(ticketMinter.address)).to.be.revertedWith("AccessControl: account " + user1.address.toLowerCase() + " is missing role " + DEFAULT_ADMIN_ROLE);
        await expect(karrotFactory.connect(owner).setMinterContract(organizationAddress)).to.be.revertedWith("InterfaceNotSupported");

        const currentTime = Math.floor(Date.now() / 1000);
        const mintDeadline = currentTime + 86400;
        const burnDeadline = currentTime + 172800;
        const lotteryTime = currentTime + 259200;

        const deployerRole = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("DEPLOYER"));
        await expect(karrotFactory.connect(user1).deployLotteryContract(owner.address, mintDeadline, burnDeadline, lotteryTime)).to.be.revertedWith("AccessControl: account " + user1.address.toLowerCase() + " is missing role " + deployerRole);
        await expect(karrotFactory.connect(user1).deployOrganizationContract(owner.address, "Test Organization")).to.be.revertedWith("AccessControl: account " + user1.address.toLowerCase() + " is missing role " + deployerRole);
        await expect(karrotFactory.connect(user1).deployCampaignAndTicketContract(owner.address, lotteryAddress, organizationAddress, "Test Campaign")).to.be.revertedWith("AccessControl: account " + user1.address.toLowerCase() + " is missing role " + deployerRole);
        await expect(karrotFactory.connect(user1).deployOrganizationAndCampaigns(owner.address, lotteryAddress, "Test Organization", ["Test Campaign"])).to.be.revertedWith("AccessControl: account " + user1.address.toLowerCase() + " is missing role " + deployerRole);

    });

    it("Should test all functions with 'withSetupMinterContract' modifier with negative scenario", async function () {
        const organizationDeployerLibrary = await (await ethers.getContractFactory("OrganizationDeployerLibrary")).deploy();
        const campaignDeployerLibrary = await (await ethers.getContractFactory("CampaignDeployerLibrary")).deploy();
        const ticketDeployerLibrary = await (await ethers.getContractFactory("TicketDeployerLibrary")).deploy();
        const karrotFactory1 = await (await ethers.getContractFactory("KarrotFactory", {
            libraries: {
                OrganizationDeployerLibrary: organizationDeployerLibrary.address,
                CampaignDeployerLibrary: campaignDeployerLibrary.address,
                TicketDeployerLibrary: ticketDeployerLibrary.address
            }
        })).deploy(owner.address);
        const currentTime = Math.floor(Date.now() / 1000);
        const mintDeadline = currentTime + 86400;
        const burnDeadline = currentTime + 172800;
        const lotteryTime = currentTime + 259200;

        await expect(karrotFactory1.connect(owner).deployLotteryContract(owner.address, mintDeadline, burnDeadline, lotteryTime)).to.be.revertedWith("Minter contract not set");
        await expect(karrotFactory1.connect(owner).deployOrganizationContract(owner.address, "Test Organization")).to.be.revertedWith("Minter contract not set");
        await expect(karrotFactory1.connect(owner).deployCampaignAndTicketContract(owner.address, lotteryAddress, organizationAddress, "Test Campaign")).to.be.revertedWith("Minter contract not set");
        await expect(karrotFactory1.connect(owner).deployOrganizationAndCampaigns(owner.address, lotteryAddress, "Test Organization", ["Test Campaign"])).to.be.revertedWith("Minter contract not set");
    });

    it("Should support AccessControl interface", async function () {
        let functionSignature = [
            'hasRole(bytes32,address)',
            'getRoleAdmin(bytes32)',
            'grantRole(bytes32,address)',
            'revokeRole(bytes32,address)',
            'renounceRole(bytes32,address)'
        ];
        let interfaceID = BigInt(0);

        for (const signature of functionSignature) {
            const selector = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(signature)).slice(2, 10);
            interfaceID ^= BigInt('0x' + selector);
        }

        const interfaceIDHex = '0x' + interfaceID.toString(16).padStart(8, '0');
        expect(await karrotFactory.supportsInterface(interfaceIDHex)).to.equal(true);
    });
});