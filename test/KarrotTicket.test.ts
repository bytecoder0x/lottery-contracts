import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { KarrotFactory, TicketMinter, KarrotOrganization, KarrotTicket, KarrotCampaign } from "../typechain-types";
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
    let campaign: KarrotCampaign;
    let minterRole: string;

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
        campaign = await ethers.getContractAt("KarrotCampaign", campaignsAddresses[0]);
        organization = await ethers.getContractAt("KarrotOrganization", organizationAddress);
        minterRole = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("MINTER"));

    });

    describe("Minting", function () {

        it("Should mint a ticket to the campaign", async function () {
            const karrotTicket = await (await ethers.getContractFactory("KarrotTicket")).deploy(owner.address, minter.address, campaign.address, "Test KarrotTicket");
            await organization.grantRole(minterRole, minter.address);
            await organization.connect(minter).mintTo(owner.address, []);
            await campaign.grantRole(minterRole, minter.address);
            const ownerOrganizationNft = await organization.ownerToken(owner.address);
            await campaign.connect(minter).mintToOrganization(ownerOrganizationNft, []);

            const pendingChildren = await organization.pendingChildrenOf(ownerOrganizationNft);
            const childToAccept = pendingChildren[0];
            const childIndex = 0;
            await organization.connect(owner).acceptChild(
                ownerOrganizationNft,
                childIndex,
                childToAccept.contractAddress,
                childToAccept.tokenId
            );
            const campaignId = await organization.childrenOf(ownerOrganizationNft);

            await karrotTicket.connect(minter).mintToCampaign(
                campaignId[0].tokenId,
                [],
            );
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
            for (let i = 1; i < ticketCount; i++) {
                expect(await karrotTicket.ownerOf(i)).to.be.eq(owner.address);
            }
            expect(await karrotTicket.balanceOf(campaign.address)).to.be.eq(ticketCount);

        });

        it("Can't mint after mint deadline", async function () {
            const karrotTicket = await (await ethers.getContractFactory("KarrotTicket")).deploy(owner.address, minter.address, campaign.address, "Test KarrotTicket");
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
            const ticketsCount = 10;

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
            const karrotTicket = await (await ethers.getContractFactory("KarrotTicket")).deploy(owner.address, minter.address, campaign.address, "Test KarrotTicket");
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
            expect(await karrotTicket.balanceOf(campaign.address)).to.be.eq(1);
            const ticketToBurn = 1;
            await karrotTicket.connect(user1).burnTicket(ticketToBurn);
            expect(await karrotTicket.balanceOf(campaign.address)).to.be.eq(0);
        });

        it("Should burn tickets", async function () {
            const karrotTicket = await (await ethers.getContractFactory("KarrotTicket")).deploy(owner.address, minter.address, campaign.address, "Test KarrotTicket");
            await organization.grantRole(minterRole, minter.address);
            await organization.connect(minter).mintTo(user1.address, []);
            await organization.connect(minter).mintTo(user2.address, []);

            await campaign.grantRole(minterRole, minter.address);
            const ownerOrganizationNft1 = await organization.ownerToken(user1.address);
            const ownerOrganizationNft2 = await organization.ownerToken(user2.address);

            await campaign.connect(minter).mintToOrganization(ownerOrganizationNft1, []);
            await campaign.connect(minter).mintToOrganization(ownerOrganizationNft2, []);

            const pendingChildren = await organization.pendingChildrenOf(ownerOrganizationNft1);
            const childToAccept = pendingChildren[0];
            const childIndex = 0;
            await organization.connect(user1).acceptChild(
                ownerOrganizationNft1,
                childIndex,
                childToAccept.contractAddress,
                childToAccept.tokenId
            );
            let campaignId = await organization.childrenOf(ownerOrganizationNft1);

            await karrotTicket.connect(minter).mintToCampaignBatch(
                5,
                campaignId[0].tokenId,
                [],
            );
            const pendingChildren2 = await organization.pendingChildrenOf(ownerOrganizationNft2);
            const childToAccept2 = pendingChildren2[0];
            const childIndex2 = 0;
            await organization.connect(user2).acceptChild(
                ownerOrganizationNft2,
                childIndex2,
                childToAccept2.contractAddress,
                childToAccept2.tokenId
            );
            let campaignId2 = await organization.childrenOf(ownerOrganizationNft2);

            await karrotTicket.connect(minter).mintToCampaignBatch(
                3,
                campaignId2[0].tokenId,
                [],
            );

            let pendingChildrenTickets1 = await campaign.pendingChildrenOf(campaignId[0].tokenId);
            let i = 0;
            while (i < pendingChildrenTickets1.length) {
                const childToAcceptTicket1 = pendingChildrenTickets1[i];
                await campaign.connect(user1).acceptChild(
                    campaignId[0].tokenId,
                    i,
                    childToAcceptTicket1.contractAddress,
                    childToAcceptTicket1.tokenId
                );

                pendingChildrenTickets1 = await campaign.pendingChildrenOf(campaignId[0].tokenId);
            }
            let pendingChildrenTickets2 = await campaign.pendingChildrenOf(campaignId2[0].tokenId);
            i = 0;
            while (i < pendingChildrenTickets2.length) {
                const childToAcceptTicket2 = pendingChildrenTickets2[i];
                await campaign.connect(user2).acceptChild(
                    campaignId2[0].tokenId,
                    i,
                    childToAcceptTicket2.contractAddress,
                    childToAcceptTicket2.tokenId
                );
                pendingChildrenTickets2 = await campaign.pendingChildrenOf(campaignId2[0].tokenId);
            }


            let ticketId1 = await campaign.childrenOf(campaignId[0].tokenId);
            let ticketId2 = await campaign.childrenOf(campaignId2[0].tokenId);
            expect(ticketId1.length).to.be.eq(5);
            expect(ticketId2.length).to.be.eq(3);


            expect(await karrotTicket.balanceOf(campaign.address)).to.be.eq(8);
            const ticketsToBurn: number[] = [1, 2, 3];
            await karrotTicket.connect(user1).burnBatch(ticketsToBurn);
            await expect(karrotTicket.connect(user1).burnTicket(3)).to.be.revertedWith("ERC721NotApprovedOrOwner");

            ticketId1 = await campaign.childrenOf(campaignId[0].tokenId);
            ticketId2 = await campaign.childrenOf(campaignId2[0].tokenId);

            expect(ticketId1.length).to.be.eq(2);
            expect(ticketId2.length).to.be.eq(3);

            expect(await karrotTicket.balanceOf(campaign.address)).to.be.eq(5);
        });
    });

    it("Should not allow to deploy with wrong factory", async function () {
        const [owner, minter] = await ethers.getSigners();
        const organization = await (await ethers.getContractFactory("KarrotOrganization")).deploy(owner.address, minter.address, "Test Organization");

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
