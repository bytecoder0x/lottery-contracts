import { ethers } from "hardhat";
import { expect } from "chai";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { deployBasicContracts, deployRandomGetter } from "./utis";
import { VRFCoordinatorV2Mock, VRFV2Wrapper, MockLinkToken, Lottery, KarrotFactory, RandomGetter } from "../typechain-types";
import { Randomizer } from "../typechain-types/contracts/Randomizer";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";


describe("Randomizer", async () => {
    let karrotFactory: KarrotFactory;
    let lottery: Lottery;
    let coordinator: VRFCoordinatorV2Mock;
    let wrapper: VRFV2Wrapper;
    let randomGetter: RandomGetter;
    let link: MockLinkToken;
    let owner: SignerWithAddress;
    let user1: SignerWithAddress;
    let user2: SignerWithAddress;

    async function deployLotteryAndRandomGetter() {
        const { karrotFactory, ticketMinter, lotteryAddress, owner, minter, user1, user2 } = await deployBasicContracts();
        const { coordinator, wrapper, randomGetter, link } = await deployRandomGetter(karrotFactory, owner);
        const campaignsAddresses = await karrotFactory.getAllCampaigns();
        const lottery = (await ethers.getContractAt("Lottery", lotteryAddress)) as Lottery;
        const rewardToken = await (await ethers.getContractFactory("RewardTokenMintableMock")).deploy();

        await rewardToken.transfer(lottery.address, ethers.utils.parseEther("1000"));
        await lottery.setupLottery(rewardToken.address, randomGetter.address, [], [10000]);
        await ticketMinter.connect(minter).mintTickets(user1.address, campaignsAddresses[0], 5);

        return { karrotFactory, lottery, coordinator, wrapper, randomGetter, link, owner, user1, user2 };
    }

    async function fulfillRandomWord() {
        function generateRandomNumber() {
            let number = '';
            for (let i = 0; i < 77; i++) {
              number += Math.floor(Math.random() * 10);
            }
            return number;
        }

        const lastRequestId = await lottery.requestRandomNumberId();
        const randomNumber = generateRandomNumber();
        await coordinator.fulfillRandomWordsWithOverride(lastRequestId, wrapper.address, [randomNumber]);
    }

    beforeEach("Init test environment", async () => {
        const fixture = await loadFixture(deployLotteryAndRandomGetter);
        karrotFactory = fixture.karrotFactory;
        lottery = fixture.lottery;
        coordinator = fixture.coordinator;
        wrapper = fixture.wrapper;
        randomGetter = fixture.randomGetter;
        link = fixture.link;
        owner = fixture.owner;
        user1 = fixture.user1;
        user2 = fixture.user2;
    });

    
    it("Should prevents deploy with wrong factory", async function () {
        await expect((await ethers.getContractFactory("RandomGetter", owner)).deploy(link.address, wrapper.address, lottery.address, owner.address))
            .to.be.revertedWith("InterfaceNotSupported");
    });

    it("Should successfully receive a random number", async function () {
        await ethers.provider.send("evm_increaseTime", [3001]);
        await lottery.initializeLottery(0);
        await lottery.runLottery();
        await fulfillRandomWord();
        await lottery.rewardWinners(0);
        const lastRequestId = await lottery.requestRandomNumberId();
        const { paid, fulfilled, randomWord } = await randomGetter.s_requests(lastRequestId);
        const randomSalt = await lottery.randomSalt();
        const oneHundredLink = ethers.utils.parseEther("100");

        expect(paid.add(await link.balanceOf(randomGetter.address))).to.be.eq(oneHundredLink);
        expect(fulfilled).to.be.true;
        expect(randomSalt).to.be.eq(randomWord);
    });

    it("Should prevents non-lottery call requestRandomNumber and getRandomNumber function", async function () {
        await expect(randomGetter.connect(user1).requestRandomNumber()).to.be.revertedWith("Only lottery can call this function");
        await expect(randomGetter.connect(user1).getRandomNumber(1)).to.be.revertedWith("Only lottery can call this function");
    });

    it("Should prevents non-admin withdraw link from contract", async function () {
        const adminRole = ethers.constants.HashZero;
        await expect(randomGetter.connect(user1).withdrawLink(1)).to.be.revertedWith(
            "AccessControl: account " + user1.address.toLowerCase() + " is missing role " + adminRole
        );
    });

    it("Should prevents withdraw link if not enough funds", async function () {
        const oneHundredLink = ethers.utils.parseEther("100");
        await expect(randomGetter.withdrawLink(oneHundredLink.add(1))).to.be.revertedWith("Not enough funds");
    });

    
    it("Should correct withdraw link from contract", async function () {
        const oldOwnerBalance = await link.balanceOf(owner.address);
        const oneHundredLink = ethers.utils.parseEther("100");
        await randomGetter.withdrawLink(oneHundredLink);

        expect(oldOwnerBalance.add(oneHundredLink)).to.be.eq(await link.balanceOf(owner.address));
        expect(await link.balanceOf(randomGetter.address)).to.be.eq(0);
    });

    it("Should support AccessControl and IRandomizer interfaces", async function () {
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
        expect(await randomGetter.supportsInterface(interfaceIDHex)).to.equal(true);

        let functionSignatureRedemption = [
            'requestRandomNumber()',
            'getRandomNumber(uint256)',
            'withdrawLink(uint256)'
        ];
        let interfaceIDRedemption = BigInt(0);
    
        for (const signature of functionSignatureRedemption) {
            const selector = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(signature)).slice(2, 10);
            interfaceIDRedemption ^= BigInt('0x' + selector);
        }
    
        const interfaceIDHexRedemption = '0x' + interfaceIDRedemption.toString(16).padStart(8, '0');
        expect(await randomGetter.supportsInterface(interfaceIDHexRedemption)).to.equal(true);
    });
});
