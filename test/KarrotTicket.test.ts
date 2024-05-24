import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { KarrotFactory, TicketMinter, KarrotOrganization, KarrotTicket, KarrotCampaign, KarrotPassport } from "../typechain-types";
import { ethers } from "hardhat";
import { assert, expect } from "chai";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { deployBasicContracts } from "./utis";
import { BigNumber } from "ethers";

describe("KarrotTicket", async () => {
    let ticket: KarrotTicket;
    let karrotFactory: KarrotFactory;
    let ticketMinter: TicketMinter;
    let passportAddress: string;
    let organizationAddress: string;
    let campaignsAddresses: string[];
    let owner: SignerWithAddress, minter: SignerWithAddress, user1: SignerWithAddress, user2: SignerWithAddress;
    let passport: KarrotPassport;
    let organization: KarrotOrganization;
    let campaign: KarrotCampaign;
    let minterRole: string;

    async function mintPassportAndOrganizationAndCampaign(user: SignerWithAddress) {
        await passport.grantRole(minterRole, minter.address);
        await passport.connect(minter).mintTo(user.address, []);
        await organization.grantRole(minterRole, minter.address);
        const ownerPassportNft = await passport.ownerToken(user.address);
        await organization.connect(minter).mintToPassport(ownerPassportNft, []);
        await campaign.grantRole(minterRole, minter.address);
        const ownerOrganizationNft = await organization.ownerToken(ownerPassportNft);
        await campaign.connect(minter).mintToOrganization(ownerOrganizationNft, []);

        const pendingChildren = await organization.pendingChildrenOf(ownerOrganizationNft);
        const childToAccept = pendingChildren[0];
        const childIndex = 0;
        await organization.connect(user).acceptChild(
            ownerOrganizationNft,
            childIndex,
            childToAccept.contractAddress,
            childToAccept.tokenId
        );
        const campaignId = await organization.childrenOf(ownerOrganizationNft);
        return campaignId[0].tokenId;
    }

    beforeEach("Init test environment", async () => {
        const fixture = await loadFixture(deployBasicContracts);
        karrotFactory = fixture.karrotFactory;
        ticketMinter = fixture.ticketMinter;
        owner = fixture.owner;
        minter = fixture.minter;
        passportAddress = fixture.passportAddress;
        organizationAddress = fixture.organizationAddress;
        campaignsAddresses = fixture.campaignsAddresses;
        user1 = fixture.user1;
        user2 = fixture.user2;
        passport = await ethers.getContractAt("KarrotPassport", passportAddress);
        organization = await ethers.getContractAt("KarrotOrganization", organizationAddress);
        campaign = await ethers.getContractAt("KarrotCampaign", campaignsAddresses[0]);
        minterRole = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("MINTER"));
    });

    describe("Minting", function () {
        it("Should mint a ticket to the campaign", async function () {
            const karrotTicket = await (await ethers.getContractFactory("KarrotTicket")).deploy(owner.address, minter.address, campaign.address, "Test KarrotTicket");
            const campaignId = await mintPassportAndOrganizationAndCampaign(user1);

            await karrotTicket.connect(minter).mintToCampaign(campaignId, []);
            expect(await karrotTicket.balanceOf(campaign.address)).to.be.eq(1);
        });

        it("Should prevents non-minter from minting tokens", async function () {
            const karrotTicket = await (await ethers.getContractFactory("KarrotTicket")).deploy(owner.address, minter.address, campaign.address, "Test KarrotTicket");
            await expect(karrotTicket.connect(user2).mintToCampaign(1, []))
                .to.be.revertedWith("AccessControl: account " + user2.address.toLowerCase() + " is missing role " + minterRole);
        });

        it("Should prevents non-minter from minting batch of tokens", async function () {
            const karrotTicket = await (await ethers.getContractFactory("KarrotTicket")).deploy(owner.address, minter.address, campaign.address, "Test KarrotTicket");
            await expect(karrotTicket.connect(user2).mintToCampaignBatch(5, 1, []))
                .to.be.revertedWith("AccessControl: account " + user2.address.toLowerCase() + " is missing role " + minterRole);
        });

        it("Should mint a batch of tickets to the campaign", async function () {
            const karrotTicket = await (await ethers.getContractFactory("KarrotTicket")).deploy(owner.address, minter.address, campaign.address, "Test KarrotTicket");
            const campaignId = await mintPassportAndOrganizationAndCampaign(user1);

            const ticketCount = 10;
            await karrotTicket.connect(minter).mintToCampaignBatch(ticketCount, campaignId, []);
            for (let i = 1; i < ticketCount; i++) {
                expect(await karrotTicket.ownerOf(i)).to.be.eq(user1.address);
            }
            expect(await karrotTicket.balanceOf(campaign.address)).to.be.eq(ticketCount);

        });

        it("Can't mint after mint deadline", async function () {
            const karrotTicket = await (await ethers.getContractFactory("KarrotTicket")).deploy(owner.address, minter.address, campaign.address, "Test KarrotTicket");
            const campaignId = await mintPassportAndOrganizationAndCampaign(user1)
            await ethers.provider.send("evm_increaseTime", [2000])

            await expect(karrotTicket.connect(minter).mintToCampaign(
                campaignId,
                [],
            )).to.be.revertedWith("MintTimeEnded");
            const ticketsCount = 10;

            await expect(karrotTicket.connect(minter).mintToCampaignBatch(
                ticketsCount,
                campaignId,
                [],
            )).to.be.revertedWith("MintTimeEnded");
        });

    });

    describe("Burning", function () {

        it("Should burn ticket", async function () {
            const karrotTicket = await (await ethers.getContractFactory("KarrotTicket")).deploy(owner.address, minter.address, campaign.address, "Test KarrotTicket");
            await campaign.setTicketContract(karrotTicket.address);
            const campaignId = await mintPassportAndOrganizationAndCampaign(user1);

            await karrotTicket.connect(minter).mintToCampaign(campaignId, []);

            expect(await karrotTicket.balanceOf(campaign.address)).to.be.eq(1);
            let pendingChildrenTickets1 = await campaign.pendingChildrenOf(campaignId);
            const childToAcceptTicket1 = pendingChildrenTickets1[0];
            await campaign.connect(user1).acceptChild(
                campaignId,
                0,
                childToAcceptTicket1.contractAddress,
                childToAcceptTicket1.tokenId
            );
            let children = await campaign.childrenOf(campaignId);
            expect(children.length).to.be.eq(1);
            await campaign.connect(user1)["burnTicket()"]();
            children = await campaign.childrenOf(campaignId);
            expect(children.length).to.be.eq(0);
            expect(await karrotTicket.balanceOf(campaign.address)).to.be.eq(0);
        });

        async function mintTickets(karrotTicket: KarrotTicket, user: SignerWithAddress, numberTicketsToMint: number) {
            const userCampaignId = await mintPassportAndOrganizationAndCampaign(user)

            await karrotTicket.connect(minter).mintToCampaignBatch(
                numberTicketsToMint,
                userCampaignId,
                [],
            );

            const pendingTickets = await campaign.pendingChildrenOf(userCampaignId);
            for (let i = pendingTickets.length - 1; i >= 0; i--) {
                const ticketToAccept = pendingTickets[i];
                await campaign.connect(user).acceptChild(
                    userCampaignId,
                    i,
                    ticketToAccept.contractAddress,
                    ticketToAccept.tokenId
                );
            }

            const ticketIds = await campaign.childrenOf(userCampaignId);
            return {
                ticketIds: ticketIds.map(ticketId => ticketId.tokenId),
                userCampaignId: userCampaignId
            };
        }

        async function checkTicketOwnership(karrotTicket: KarrotTicket, userTicketIds: BigNumber[], userCampaignId: BigNumber, owner: SignerWithAddress) {
            for (let i = 0; i < userTicketIds.length; i++) {
                const ticketId = userTicketIds[i];
                const ticketDirectOwner = await karrotTicket.directOwnerOf(ticketId);
                expect(ticketDirectOwner.parentId).to.be.eq(userCampaignId);
                expect(await karrotTicket.ownerOf(ticketId)).to.be.eq(owner.address);
            }
        }

        it("Should burn ticket", async function () {
            const karrotTicket = await (await ethers.getContractFactory("KarrotTicket")).deploy(owner.address, minter.address, campaign.address, "Test KarrotTicket");
            await campaign.setTicketContract(karrotTicket.address);

            let user1Data = await mintTickets(karrotTicket, user1, 2);
            const ticketIds = await karrotTicket.getUserTicketIds(user1.address);

            expect(user1Data.ticketIds.length).to.be.eq(ticketIds.length);
            expect(user1Data.ticketIds.length).to.be.eq(2);
            
            expect(await karrotTicket.balanceOf(campaign.address)).to.be.eq(2);
            await campaign.connect(user1)["burnTicket()"]();

            const user1NewTicketIdsData = await campaign.childrenOf(user1Data.userCampaignId);
            const user1NewTicketIds = user1NewTicketIdsData.map(ticketId => ticketId.tokenId);
            expect(user1NewTicketIds.length).to.be.eq(1);
            await checkTicketOwnership(karrotTicket, user1NewTicketIds, user1Data.userCampaignId, user1);

            expect(await karrotTicket.balanceOf(campaign.address)).to.be.eq(1);
        });

        it("Should not allow to burn tickets in KarrotTicket contract", async function () {
            const karrotTicket = await (await ethers.getContractFactory("KarrotTicket")).deploy(owner.address, minter.address, campaign.address, "Test KarrotTicket");
            await mintPassportAndOrganizationAndCampaign(user1);

            await expect(karrotTicket.connect(user1).burnLastTicket()).to.be.revertedWith("Only Campaign can burn tickets");
        });
        

        it("Should correctly burn last ticket", async function () {
            const lotteryAddress = await karrotFactory.lotteries(0) 
            const karrotCampaignMock = await (await ethers.getContractFactory("KarrotCampaignMock")).deploy(
                owner.address,
                minter.address,
                lotteryAddress,
                "Test KarrotCampaignMock");
            const karrotTicket = await (await ethers.getContractFactory("KarrotTicket")).deploy(
                owner.address,
                minter.address,
                karrotCampaignMock.address,
                "Test KarrotTicket");
            await karrotCampaignMock.setTicketContract(karrotTicket.address);
            await karrotCampaignMock.mintTo(user1.address);
            await karrotTicket.connect(minter).mintToCampaignBatch(2, 1, []);
            await karrotCampaignMock.connect(user1).acceptChild(1, 0, karrotTicket.address, 1);
            await karrotCampaignMock.connect(user1).acceptChild(1, 0, karrotTicket.address, 2);
            
            expect(await karrotTicket.balanceOf(karrotCampaignMock.address)).to.be.eq(2);
            expect(await karrotTicket.totalSupply()).to.be.eq(2);
            await karrotCampaignMock.burnTicket();
            expect(await karrotTicket.balanceOf(karrotCampaignMock.address)).to.be.eq(1);
            expect(await karrotTicket.totalSupply()).to.be.eq(1);
            await karrotCampaignMock.burnTicket();
            expect(await karrotTicket.balanceOf(karrotCampaignMock.address)).to.be.eq(0);
            expect(await karrotTicket.totalSupply()).to.be.eq(0);
        });
    });

    it("Should not allow to deploy with wrong factory", async function () {
        const [owner, minter] = await ethers.getSigners();
        const organization = await (await ethers.getContractFactory("KarrotOrganization")).deploy(owner.address, minter.address, passportAddress, "Test Organization");

        await expect((await ethers.getContractFactory("KarrotTicket")).deploy(owner.address, minter.address, organization.address, "Test KarrotTicket"))
            .to.be.revertedWith("InterfaceNotSupported");
    });

    it("Should support AccessControl interface", async function () {
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
