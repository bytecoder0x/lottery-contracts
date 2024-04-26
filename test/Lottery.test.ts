import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { KarrotFactory, TicketMinter, Lottery, RewardTokenMintableMock, KarrotTicket } from "../typechain-types";
import { ethers, network } from "hardhat";
import { expect } from "chai";
import { deployBasicContracts } from "./utis";

describe.only("Lottery", async () => {
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
        winnersShare: 40_00, //40%
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
      await lottery.initializeLottery(0);
    });

    it("Lottery initialized correctly", async function () {
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
      expect(tiers[1].winnersCount).to.equal(Math.trunc((expectedTicketsCount * 40) / 100));
      expect(tiers[1].winnersShare).to.equal(4000); // 25%
      expect(tiers[1].rewardAmount).to.equal(ethers.utils.parseEther("10"));

      //Fixed winners tier
      expect(tiers[2].tierType).to.equal(2);
      expect(tiers[2].winnersCount).to.equal(10);
      expect(tiers[2].winnersShare).to.equal(0);
      expect(tiers[2].rewardAmount).to.equal(ethers.utils.parseEther("1"));
    });

    it("Can't call initializeLottery twice", async function () {
      await expect(lottery.initializeLottery(0)).to.be.revertedWith("Lottery already initialized");
    });

    it("Can't call runLottery before lottery time come", async function () {
      await expect(lottery.runLottery()).to.be.revertedWith("Lottery time not reached yet");
    });

    describe("Lottery run", async function () {
      beforeEach(async function () {
        await ethers.provider.send("evm_increaseTime", [1000]);
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

      it("Reward token is transferred to winners", async function () {
        type Winner = {
          owner: string;
          amountToken: number;
        };

        const oldBalanceOfLottery = Number(await rewardToken.balanceOf(lottery.address));
        const winners: Winner[] = [];
        const tier1 = await lottery.getTier(1);
        const tier2 = await lottery.getTier(2);
        const totalWinnersTier1 = Number(tier1.winnersCount);
        const totalWinnersTier2 = Number(tier2.winnersCount);

        await lottery.rewardWinners(0);
        await processTierWinners(0, 1);
        await processTierWinners(1, totalWinnersTier1);
        await processTierWinners(2, totalWinnersTier2);

        async function processTierWinners(tier: number, totalWinners: number) {
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
  });

  describe("Redemption functionality", async function () {
    it("Should prevents non-admin set redemption price and cap", async function () {
      const adminRole = ethers.constants.HashZero;

      await expect(lottery.connect(user1).setRedemptionPrice(1)).to.be.revertedWith(
        "AccessControl: account " + user1.address.toLowerCase() + " is missing role " + adminRole
      );
    });

    it("Should prevents redemption price from set to 0", async function () {
      await expect(lottery.setRedemptionPrice(0)).to.be.revertedWith("Redemption price can't be 0");
    });

    it("Correct set redemption price and cap", async function () {
      const redemptionPrice = ethers.utils.parseEther("100");
      await lottery.setRedemptionPrice(redemptionPrice);
      await lottery.setRedemptionCap(redemptionPrice);
      expect(await lottery.redemptionPrice()).to.be.eq(redemptionPrice);
      expect(await lottery.redemptionCap()).to.be.eq(redemptionPrice);
    });

    // it("Should prevents redeem if burn period finished or price not set", async function () {
    //   const campaign = await ethers.getContractAt("KarrotCampaign", campaignsAddresses[0]);
    //   const ticketContract = await campaign.ticketsContract();
    //   await expect(lottery.redeem(ticketContract, 2)).to.be.revertedWith("Redemption price not set");

    //   await ethers.provider.send("evm_increaseTime", [2001]);
    //   await expect(lottery.redeem(ticketContract, 2)).to.be.revertedWith("Burn period finished yet");
    // });

    // it("Should prevents redeem if redemption cap reached", async function () {
    //   const redemptionPrice = ethers.utils.parseEther("100");
    //   await lottery.setRedemptionPrice(redemptionPrice);
    //   await lottery.setRedemptionCap(redemptionPrice);
    //   const campaign = await ethers.getContractAt("KarrotCampaign", campaignsAddresses[0]);
    //   const ticketContract = await campaign.ticketsContract();
    //   await expect(lottery.redeem(ticketContract, 2)).to.be.revertedWith("Redemption cap reached");
    // });

    // it("redeem test", async function () {
    //   const redemptionPrice = ethers.utils.parseEther("100");
    //   const campaign = await ethers.getContractAt("KarrotCampaign", campaignsAddresses[0]);

    //   const organization = await ethers.getContractAt("KarrotOrganization", organizationAddresses[0]);
    //   const ticketAddress = await campaign.ticketsContract();
    //   await lottery.setRedemptionPrice(redemptionPrice);

    //   await organization.connect(user1).approve(lottery.address, 1);
    //   console.log(await organization.isApprovedOrOwner(lottery.address, 1));
    //   console.log(lottery.address);
    //   // await lottery.redeem(ticketAddress, 1);
    //   // console.log(minter.address);
    // });
  });

  describe("Terms and conditions for setup and initialize lottery", async function () {});

  after(async function () {
    //revert to initial state to remove time manipulation results
    await network.provider.send("evm_revert", [hardhatSnapshotId]);
  });
});
