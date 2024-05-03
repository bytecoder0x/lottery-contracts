import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { KarrotFactory, TicketMinter, Lottery, RewardTokenMintableMock, TicketRedemption } from "../typechain-types";
import { ethers, network } from "hardhat";
import { expect } from "chai";
import { deployBasicContracts } from "./utis";

describe("TicketRedemption", async () => {
  let hardhatSnapshotId: string;
  let karrotFactory: KarrotFactory;
  let ticketMinter: TicketMinter;
  let lottery: Lottery;
  let redemption: TicketRedemption;
  let rewardToken: RewardTokenMintableMock;
  let organizationAddresses: string[];
  let campaignsAddresses: string[];
  let organazationsTicketsCount: number[];
  let owner: SignerWithAddress, minter: SignerWithAddress, user1: SignerWithAddress, user2: SignerWithAddress;

  async function deployRedemptionAndLottery() {
    const { karrotFactory, ticketMinter, lotteryAddress, redemptionAddress, owner, minter, user1, user2 } = await deployBasicContracts();
    await karrotFactory.deployOrganizationAndCampaigns(owner.address, lotteryAddress, "Test Organization 2", ["Campaign 3", "Campaign 4"]);
    const campaignsAddresses = await karrotFactory.getAllCampaigns();
    const organizationAddresses = await karrotFactory.getAllOrganizations();

    const rewardToken = await (await ethers.getContractFactory("RewardTokenMintableMock")).deploy();
    const lottery = (await ethers.getContractAt("Lottery", lotteryAddress)) as Lottery;
    const redemption = (await ethers.getContractAt("TicketRedemption", redemptionAddress)) as TicketRedemption;
    await rewardToken.transfer(redemption.address, ethers.utils.parseEther("1000"));

    let organazationsTicketsCount = [0, 0];

    for (let c = 0; c < campaignsAddresses.length; c++) {
      //campaign 0 and 1 is for organization 0, campaign 2 and 3 is for organization 1
      if (c < 2) {
        await ticketMinter.connect(minter).mintTickets(user1.address, campaignsAddresses[c], 5);
        organazationsTicketsCount[0] = organazationsTicketsCount[0] + 5;
      } else {
        await ticketMinter.connect(minter).mintTickets(user2.address, campaignsAddresses[c], 5);
        organazationsTicketsCount[1] = organazationsTicketsCount[1] + 5;
      }
    }

    return {
      karrotFactory,
      ticketMinter,
      lottery,
      redemption,
      rewardToken,
      organizationAddresses,
      campaignsAddresses,
      organazationsTicketsCount,
      owner,
      minter,
      user1,
      user2,
    };
  }

  before(async function () {
    hardhatSnapshotId = await network.provider.send("evm_snapshot");
  });

  beforeEach("Init test environment", async () => {
    const fixture = await loadFixture(deployRedemptionAndLottery);
    karrotFactory = fixture.karrotFactory;
    ticketMinter = fixture.ticketMinter;
    lottery = fixture.lottery;
    redemption = fixture.redemption;
    rewardToken = fixture.rewardToken;
    owner = fixture.owner;
    minter = fixture.minter;
    organizationAddresses = fixture.organizationAddresses;
    campaignsAddresses = fixture.campaignsAddresses;
    organazationsTicketsCount = fixture.organazationsTicketsCount;
    user1 = fixture.user1;
    user2 = fixture.user2;
  });

  it("Should prevents non-admin set redemption price and cap", async function () {
    const adminRole = ethers.constants.HashZero;

    await expect(redemption.connect(user1).setRedemptionPrice(1)).to.be.revertedWith(
      "AccessControl: account " + user1.address.toLowerCase() + " is missing role " + adminRole
    );
    await expect(redemption.connect(user1).setRedemptionCap(1)).to.be.revertedWith(
      "AccessControl: account " + user1.address.toLowerCase() + " is missing role " + adminRole
    );
  });

  it("Should prevents redemption price from set to 0", async function () {
    await expect(redemption.setRedemptionPrice(0)).to.be.revertedWith("Redemption price can't be 0");
  });

  it("Should prevents redeem if burn period finished or price not set", async function () {
    const campaign = await ethers.getContractAt("KarrotCampaign", campaignsAddresses[0]);
    const ticketContract = await campaign.ticketsContract();
    await expect(redemption.redeem(ticketContract, 2)).to.be.revertedWith("Redemption price not set");

    await ethers.provider.send("evm_increaseTime", [2001]);
    await expect(redemption.redeem(ticketContract, 2)).to.be.revertedWith("Burn period finished yet");
  });

  it("Should prevents redeem if redemption cap reached", async function () {
    const redemptionPrice = ethers.utils.parseEther("100");
    await redemption.setRedemptionPrice(redemptionPrice);
    await redemption.setRedemptionCap(redemptionPrice);
    const campaign = await ethers.getContractAt("KarrotCampaign", campaignsAddresses[0]);
    const ticketContract = await campaign.ticketsContract();
    await expect(redemption.redeem(ticketContract, 2)).to.be.revertedWith("Redemption cap reached");
  });

  it("Should prevents ticket redemption if sender does not own any organization", async function () {
    const redemptionPrice = ethers.utils.parseEther("100");
    const campaign = await ethers.getContractAt("KarrotCampaign", campaignsAddresses[0]);
    const ticketAddress = await campaign.ticketsContract();
    await redemption.setRedemptionPrice(redemptionPrice);
    await redemption.setRedemptionCap(redemptionPrice);
    await expect(redemption.connect(minter).redeem(ticketAddress, 1)).to.be.revertedWith("User is not an owner of any organization");
  });

  it("Should prevents ticket redemption if ticket is not registered", async function () {
    const redemptionPrice = ethers.utils.parseEther("100");
    const campaign = await ethers.getContractAt("KarrotCampaign", campaignsAddresses[0]);
    const karrotTicket = await (await ethers.getContractFactory("KarrotTicket")).deploy(owner.address, minter.address, campaign.address, "Test KarrotTicket");
    await redemption.setRedemptionPrice(redemptionPrice);
    await redemption.setRedemptionCap(redemptionPrice);
    await expect(redemption.connect(user1).redeem(karrotTicket.address, 1)).to.be.revertedWith("The ticket is not registered");
  });

  it("Correct set redemption price and cap", async function () {
    const redemptionPrice = ethers.utils.parseEther("100");
    await redemption.setRedemptionPrice(redemptionPrice);
    await redemption.setRedemptionCap(redemptionPrice);
    expect(await redemption.redemptionPrice()).to.be.eq(redemptionPrice);
    expect(await redemption.redemptionCap()).to.be.eq(redemptionPrice);
  });

  it("Correct redemption of tickets", async function () {
    const redemptionPrice = ethers.utils.parseEther("1");
    const redemptionCap = ethers.utils.parseEther("10");
    const campaign = await ethers.getContractAt("KarrotCampaign", campaignsAddresses[0]);
    const ticketAddress = await campaign.ticketsContract();
    const oldAmountTicket = (await campaign.childrenOf(1)).length;
    const oldBalanceOfRedemption = await rewardToken.balanceOf(redemption.address);
    await redemption.setRedemptionPrice(redemptionPrice);
    await redemption.setRedemptionCap(redemptionCap);
    await redemption.setRewardToken(rewardToken.address);
    await campaign.connect(user1).approve(redemption.address, 1)
    await redemption.connect(user1).redeem(ticketAddress, 3);
    const balanceOfWinner = await rewardToken.balanceOf(user1.address);
    const rewardAmount = redemptionPrice.mul(3);
    const newAmountTicket = (await campaign.childrenOf(1)).length;
    const newBalanceOfRedemption = await rewardToken.balanceOf(redemption.address);

    expect(newBalanceOfRedemption).to.be.eq(oldBalanceOfRedemption.sub(rewardAmount));
    expect(newAmountTicket).to.be.eq(oldAmountTicket - 3);
    expect(balanceOfWinner).to.be.eq(rewardAmount);
  });

  it("Should support AccessControl interface", async function () {
    let functionSignature = [
      "hasRole(bytes32,address)",
      "getRoleAdmin(bytes32)",
      "grantRole(bytes32,address)",
      "revokeRole(bytes32,address)",
      "renounceRole(bytes32,address)",
    ];
    let interfaceID = BigInt(0);

    for (const signature of functionSignature) {
      const selector = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(signature)).slice(2, 10);
      interfaceID ^= BigInt("0x" + selector);
    }

    const interfaceIDHex = "0x" + interfaceID.toString(16).padStart(8, "0");
    expect(await redemption.supportsInterface(interfaceIDHex)).to.equal(true);
  });

  after(async function () {
    await network.provider.send("evm_revert", [hardhatSnapshotId]);
  });
});
