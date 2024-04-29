import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { KarrotFactory, TicketMinter, Lottery, RewardTokenMintableMock, KarrotTicket } from "../typechain-types";
import { ethers, network } from "hardhat";
import { expect } from "chai";
import { deployBasicContracts } from "./utis";
import { BigNumber } from "ethers";

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

  async function deployAndSetupLottery() {
    const { karrotFactory, ticketMinter, lotteryAddress, owner, minter, user1, user2 } = await deployBasicContracts();
    await karrotFactory.deployOrganizationAndCampaigns(owner.address, lotteryAddress, "Test Organization 2", ["Campaign 3", "Campaign 4"]);
    const campaignsAddresses = await karrotFactory.getAllCampaigns();
    const organizationAddresses = await karrotFactory.getAllOrganizations();

    const rewardToken = await (await ethers.getContractFactory("RewardTokenMintableMock")).deploy();
    const lottery = (await ethers.getContractAt("Lottery", lotteryAddress)) as Lottery;
    const tiers = [
      {
        tierType: 0,
        winnersShare: 0,
        winnersCount: 1,
        rewardAmount: ethers.utils.parseEther("100"),
      },
      {
        tierType: 1,
        winnersShare: 35_00, // 35%
        winnersCount: 0,
        rewardAmount: ethers.utils.parseEther("10"),
      },
      {
        tierType: 2,
        winnersShare: 0,
        winnersCount: 10,
        rewardAmount: ethers.utils.parseEther("1"),
      },
    ];

    await lottery.setupLottery(rewardToken.address, tiers, [8000, 2000]);
    await rewardToken.transfer(lottery.address, ethers.utils.parseEther("1000"));

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
    const fixture = await loadFixture(deployAndSetupLottery);
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

  it("Ticket contract is registered if deployed through factory", async function () {
    for (let i = 0; i < campaignsAddresses.length; i++) {
      const campaign = await ethers.getContractAt("KarrotCampaign", campaignsAddresses[i]);
      const ticketContract = await campaign.ticketsContract();
      const organizationAddress = i < 2 ? organizationAddresses[0] : organizationAddresses[1];
      const ticketAddress = await lottery.organizationTicketsContracts(organizationAddress, i < 2 ? i : i - 2);
      const organizationTickets = await lottery.getOrganizationTicketsContracts(organizationAddress);
      expect(organizationTickets.length).to.be.equal(2);
      expect(ticketAddress).to.equal(ticketContract);
    }
  });

  it("Should prevents from deploy lottery if incorrect time values", async function () {
    const mintDeadline = +(new Date().getTime() / 1000).toFixed(0) + 1000;
    const burnDeadline = +(new Date().getTime() / 1000).toFixed(0) + 2000;
    const lotteryTime = +(new Date().getTime() / 1000).toFixed(0) + 3000;

    await expect(karrotFactory.deployLotteryContract(owner.address, 0, burnDeadline, lotteryTime)).to.be.revertedWith("Incorrect time values");
    await expect(karrotFactory.deployLotteryContract(owner.address, mintDeadline, 0, lotteryTime)).to.be.revertedWith("Incorrect time values");
    await expect(karrotFactory.deployLotteryContract(owner.address, mintDeadline, burnDeadline, 0)).to.be.revertedWith("Incorrect time values");
  });

  it("Should prevents non-registar from register ticket", async function () {
    const registerRole = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("REGISTRAR"));
    const campaign = await ethers.getContractAt("KarrotCampaign", campaignsAddresses[0]);
    const ticketAddress = await campaign.ticketsContract();

    await expect(lottery.connect(user1).registerTicketContract(ticketAddress)).to.be.revertedWith(
      "AccessControl: account " + user1.address.toLowerCase() + " is missing role " + registerRole
    );
  });

  it("Should prevents from register ticket contracts with wrong interface", async function () {
    const registerRole = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("REGISTRAR"));
    await lottery.grantRole(registerRole, owner.address);
    const campaign = await ethers.getContractAt("KarrotCampaign", campaignsAddresses[0]);

    await expect(lottery.registerTicketContract(campaign.address)).to.be.revertedWith("InterfaceNotSupported");
  });

  it("Can't initializeLottery before burn deadline", async function () {
    await expect(lottery.initializeLottery(0)).to.be.revertedWith("Burn period not finished yet");
  });

  describe("Lottery initialized", async function () {
    beforeEach(async function () {
      await ethers.provider.send("evm_increaseTime", [2001]);
    });

    it("Lottery initialized correctly for 1 organization", async function () {
      await lottery.initializeLottery(1);
      const organizations = await lottery.getAllOrganizations();
      const organizationSharesForFixedTiers = await lottery.getOrganizationSharesForFixedTiers();

      expect(organizations[0]).to.be.eq(organizationAddresses[0]);
      expect(organizationSharesForFixedTiers[0]).to.be.eq(8000);
      expect(await lottery.initializedOrganizationsCount()).to.equal(1);
      expect(await lottery.lotteryTicketsTotalSupply()).to.equal(organazationsTicketsCount[0]);
    });

    it("Lottery initialized correctly when expected number of organizations greater than actual number", async function () {
      await lottery.initializeLottery(5); // expected 2

      expect(await lottery.initializedOrganizationsCount()).to.equal(2);
      const expectedTicketsCount = organazationsTicketsCount[0] + organazationsTicketsCount[1];
      const organizationSharesForFixedTiers = await lottery.getOrganizationSharesForFixedTiers();
      const organizations = await lottery.getAllOrganizations();

      expect(organizationSharesForFixedTiers[0]).to.be.eq(8000);
      expect(organizationSharesForFixedTiers[1]).to.be.eq(2000);
      expect(organizations[0]).to.be.eq(organizationAddresses[0]);
      expect(organizations[1]).to.be.eq(organizationAddresses[1]);
      expect(await lottery.lotteryTicketsTotalSupply()).to.equal(expectedTicketsCount);
    });

    it("Lottery initialized correctly", async function () {
      await lottery.initializeLottery(0);

      expect(await lottery.initializedOrganizationsCount()).to.equal(2);
      const expectedTicketsCount = organazationsTicketsCount[0] + organazationsTicketsCount[1];
      const organizationSharesForFixedTiers = await lottery.getOrganizationSharesForFixedTiers();
      const organizations = await lottery.getAllOrganizations();

      expect(organizationSharesForFixedTiers[0]).to.be.eq(8000);
      expect(organizationSharesForFixedTiers[1]).to.be.eq(2000);
      expect(organizations[0]).to.be.eq(organizationAddresses[0]);
      expect(organizations[1]).to.be.eq(organizationAddresses[1]);
      expect(await lottery.lotteryTicketsTotalSupply()).to.equal(expectedTicketsCount);

      const organization1TicketsRange = await lottery.organizationTicketsRange(organizationAddresses[0]);
      expect(organization1TicketsRange.firstLotteryTicketId).to.equal(0);
      expect(organization1TicketsRange.lastLotteryTicketId).to.equal(9);
      const organization2TicketsRange = await lottery.organizationTicketsRange(organizationAddresses[1]);
      expect(organization2TicketsRange.firstLotteryTicketId).to.equal(10);
      expect(organization2TicketsRange.lastLotteryTicketId).to.equal(19);

      const allCampaignTickets = await lottery.getAllCampaignTickets();
      const allTickets = await karrotFactory.getAllTickets();
      expect(allCampaignTickets.length).to.equal(4);
      let startIndex = 0;
      for (let i = 0; i < allCampaignTickets.length; i++) {
        expect(allCampaignTickets[i].campaignTicketContract).to.equal(allTickets[i]);
        expect(allCampaignTickets[i].ticketRange.firstLotteryTicketId).to.equal(startIndex);
        const endIndex = startIndex + 4;
        expect(allCampaignTickets[i].ticketRange.lastLotteryTicketId).to.equal(endIndex);
        startIndex = endIndex + 1;
      }

      const tiers = await lottery.getAllTiers();
      expect(tiers.length).to.equal(3);
      //Jackpot tier
      expect(tiers[0].tierType).to.equal(0);
      expect(tiers[0].winnersCount).to.equal(1);
      expect(tiers[0].winnersShare).to.equal(0);
      expect(tiers[0].rewardAmount).to.equal(ethers.utils.parseEther("100"));

      //Random tier should be initialized with winners count
      expect(tiers[1].tierType).to.equal(1);
      expect(tiers[1].winnersCount).to.equal(Math.trunc((expectedTicketsCount * 35) / 100));
      expect(tiers[1].winnersShare).to.equal(3500); // 35%
      expect(tiers[1].rewardAmount).to.equal(ethers.utils.parseEther("10"));

      //Fixed winners tier
      expect(tiers[2].tierType).to.equal(2);
      expect(tiers[2].winnersCount).to.equal(10);
      expect(tiers[2].winnersShare).to.equal(0);
      expect(tiers[2].rewardAmount).to.equal(ethers.utils.parseEther("1"));
    });

    it("Can't call initializeLottery twice", async function () {
      await lottery.initializeLottery(0);
      await expect(lottery.initializeLottery(0)).to.be.revertedWith("Lottery already initialized");
    });

    it("Can't call runLottery before lottery time come", async function () {
      await lottery.initializeLottery(0);
      await expect(lottery.runLottery()).to.be.revertedWith("Lottery time not reached yet");
    });
  });

  describe("Lottery run", async function () {
    type Winner = {
      owner: string;
      amountToken: number;
    };

    async function processTierWinners(winners: Winner[], tier: number, totalWinners: number) {
      for (let i = 0; i < totalWinners; i += 1) {
        const lotteryTicketId = await lottery.tierWinners(tier, i);
        const [ticketAddress, ticketId] = await lottery.getUnderlyingTicket(lotteryTicketId);
        const ticketContract = await ethers.getContractAt("KarrotTicket", ticketAddress);
        const owner = await ticketContract.ownerOf(ticketId);
        const amountToken = Number(await lottery.winnerAmount(lotteryTicketId));
        const index = winners.findIndex((winner) => winner.owner === owner);

        if (index !== -1) {
          winners[index].amountToken += amountToken;
        } else {
          winners.push({ owner, amountToken });
        }
      }
    }

    beforeEach(async function () {
      await ethers.provider.send("evm_increaseTime", [3001]);
      await lottery.initializeLottery(0);
      await lottery.runLottery();
    });

    it("Lottery randomSalt is gotten", async function () {
      expect(await lottery.randomSalt()).to.not.equal(0);
    });

    it("Can't call runLottery twice", async function () {
      await expect(lottery.runLottery()).to.be.revertedWith("Lottery already run");
    });

    it("Can't reward winners twice", async function () {
      await lottery.rewardWinners(0);
      await expect(lottery.rewardWinners(0)).to.be.revertedWith("Lottery already processed");
    });

    it("Reward token is transferred to one user who won jackpot", async function () {
      const winners: Winner[] = [];
      const oldBalanceOfLottery = Number(await rewardToken.balanceOf(lottery.address));
      await lottery.rewardWinners(1);
      await processTierWinners(winners, 0, 1);
      const newBalanceOfLottery = Number(await rewardToken.balanceOf(lottery.address));
      const balanceOfWinner = Number(await rewardToken.balanceOf(winners[0].owner));

      expect(winners[0].amountToken).to.eq(balanceOfWinner);
      expect(newBalanceOfLottery).to.eq(oldBalanceOfLottery - balanceOfWinner);
    });

    it("Correct reward when expected number of tiers greater than actual number", async function () {
      const distributedAmount = Number(ethers.utils.parseEther("180"));
      const oldBalanceOfLottery = Number(await rewardToken.balanceOf(lottery.address));
      await lottery.rewardWinners(5);
      const newBalanceOfLottery = Number(await rewardToken.balanceOf(lottery.address));
      expect(newBalanceOfLottery).to.eq(oldBalanceOfLottery - distributedAmount);
    });

    it("Reward token is transferred to winners", async function () {
      const oldBalanceOfLottery = Number(await rewardToken.balanceOf(lottery.address));
      const winners: Winner[] = [];
      const tier1 = await lottery.getTier(1);
      const tier2 = await lottery.getTier(2);
      const totalWinnersTier1 = Number(tier1.winnersCount);
      const totalWinnersTier2 = Number(tier2.winnersCount);

      await lottery.rewardWinners(0);
      await processTierWinners(winners, 0, 1);
      await processTierWinners(winners, 1, totalWinnersTier1);
      await processTierWinners(winners, 2, totalWinnersTier2);

      let totalSpentTokens = 0;
      for (let i = 0; i < winners.length; i += 1) {
        const balanceOfWinner = Number(await rewardToken.balanceOf(winners[i].owner));
        totalSpentTokens += balanceOfWinner;

        expect(winners[i].amountToken).to.eq(balanceOfWinner);
      }

      const newBalanceOfLottery = Number(await rewardToken.balanceOf(lottery.address));
      expect(newBalanceOfLottery).to.eq(oldBalanceOfLottery - totalSpentTokens);
    });
  });

  describe("Terms and conditions for setup lottery", async function () {
    type Tier = {
      tierType: number;
      winnersShare: number;
      winnersCount: number;
      rewardAmount: BigNumber;
    };

    let tier0: Tier;
    let tier1: Tier;
    let tier2: Tier;

    beforeEach(async function () {
      tier0 = {
        tierType: 0,
        winnersShare: 0,
        winnersCount: 1,
        rewardAmount: ethers.utils.parseEther("100"),
      };
      tier1 = {
        tierType: 1,
        winnersShare: 40_00, //40%
        winnersCount: 0,
        rewardAmount: ethers.utils.parseEther("10"),
      };
      tier2 = {
        tierType: 2,
        winnersShare: 0,
        winnersCount: 10,
        rewardAmount: ethers.utils.parseEther("1"),
      };
    });

    it("Should prevents if non-admin setup", async function () {
      const adminRole = ethers.constants.HashZero;
      await expect(lottery.connect(user1).setupLottery(rewardToken.address, [], [])).to.be.revertedWith(
        "AccessControl: account " + user1.address.toLowerCase() + " is missing role " + adminRole
      );
    });

    it("Should prevents setup after lottery time", async function () {
      await ethers.provider.send("evm_increaseTime", [3001]);
      await expect(lottery.setupLottery(rewardToken.address, [], [])).to.be.revertedWith("Can't setup after lottery time");
    });

    it("Should prevents setup if reward token is not a contract", async function () {
      await expect(lottery.setupLottery(user1.address, [], [])).to.be.revertedWith("Reward token is not a contract");
    });

    it("Should prevents setup if incorrect organization shares count", async function () {
      await expect(lottery.setupLottery(rewardToken.address, [], [])).to.be.revertedWith("Incorrect organization shares count");
    });

    it("Should prevents setup if organization shares count more than bips or 0", async function () {
      await expect(lottery.setupLottery(rewardToken.address, [], [12000, 2000])).to.be.revertedWith("Incorrect organization shares");
      await expect(lottery.setupLottery(rewardToken.address, [], [0, 2000])).to.be.revertedWith("Incorrect organization shares");
    });

    it("Should prevents setup if total shares amounu is not 100%", async function () {
      await expect(lottery.setupLottery(rewardToken.address, [], [8000, 1999])).to.be.revertedWith("Total shares sum must be 100%");
    });

    it("Should prevents setup if first tier is not jackpot", async function () {
      tier0.tierType = 1;
      await expect(lottery.setupLottery(rewardToken.address, [tier0], [8000, 2000])).to.be.revertedWith("First tier must be Jackpot");
    });

    it("Should prevents setup if jackpot tier has more than 2 winners", async function () {
      tier0.winnersCount = 2;
      await expect(lottery.setupLottery(rewardToken.address, [tier0], [8000, 2000])).to.be.revertedWith("There must be 1 winner in Jackpot tier");
    });

    it("Should prevents setup if reward amount equal 0", async function () {
      tier0.rewardAmount = ethers.utils.parseEther("0");
      await expect(lottery.setupLottery(rewardToken.address, [tier0], [8000, 2000])).to.be.revertedWith("Incorrect tier values");
    });

    it("Should prevents setup if tiers in the wrong order", async function () {
      await expect(lottery.setupLottery(rewardToken.address, [tier0, tier2, tier1], [8000, 2000])).to.be.revertedWith("Incorrect tier order");
    });

    it("Should prevents setup if winners share equal 0 for random tier or count for fixed", async function () {
      tier1.winnersShare = 0;
      await expect(lottery.setupLottery(rewardToken.address, [tier0, tier1], [8000, 2000])).to.be.revertedWith("Winners share can't be 0 for random tier");

      tier1.winnersShare = 40_00;
      tier2.winnersCount = 0;
      await expect(lottery.setupLottery(rewardToken.address, [tier0, tier2], [8000, 2000])).to.be.revertedWith("Winners count can't be 0 for fixed tier");
    });
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
    expect(await lottery.supportsInterface(interfaceIDHex)).to.equal(true);
  });

  after(async function () {
    //revert to initial state to remove time manipulation results
    await network.provider.send("evm_revert", [hardhatSnapshotId]);
  });
});
