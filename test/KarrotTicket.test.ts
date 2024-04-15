import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { KarrotFactory, TicketMinter, KarrotOrganization, KarrotTicket, KarrotTicket__factory } from "../typechain-types";
import { ethers } from "hardhat";
import { assert, expect } from "chai";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { deployBasicContracts } from "./utis";

describe("KarrotTicket", async () => {
    let ticket: KarrotTicket;
    let karrotFactory: KarrotFactory
    let ticketMinter: TicketMinter;
    let organizationAddress: string;
    let campaignsAddresses: string[];
    let owner: SignerWithAddress, minter: SignerWithAddress, user1: SignerWithAddress, user2: SignerWithAddress;
    let organization: KarrotOrganization;


    beforeEach("Init test environment", async () => {
        const fixture = await loadFixture(deployBasicContracts);
        karrotFactory = fixture.karrotFactory;
        ticketMinter = fixture.ticketMinter;
        owner = fixture.owner;
        minter = fixture.minter;
        organizationAddress = fixture.organizationAddress;
        campaignsAddresses = fixture.campaignsAddresses;
        user1 = fixture.user1;
        user2 = fixture.user2;

    });

    describe("Minting", function () {

        it("Should mint a ticket to the campaign", async function () {
            const campaign = await ethers.getContractAt("KarrotCampaign", campaignsAddresses[0]);
            const karrotTicket = await (await ethers.getContractFactory("KarrotTicket")).deploy(owner.address, minter.address, campaign.address, "Test KarrotTicket");
            const organization = await ethers.getContractAt("KarrotOrganization", organizationAddress);
            const minterRole = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("MINTER"));
            await organization.grantRole(minterRole, minter.address);
            await organization.connect(minter).mintTo(owner.address, []);
            await campaign.grantRole(minterRole, minter.address);
            const ownerOrganizationNft = await organization.ownerToken(owner.address);
            await campaign.connect(minter).mintToOrganization(ownerOrganizationNft, []);

            await karrotTicket.connect(minter).mintToCampaign(
                1,
                [],
            );
            expect(await karrotTicket.ownerOf(1)).to.be.eq(owner.address);
        });

        it("Should prevents non-minter from minting tokens", async function () {
            const campaign = await ethers.getContractAt("KarrotCampaign", campaignsAddresses[0]);
            const karrotTicket = await (await ethers.getContractFactory("KarrotTicket")).deploy(owner.address, minter.address, campaign.address, "Test KarrotTicket");
            const minterRole = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("MINTER"));
            await expect(karrotTicket.connect(user2).mintToCampaign(1, []))
                .to.be.revertedWith("AccessControl: account " + user2.address.toLowerCase() + " is missing role " + minterRole);
        });

        it("Should prevents non-minter from minting batch of tokens", async function () {
            const campaign = await ethers.getContractAt("KarrotCampaign", campaignsAddresses[0]);
            const karrotTicket = await (await ethers.getContractFactory("KarrotTicket")).deploy(owner.address, minter.address, campaign.address, "Test KarrotTicket");
            const minterRole = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("MINTER"));
            await expect(karrotTicket.connect(user2).mintToCampaignBatch(5, 1, []))
                .to.be.revertedWith("AccessControl: account " + user2.address.toLowerCase() + " is missing role " + minterRole);
        });

        it("Should mint a batch of tickets to the campaign", async function () {
            const campaign = await ethers.getContractAt("KarrotCampaign", campaignsAddresses[0]);
            const karrotTicket = await (await ethers.getContractFactory("KarrotTicket")).deploy(owner.address, minter.address, campaign.address, "Test KarrotTicket");
            const organization = await ethers.getContractAt("KarrotOrganization", organizationAddress);
            const minterRole = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("MINTER"));
            await organization.grantRole(minterRole, minter.address);
            await organization.connect(minter).mintTo(owner.address, []);
            await campaign.grantRole(minterRole, minter.address);
            const ownerOrganizationNft = await organization.ownerToken(owner.address);
            await campaign.connect(minter).mintToOrganization(ownerOrganizationNft, []);
            const ticketCount = 10;
            await karrotTicket.connect(minter).mintToCampaignBatch(
                ticketCount,
                1,
                [],
            );
            expect(await karrotTicket.ownerOf(ticketCount)).to.be.eq(owner.address);
        });

        it("Can't mint after mint deadline", async function () {
            const campaign = await ethers.getContractAt("KarrotCampaign", campaignsAddresses[0]);
            const karrotTicket = await (await ethers.getContractFactory("KarrotTicket")).deploy(owner.address, minter.address, campaign.address, "Test KarrotTicket");
            const organization = await ethers.getContractAt("KarrotOrganization", organizationAddress);
            const minterRole = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("MINTER"));
            await organization.grantRole(minterRole, minter.address);
            await organization.connect(minter).mintTo(user1.address, []);
            await campaign.grantRole(minterRole, minter.address);
            const ownerOrganizationNft = await organization.ownerToken(user1.address);
            await campaign.connect(minter).mintToOrganization(ownerOrganizationNft, []);

            await campaign.connect(minter).mintToOrganization(ownerOrganizationNft, []);
            const user1OrganizationNft = await organization.ownerToken(user1.address);
            await ethers.provider.send("evm_increaseTime", [2000])

            await expect(karrotTicket.connect(minter).mintToCampaign(
                user1OrganizationNft,
                [],
            )).to.be.revertedWith("MintTimeEnded");
            await ethers.provider.send("evm_increaseTime", [-2000])

        });

        it("Can't mint batch after mint deadline", async function () {
            const campaign = await ethers.getContractAt("KarrotCampaign", campaignsAddresses[0]);
            const karrotTicket = await (await ethers.getContractFactory("KarrotTicket")).deploy(owner.address, minter.address, campaign.address, "Test KarrotTicket");
            const organization = await ethers.getContractAt("KarrotOrganization", organizationAddress);
            const minterRole = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("MINTER"));
            await organization.grantRole(minterRole, minter.address);
            await organization.connect(minter).mintTo(user1.address, []);
            await campaign.grantRole(minterRole, minter.address);
            const ownerOrganizationNft = await organization.ownerToken(user1.address);
            await campaign.connect(minter).mintToOrganization(ownerOrganizationNft, []);

            await campaign.connect(minter).mintToOrganization(ownerOrganizationNft, []);
            const user1OrganizationNft = await organization.ownerToken(user1.address);
            const ticketsCount = 10;

            await ethers.provider.send("evm_increaseTime", [2000])
            await expect(karrotTicket.connect(minter).mintToCampaignBatch(
                ticketsCount,
                user1OrganizationNft,
                [],
            )).to.be.revertedWith("MintTimeEnded");
            await ethers.provider.send("evm_increaseTime", [-2000])
        });
    });

    describe("Burning", function () {

        it("Should burn ticket", async function () {
            const campaign = await ethers.getContractAt("KarrotCampaign", campaignsAddresses[0]);
            const karrotTicket = await (await ethers.getContractFactory("KarrotTicket")).deploy(owner.address, minter.address, campaign.address, "Test KarrotTicket");
            const organization = await ethers.getContractAt("KarrotOrganization", organizationAddress);
            const minterRole = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("MINTER"));
            await organization.grantRole(minterRole, minter.address);
            await organization.connect(minter).mintTo(user1.address, []);
            await campaign.grantRole(minterRole, minter.address);
            const ownerOrganizationNft = await organization.ownerToken(user1.address);
            await campaign.connect(minter).mintToOrganization(ownerOrganizationNft, []);

            const user1OrganizationNft = await organization.ownerToken(user1.address);
            await karrotTicket.connect(minter).mintToCampaign(
                user1OrganizationNft,
                [],
            );

            const ticketToBurn = 1;
            await karrotTicket.connect(user1).burnTicket(ticketToBurn);
            await expect(karrotTicket.connect(user1).burnTicket(ticketToBurn)).to.be.revertedWith("ERC721InvalidTokenId");
        });

        it("Should burn tickets", async function () {
            const campaign = await ethers.getContractAt("KarrotCampaign", campaignsAddresses[0]);
            const karrotTicket = await (await ethers.getContractFactory("KarrotTicket")).deploy(owner.address, minter.address, campaign.address, "Test KarrotTicket");
            const organization = await ethers.getContractAt("KarrotOrganization", organizationAddress);
            const minterRole = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("MINTER"));
            await organization.grantRole(minterRole, minter.address);
            await organization.connect(minter).mintTo(user1.address, []);
            await campaign.grantRole(minterRole, minter.address);
            const ownerOrganizationNft = await organization.ownerToken(user1.address);
            await campaign.connect(minter).mintToOrganization(ownerOrganizationNft, []);

            const user1OrganizationNft = await organization.ownerToken(user1.address);
            await karrotTicket.connect(minter).mintToCampaignBatch(
                10,
                user1OrganizationNft,
                [],
            );
            const ticketsToBurn: number[] = [10,9,8,7,6];

            await karrotTicket.connect(user1).burnBatch(ticketsToBurn);
            await expect(karrotTicket.connect(user1).burnTicket(9)).to.be.revertedWith("ERC721InvalidTokenId");
        });
    });

    it("Should not allow to deploy with wrong factory", async function () {
        const [owner, minter] = await ethers.getSigners();
        const organization = await (await ethers.getContractFactory("KarrotOrganization")).deploy(owner.address, minter.address, "Test Organization");

        await expect((await ethers.getContractFactory("KarrotTicket")).deploy(owner.address, minter.address, organization.address, "Test KarrotTicket"))
            .to.be.revertedWith("InterfaceNotSupported");
    });

    it("Should support AccessControl interface", async function () {
        const campaign = await ethers.getContractAt("KarrotCampaign", campaignsAddresses[0]);
        const karrotTicket = await (await ethers.getContractFactory("KarrotTicket")).deploy(owner.address, minter.address, campaign.address, "Test KarrotTicket");
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
        expect(await karrotTicket.supportsInterface(interfaceIDHex)).to.equal(true);
    });
});
