import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { KarrotOrganization, KarrotCampaign, KarrotTicket, KarrotPassport } from "../typechain-types";
import { ethers } from "hardhat";
import { assert, expect } from "chai";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { deployBasicContracts } from "./utis";
import { BigNumber } from "ethers";

describe("KarrotCampaign", async () => {
    let passport: KarrotPassport;
    let organization: KarrotOrganization;
    let campaign: KarrotCampaign;
    let owner: SignerWithAddress;
    let minter: SignerWithAddress;
    let user1: SignerWithAddress;
    let user2: SignerWithAddress;
    let passportAddress: string;
    let organizationAddress: string;
    let campaignsAddresses: string[];
    let lotteryAddress: string;

    async function mintPassportsAndOrganizations() {
        const minterRole = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("MINTER"));
        await passport.grantRole(minterRole, minter.address);
        await organization.grantRole(minterRole, minter.address);
        await campaign.grantRole(minterRole, minter.address)
        await passport.connect(minter).mintTo(user1.address, []);
        await passport.connect(minter).mintTo(user2.address, []);
        await organization.connect(minter).mintToPassport(1, []);
        await organization.connect(minter).mintToPassport(2, []);
        const user1PassportId = await passport.ownerToken(user1.address);
        const user2PassportId = await passport.ownerToken(user1.address);
        const user1OrganizationId = await organization.ownerToken(user1PassportId);
        const user2OrganizationId = await organization.ownerToken(user2PassportId);

        return { user1OrganizationId, user2OrganizationId };
    }

    beforeEach("Init test environment", async () => {
        const fixture = await loadFixture(deployBasicContracts);
        owner = fixture.owner;
        minter = fixture.minter;
        user1 = fixture.user1;
        user2 = fixture.user2;
        passportAddress = fixture.passportAddress;
        organizationAddress = fixture.organizationAddress;
        campaignsAddresses = fixture.campaignsAddresses;
        passport = await ethers.getContractAt("KarrotPassport", passportAddress);
        organization = await ethers.getContractAt("KarrotOrganization", organizationAddress);
        campaign = await ethers.getContractAt("KarrotCampaign", campaignsAddresses[0]);
        lotteryAddress = fixture.lotteryAddress;
    });

    it("Should mint campaign token", async function () {
        const { user1OrganizationId } = await mintPassportsAndOrganizations();
        await campaign.connect(minter).mintToOrganization(user1OrganizationId, []);
        const mintedTokenCampaignId = await campaign.getUserCampaignId(user1.address);

        expect(await campaign.balanceOf(organization.address)).to.be.eq(1);
        const directOwner = await campaign.directOwnerOf(mintedTokenCampaignId);
        expect(directOwner.isNFT).to.be.eq(true);
        expect(directOwner.owner_).to.be.eq(organization.address);
        expect(directOwner.parentId).to.be.eq(user1OrganizationId);
    });

    it("Should prevent mint campaign if organization already has this campaign", async function () {
        const { user1OrganizationId } = await mintPassportsAndOrganizations();
        
        await campaign.connect(minter).mintToOrganization(user1OrganizationId, [])
        await expect(campaign.connect(minter).mintToOrganization(user1OrganizationId, [])).to.be.revertedWith("Organization already has this campaign");
    });

    it("Should set ticket contracts", async function () {
        const karrotTicket = await (await ethers.getContractFactory("KarrotTicket")).deploy(owner.address, minter.address, campaign.address, "Test KarrotTicket");
        campaign.connect(owner).setTicketContract(karrotTicket.address)
        expect(await campaign.ticketsContract()).to.be.eq(karrotTicket.address);
    });

    it("Should burn a single ticket", async function () {
        const karrotTicket = await (await ethers.getContractFactory("KarrotTicket")).deploy(owner.address, minter.address, campaign.address, "Test KarrotTicket");

        campaign.connect(owner).setTicketContract(karrotTicket.address);
        await mintPassportsAndOrganizations();

        let user1Data = await mintTickets(karrotTicket, user1, 5);
        expect(await karrotTicket.balanceOf(campaign.address)).to.be.eq(5);
        await campaign.connect(user1)["burnTicket(uint256)"](user1Data.userCampaignId);
        expect(await karrotTicket.balanceOf(campaign.address)).to.be.eq(4);
        await campaign.connect(user1)["burnTicket()"]();
        expect(await karrotTicket.balanceOf(campaign.address)).to.be.eq(3);
    });

    it("Should burn multiple tickets at once", async function () {
        const karrotTicket = await (await ethers.getContractFactory("KarrotTicket")).deploy(owner.address, minter.address, campaign.address, "Test KarrotTicket");
        await campaign.setTicketContract(karrotTicket.address);
        await mintPassportsAndOrganizations();

        let user1Data = await mintTickets(karrotTicket, user1, 5);
        let user2Data = await mintTickets(karrotTicket, user2, 3);
        expect(user1Data.ticketIds.length).to.be.eq(5);
        expect(user2Data.ticketIds.length).to.be.eq(3);

        expect(await karrotTicket.balanceOf(campaign.address)).to.be.eq(8);
        const ticketsToBurn = 3;
        await campaign.connect(user1)["burnTicketBatch(uint256)"](ticketsToBurn);

        const user1NewTicketIdsData = await campaign.childrenOf(user1Data.userCampaignId);
        const user2NewTicketIdsData = await campaign.childrenOf(user2Data.userCampaignId);
        const user1NewTicketIds = user1NewTicketIdsData.map(ticketId => ticketId.tokenId);
        const user2NewTicketIds = user2NewTicketIdsData.map(ticketId => ticketId.tokenId);
        expect(user1NewTicketIds.length).to.be.eq(2);
        expect(user2NewTicketIds.length).to.be.eq(3);
        await checkTicketOwnership(karrotTicket, user1NewTicketIds, user1Data.userCampaignId, user1);
        await checkTicketOwnership(karrotTicket, user2NewTicketIds, user2Data.userCampaignId, user2);

        expect(await karrotTicket.balanceOf(campaign.address)).to.be.eq(5);
    });

    it("Should burn multiple tickets at once", async function () {
        const karrotTicket = await (await ethers.getContractFactory("KarrotTicket")).deploy(owner.address, minter.address, campaign.address, "Test KarrotTicket");
        await campaign.setTicketContract(karrotTicket.address);
        await mintPassportsAndOrganizations();

        let user1Data = await mintTickets(karrotTicket, user1, 5);
        let user2Data = await mintTickets(karrotTicket, user2, 3);
        expect(user1Data.ticketIds.length).to.be.eq(5);
        expect(user2Data.ticketIds.length).to.be.eq(3);

        expect(await karrotTicket.balanceOf(campaign.address)).to.be.eq(8);
        const ticketsToBurn = 3;
        await campaign.connect(user1)["burnTicketBatch(uint256)"](ticketsToBurn);

        const user1NewTicketIdsData = await campaign.childrenOf(user1Data.userCampaignId);
        const user2NewTicketIdsData = await campaign.childrenOf(user2Data.userCampaignId);
        const user1NewTicketIds = user1NewTicketIdsData.map(ticketId => ticketId.tokenId);
        const user2NewTicketIds = user2NewTicketIdsData.map(ticketId => ticketId.tokenId);
        expect(user1NewTicketIds.length).to.be.eq(2);
        expect(user2NewTicketIds.length).to.be.eq(3);
        await checkTicketOwnership(karrotTicket, user1NewTicketIds, user1Data.userCampaignId, user1);
        await checkTicketOwnership(karrotTicket, user2NewTicketIds, user2Data.userCampaignId, user2);

        expect(await karrotTicket.balanceOf(campaign.address)).to.be.eq(5);
    });

    it("Should prevents burn tickets if sender is not owner or aprroved", async function () {
        const karrotTicket = await (await ethers.getContractFactory("KarrotTicket")).deploy(owner.address, minter.address, campaign.address, "Test KarrotTicket");
        await campaign.setTicketContract(karrotTicket.address);
        await mintPassportsAndOrganizations();
        await mintTickets(karrotTicket, user1, 5);
        await mintTickets(karrotTicket, user2, 5);

        await expect(campaign.connect(user2)["burnTicketBatch(uint256,uint256)"](1, 1)).to.be.revertedWith("User is not aprroved or owner");
        await campaign.connect(user1).approve(user2.address, 1)
        expect(await karrotTicket.balanceOf(campaign.address)).to.be.eq(10);
        await campaign.connect(user2)["burnTicketBatch(uint256,uint256)"](1, 1);
        expect(await karrotTicket.balanceOf(campaign.address)).to.be.eq(9);
    })

    it("Should test all burn minor scenarios", async function () {
        const karrotTicket = await (await ethers.getContractFactory("KarrotTicket")).deploy(owner.address, minter.address, campaign.address, "Test KarrotTicket");
        await campaign.setTicketContract(karrotTicket.address);
        await mintPassportsAndOrganizations();

        let user1Data = await mintTickets(karrotTicket, user1, 5);
        let user2Data = await mintTickets(karrotTicket, user2, 3);
        expect(user1Data.ticketIds.length).to.be.eq(5);
        expect(user2Data.ticketIds.length).to.be.eq(3);

        expect(await karrotTicket.balanceOf(campaign.address)).to.be.eq(8);
        const ticketsToBurn = 3;
        await campaign.connect(user2)["burnTicketBatch(uint256)"](ticketsToBurn);

        const user1NewTicketIdsData = await campaign.childrenOf(user1Data.userCampaignId);
        const user2NewTicketIdsData = await campaign.childrenOf(user2Data.userCampaignId);
        const user1NewTicketIds = user1NewTicketIdsData.map(ticketId => ticketId.tokenId);
        const user2NewTicketIds = user2NewTicketIdsData.map(ticketId => ticketId.tokenId);
        expect(user1NewTicketIds.length).to.be.eq(5);
        expect(user2NewTicketIds.length).to.be.eq(0);
        await checkTicketOwnership(karrotTicket, user1NewTicketIds, user1Data.userCampaignId, user1);
        await checkTicketOwnership(karrotTicket, user2NewTicketIds, user2Data.userCampaignId, user2);
        expect(await karrotTicket.balanceOf(campaign.address)).to.be.eq(5);
        const ticketsToBurn2 = 6;
        
        await expect(campaign.connect(user1)["burnTicketBatch(uint256)"](ticketsToBurn2)).to.be.revertedWith("Not enough tickets to burn");
    });

    it("Should prevent accept child if it is not ticket", async function () {
        const karrotTicket = await (await ethers.getContractFactory("KarrotTicket")).deploy(owner.address, minter.address, campaign.address, "Test KarrotTicket");
        const ERC7401Mock = await (await ethers.getContractFactory("ERC7401Mock")).deploy(owner.address, minter.address, "Test ERC7401");
        await campaign.setTicketContract(karrotTicket.address);
        await mintPassportsAndOrganizations();
        await campaign.connect(minter).mintToOrganization(1, []);

        await ERC7401Mock.connect(minter).mintTo(1, campaign.address);
        await expect(campaign.connect(minter).acceptChild(1, 0, ERC7401Mock.address, 1))
            .to.be.revertedWith("Only ticket can be child of campaign");
        expect((await campaign.childrenOf(1)).length).to.eq(0)
    });

    async function checkTicketOwnership(karrotTicket: KarrotTicket, userTicketIds: BigNumber[], userCampaignId: BigNumber, owner: SignerWithAddress) {
        for (let i = 0; i < userTicketIds.length; i++) {
            const ticketId = userTicketIds[i];
            const ticketDirectOwner = await karrotTicket.directOwnerOf(ticketId);
            expect(ticketDirectOwner.parentId).to.be.eq(userCampaignId);
            expect(await karrotTicket.ownerOf(ticketId)).to.be.eq(owner.address);
        }
    }

    async function mintTickets(karrotTicket: KarrotTicket, user: SignerWithAddress, numberTicketsToMint: number) {
        const ownerPassportNft = await passport.ownerToken(user.address);
        const ownerOrganizationNft = await organization.ownerToken(ownerPassportNft);
        await campaign.connect(minter).mintToOrganization(ownerOrganizationNft, []);
        const organizationPendingChildren = await organization.pendingChildrenOf(ownerOrganizationNft);
        const campaignToAccept = organizationPendingChildren[0];
        const childIndex = 0;
        await organization.connect(user).acceptChild(
            ownerOrganizationNft,
            childIndex,
            campaignToAccept.contractAddress,
            campaignToAccept.tokenId
        );
        const userCampaignId = campaignToAccept.tokenId;

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
        expect(await campaign.supportsInterface(interfaceIDHex)).to.equal(true);
    });

    it("Should prevents non-minter from minting tokens", async function () {
        const minterRole = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("MINTER"));
        await expect(campaign.connect(user2).mintToOrganization(user1.address, campaignsAddresses[0]))
            .to.be.revertedWith("AccessControl: account " + user2.address.toLowerCase() + " is missing role " + minterRole);
    });

    it("Should prevents non-admin from setting ticket contracts", async function () {
        const expectedError = `MissingAdminRole("${user2.address}")`;
        await expect(campaign.connect(user2).setTicketContract(user1.address))
            .to.be.revertedWith(expectedError);
    });

    it("Should prevents from setting ticket contracts with wrong interface", async function () {
        await expect(campaign.connect(owner).setTicketContract(organization.address))
            .to.be.revertedWith("InterfaceNotSupported");
    });

    it("Should revert deployment with InterfaceNotSupported for wrong interface", async function () {
        try {
            await (await ethers.getContractFactory("KarrotCampaign")).deploy(
                owner.address,
                user1.address,
                minter.address,
                lotteryAddress,
                lotteryAddress,
                "Test Campaign"
            );
            assert.fail("Contract was deployed, but it should have failed with 'InterfaceNotSupported'.");
        } catch (error) {
            const err = error as Error;
            assert.include(err.message, "reverted with custom error 'InterfaceNotSupported()'", "Deployment did not fail with 'InterfaceNotSupported'.");
        }

        try {
            await (await ethers.getContractFactory("KarrotCampaign")).deploy(
                owner.address,
                user1.address,
                minter.address,
                organization.address,
                organization.address,
                "Test Campaign"
            );
            assert.fail("Contract was deployed, but it should have failed with 'InterfaceNotSupported'.");
        } catch (error) {
            const err = error as Error;
            assert.include(err.message, "reverted with custom error 'InterfaceNotSupported()'", "Deployment did not fail with 'InterfaceNotSupported'.");
        }
    });
});

