import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { KarrotFactory, TicketMinter } from "../typechain-types";
import { ethers, network } from "hardhat";
import { expect } from "chai";
import { deployBasicContracts } from "./utis";

describe("TicketMinter", async () => {
  let hardhatSnapshotId: string;
  let karrotFactory: KarrotFactory
  let ticketMinter: TicketMinter;
  let organizationAddress: string;
  let campaignsAddresses: string[];
  let owner: SignerWithAddress, minter: SignerWithAddress, user1: SignerWithAddress, user2: SignerWithAddress;

  before(async function () {
    hardhatSnapshotId =  await network.provider.send('evm_snapshot')
  });

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

  it("Can mint multiple tickets to multiple users", async function () {
    await ticketMinter.connect(minter).mintTicketsBatch(
      [user1.address, user2.address],
      campaignsAddresses[0],
      [2, 3]);
    const organization = await ethers.getContractAt("KarrotOrganization", organizationAddress);
    expect(await organization.balanceOf(user1.address)).to.equal(1);
    expect(await organization.balanceOf(user2.address)).to.equal(1);
    const user1OrganizationNft = await organization.ownerToken(user1.address);
    const user2OrganizationNft = await organization.ownerToken(user2.address);
    const user1CampaignNfts = await organization.childrenOf(user1OrganizationNft);
    const user2CampaignNfts = await organization.childrenOf(user2OrganizationNft);
    expect(user1CampaignNfts.length).to.equal(1);
    expect(user1CampaignNfts[0].contractAddress).to.equal(campaignsAddresses[0]);
    expect(user2CampaignNfts.length).to.equal(1);
    expect(user2CampaignNfts[0].contractAddress).to.equal(campaignsAddresses[0]);

    const campaign = await ethers.getContractAt("KarrotCampaign", campaignsAddresses[0]);
    const ticketContract = await campaign.ticketsContract();
    const user1TicketNfts = await campaign.childrenOf(user1CampaignNfts[0].tokenId);
    const user2TicketNfts = await campaign.childrenOf(user2CampaignNfts[0].tokenId);
    expect(user1TicketNfts.length).to.equal(2);
    expect(user2TicketNfts.length).to.equal(3);
    for (let ticket of user1TicketNfts) {
      expect(ticket.contractAddress).to.equal(ticketContract);
    }
    for (let ticket of user2TicketNfts) {
      expect(ticket.contractAddress).to.equal(ticketContract);
    }
  });

  it("Can't mint after mint deadline", async function () {
    await ethers.provider.send("evm_increaseTime", [2000])
    await expect(ticketMinter.connect(minter).mintTicketsBatch(
      [user1.address, user2.address],
      campaignsAddresses[0],
      [2, 3])).to.be.revertedWith("MintTimeEnded");
  });

  after(async function () {
    //revert to initial state to remove time manipulation results
    await network.provider.send("evm_revert", [hardhatSnapshotId]);
  });
})