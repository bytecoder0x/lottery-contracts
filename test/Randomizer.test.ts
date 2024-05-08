import { ethers } from "hardhat";
import { expect } from "chai";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { deployBasicContracts, deployRandomizer } from "./utis";
import { VRFCoordinatorV2Mock, VRFV2Wrapper, MockLinkToken, Lottery, KarrotFactory } from "../typechain-types";
import { Randomizer } from "../typechain-types/contracts/Randomizer";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";


describe.only("Randomizer", async () => {
    let karrotFactory: KarrotFactory;
    let lottery: Lottery;
    let coordinator: VRFCoordinatorV2Mock;
    let wrapper: VRFV2Wrapper;
    let randomizer: Randomizer
    let link: MockLinkToken;
    let owner: SignerWithAddress;
    let user1: SignerWithAddress;
    let user2: SignerWithAddress;

    async function deployFactoryAndRandomizer() {
        const { karrotFactory, lotteryAddress, owner, user1, user2 } = await deployBasicContracts();
        const { coordinator, wrapper, randomizer, link } = await deployRandomizer(karrotFactory, owner);
        const lottery = (await ethers.getContractAt("Lottery", lotteryAddress)) as Lottery;

        return { karrotFactory, lottery, coordinator, wrapper, randomizer, link, owner, user1, user2 };
    }

    beforeEach("Init test environment", async () => {
        const fixture = await loadFixture(deployFactoryAndRandomizer);
        karrotFactory = fixture.karrotFactory;
        lottery = fixture.lottery;
        coordinator = fixture.coordinator;
        wrapper = fixture.wrapper;
        randomizer = fixture.randomizer;
        link = fixture.link;
        owner = fixture.owner;
        user1 = fixture.user1;
        user2 = fixture.user2;
    });

    
    it("Should successfully receive a random number", async () => {
        await randomizer.connect(requester).requestRandomNumber()
        const randomNumber =  Math.floor(Math.random() * 1000);
        const lastRequestId = await randomizer.lastRequestId();
        await coordinator.connect(owner).fulfillRandomWordsWithOverride(lastRequestId, wrapper.address, [randomNumber]);
        const { paid, fulfilled } = await randomizer.s_requests(lastRequestId);
        const randomWord = await randomizer.getRandomNumber(lastRequestId);

        expect(paid.add(await link.balanceOf(randomizer.address))).to.be.eq(oneHundredLink);
        expect(fulfilled).to.be.true;
        expect(randomNumber).to.be.eq(randomWord);

        // // expect(paid).to.equal(price)
    })
});
