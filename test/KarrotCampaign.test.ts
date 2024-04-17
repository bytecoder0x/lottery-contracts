import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { KarrotOrganization, KarrotCampaign } from "../typechain-types";
import { ethers } from "hardhat";
import { assert, expect } from "chai";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { deployBasicContracts } from "./utis";

describe("KarrotCampaign", async () => {
    let campaign: KarrotCampaign;
    let organization: KarrotOrganization;
    let owner: SignerWithAddress;
    let minter: SignerWithAddress;
    let user1: SignerWithAddress;
    let user2: SignerWithAddress;
    let organizationAddress: string;
    let campaignsAddresses: string[];
    let lotteryAddress: string;
    beforeEach("Init test environment", async () => {
        const fixture = await loadFixture(deployBasicContracts);
        owner = fixture.owner;
        minter = fixture.minter;
        user1 = fixture.user1;
        user2 = fixture.user2;
        organizationAddress = fixture.organizationAddress;
        campaignsAddresses = fixture.campaignsAddresses;
        organization = await ethers.getContractAt("KarrotOrganization", organizationAddress);
        campaign = await ethers.getContractAt("KarrotCampaign", campaignsAddresses[0]);
        lotteryAddress = fixture.lotteryAddress;
    });

    it("Should mint campaign token", async function () {
        const minterRole = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("MINTER"));
        await organization.grantRole(minterRole, minter.address);
        await campaign.grantRole(minterRole, minter.address);

        await organization.connect(minter).mintTo(user1.address, []);
        const organizationId = await organization.ownerToken(user1.address);
        await campaign.connect(minter).mintToOrganization(organizationId, []);
        const mintedTokenCampaignId = 1;

        expect(await campaign.balanceOf(organization.address)).to.be.eq(1);
        const directOwner = await campaign.directOwnerOf(mintedTokenCampaignId);
        expect(directOwner.isNFT).to.be.eq(true);
        expect(directOwner.owner_).to.be.eq(organization.address);
        expect(directOwner.parentId).to.be.eq(organizationId);
    });

    it("Should set ticket contracts", async function () {
        const karrotTicket = await (await ethers.getContractFactory("KarrotTicket")).deploy(owner.address, minter.address, campaign.address, "Test KarrotTicket");
        campaign.connect(owner).setTicketContract(karrotTicket.address)
        expect(await campaign.ticketsContract()).to.be.eq(karrotTicket.address);
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

