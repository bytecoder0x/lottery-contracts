import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { KarrotFactory, TicketMinter, Lottery } from "../typechain-types";
import { ethers, network } from "hardhat";
import { expect } from "chai";
import { deployBasicContracts } from "./utis";

describe("Lottery", async () => {
  let hardhatSnapshotId: string;
  let karrotFactory: KarrotFactory
  let ticketMinter: TicketMinter;
  let lottery: Lottery;
  let organizationAddresses: string[];
  let campaignsAddresses: string[];
  let organazationsTicketsCount: number[];
  let owner: SignerWithAddress, minter: SignerWithAddress, user1: SignerWithAddress, user2: SignerWithAddress;

  async function deployAndSetupLottery() {
    const { karrotFactory, ticketMinter, lotteryAddress, owner, minter }
      = await deployBasicContracts();
    await karrotFactory.deployOrganizationAndCampaigns(
      owner.address,
      lotteryAddress,
      "Test Organization 2",
      ["Campaign 3", "Campaign 4"]
    );
    const campaignsAddresses = await karrotFactory.getAllCampaigns();
    const organizationAddresses = await karrotFactory.getAllOrganizations();

    const rewardToken = await (await ethers.getContractFactory("RewardTokenMintableMock")).deploy();
    const lottery = await ethers.getContractAt("Lottery", lotteryAddress) as Lottery;
    const tiers = [{
      tierType: 0,
      winnersShare: 0,
      winnersCount: 1,
      rewardAmount: ethers.utils.parseEther("100")
    }, {
      tierType: 1,
      winnersShare: 5_00, //5%
      winnersCount: 0,
      rewardAmount: ethers.utils.parseEther("10")
    }, {
      tierType: 2,
      winnersShare: 0,
      winnersCount: 10,
      rewardAmount: ethers.utils.parseEther("1")
    }];

    await lottery.setupLottery(rewardToken.address, tiers, [8000, 2000]);
    await rewardToken.transfer(lottery.address, ethers.utils.parseEther("1000"));

    const users = await ethers.getSigners();

    let organazationsTicketsCount = [0, 0];
    for (let u = 2; u < 10; u++) {
      for (let c = 0; c < campaignsAddresses.length; c++) {
        await ticketMinter.connect(minter).mintTickets(
          users[u].address,
          campaignsAddresses[c],
          [10 + u]
        );

        //campaign 0 and 1 is for organization 0, campaign 2 and 3 is for organization 1
        if (c < 2) {
          organazationsTicketsCount[0] = organazationsTicketsCount[0] + 10 + u;
        } else {
          organazationsTicketsCount[1] = organazationsTicketsCount[1] + 10 + u;
        }
      }
    }

    return {
      karrotFactory,
      ticketMinter,
      lottery,
      organizationAddresses,
      campaignsAddresses,
      organazationsTicketsCount,
      owner,
      minter,
      user1,
      user2
    };
  }

  before(async function () {
    hardhatSnapshotId =  await network.provider.send('evm_snapshot')
  });

  beforeEach("Init test environment", async () => {
    const fixture = await loadFixture(deployAndSetupLottery);
    karrotFactory = fixture.karrotFactory;
    ticketMinter = fixture.ticketMinter;
    lottery = fixture.lottery;
    owner = fixture.owner;
    minter = fixture.minter;
    organizationAddresses = fixture.organizationAddresses;
    campaignsAddresses = fixture.campaignsAddresses;
    organazationsTicketsCount = fixture.organazationsTicketsCount;
    user1 = fixture.user1;
    user2 = fixture.user2;
  })

  it("Ticket contract is registered if deployed through factory", async function () {
    for (let i = 0; i < campaignsAddresses.length; i++) {
      const campaign = await ethers.getContractAt("KarrotCampaign", campaignsAddresses[i]);
      const ticketContract = await campaign.ticketsContract();
      const organizationAddress = i < 2 ? organizationAddresses[0] : organizationAddresses[1];
      expect(await lottery.organizationTicketsContracts(organizationAddress, i < 2 ? i : i - 2)).to.equal(ticketContract);
    }
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
      expect(await lottery.lotteryTicketsTotalSupply()).to.equal(expectedTicketsCount);

      const organization1TicketsRange = await lottery.organizationTicketsRange(organizationAddresses[0]);
      expect(organization1TicketsRange.firstLotteryTicketId).to.equal(0);
      expect(organization1TicketsRange.lastLotteryTicketId).to.equal(247);
      const organization2TicketsRange = await lottery.organizationTicketsRange(organizationAddresses[1]);
      expect(organization2TicketsRange.firstLotteryTicketId).to.equal(248);
      expect(organization2TicketsRange.lastLotteryTicketId).to.equal(495);

      const allCampaignTickets = await lottery.getAllCampaignTickets();
      const allTickets = await karrotFactory.getAllTickets();
      expect(allCampaignTickets.length).to.equal(4);
      let startIndex = 0;
      for (let i = 0; i < allCampaignTickets.length; i++) {
        expect(allCampaignTickets[i].campaignTicketContract).to.equal(allTickets[i]);
        expect(allCampaignTickets[i].ticketRange.firstLotteryTicketId).to.equal(startIndex);
        const endIndex = startIndex + 123;
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
      expect(tiers[1].winnersCount).to.equal(Math.trunc(expectedTicketsCount * 5 / 100));
      expect(tiers[1].winnersShare).to.equal(500); //5%
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

      it("Reward token is transferred to winners", async function () {
        await lottery.rewardWinners(0);
        //TODO: check winners for each tier
      });
    });
  });

  after(async function () {
    //revert to initial state to remove time manipulation results
    await network.provider.send("evm_revert", [hardhatSnapshotId]);
  });
});