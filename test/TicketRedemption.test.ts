import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { KarrotFactory, TicketMinter, Lottery, RewardTokenMintableMock, TicketRedemption } from "../typechain-types";
import { ethers, network } from "hardhat";
import { expect } from "chai";
import { deployBasicContracts } from "./utis";

describe("Lottery", async () => {
  let hardhatSnapshotId: string;
  let karrotFactory: KarrotFactory;
  let ticketMinter: TicketMinter;
  let lottery: Lottery;
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
    rewardToken = fixture.rewardToken;
    owner = fixture.owner;
    minter = fixture.minter;
    organizationAddresses = fixture.organizationAddresses;
    campaignsAddresses = fixture.campaignsAddresses;
    organazationsTicketsCount = fixture.organazationsTicketsCount;
    user1 = fixture.user1;
    user2 = fixture.user2;
  });

  after(async function () {
    await network.provider.send("evm_revert", [hardhatSnapshotId]);
  });
});
