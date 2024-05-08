import { ethers } from "hardhat";
import { expect } from "chai";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { deployBasicContracts } from "./utis";
import { VRFCoordinatorV2Mock, VRFV2Wrapper, MockLinkToken } from "../typechain-types";
import { Randomizer } from "../typechain-types/contracts/Randomizer";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe.only("Randomizer", async () => {
    let coordinator: VRFCoordinatorV2Mock;
    let wrapper: VRFV2Wrapper;
    let randomizer: Randomizer
    let link: MockLinkToken;
    let owner: SignerWithAddress;
    let requester: SignerWithAddress;
    let user1: SignerWithAddress;
    let user2: SignerWithAddress;

    const pointOneLink = ethers.utils.parseEther("0.1");
    const pointZeroZeroThreeLink = ethers.utils.parseEther("0.003");
    const oneHundredLink = ethers.utils.parseEther("100")
    const wrapperGasOverhead = 60000
    const coordinatorGasOverhead = 52000
    const wrapperPremiumPercentage = 10
    const maxNumWords = 10;
    const weiPerUnitLink = pointZeroZeroThreeLink


    const deployRandomizer = async () => {
        const { karrotFactory, owner, minter: requester, user1, user2 } = await deployBasicContracts();
        const coordinator = await (await ethers.getContractFactory("VRFCoordinatorV2Mock", owner)).deploy(pointOneLink, 1e9);
        const linkEthFeed = await (await ethers.getContractFactory("MockV3Aggregator", owner)).deploy(18, weiPerUnitLink);
        const link = await (await ethers.getContractFactory("MockLinkToken", owner)).deploy();
        const wrapper =  await (await ethers.getContractFactory("VRFV2Wrapper", owner)).deploy(link.address, linkEthFeed.address, coordinator.address);
        const randomizer = await (await ethers.getContractFactory("Randomizer", owner)).deploy(link.address, wrapper.address, karrotFactory.address, owner.address) as Randomizer;

        const keyHash = "0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc";
        await wrapper.connect(owner).setConfig(wrapperGasOverhead, coordinatorGasOverhead, wrapperPremiumPercentage, keyHash, maxNumWords)
        await coordinator.connect(owner).fundSubscription(1, oneHundredLink)
        await link.transfer(randomizer.address, oneHundredLink);

        return { coordinator, wrapper, randomizer, link, owner, requester, user1, user2 };
    }

    beforeEach("Init test environment", async () => {
        const fixture = await loadFixture(deployRandomizer);
        coordinator = fixture.coordinator;
        wrapper = fixture.wrapper;
        randomizer = fixture.randomizer;
        link = fixture.link;
        owner = fixture.owner;
        requester = fixture.requester;
        user1 = fixture.user1;
        user2 = fixture.user2;
    });

    
    it("Should successfully receive a random number", async () => {
        await randomizer.connect(requester).requestRandomNumber()
        const randomNumber =  Math.floor(Math.random() * 1000);
        const lastRequestId = await randomizer.lastRequestId();
        await coordinator.connect(owner).fulfillRandomWordsWithOverride(lastRequestId, wrapper.address, [randomNumber]);
        const { paid, fulfilled } = await randomizer.s_requests(lastRequestId);
        const randomWord = await randomizer.getStatus(lastRequestId);

        expect(paid.add(await link.balanceOf(randomizer.address))).to.be.eq(oneHundredLink);
        expect(fulfilled).to.be.true;
        expect(randomNumber).to.be.eq(randomWord);

        // // expect(paid).to.equal(price)
    })
});
