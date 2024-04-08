import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { KarrotOrganization } from "../typechain-types/contracts/KarrotOrganization";
import { ethers } from "hardhat";
import { assert, expect } from "chai";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";

describe("KarrotOrganization", async () => {
  let organization: KarrotOrganization;
  let owner: SignerWithAddress;
  let minter: SignerWithAddress;
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;

  async function deployOrganization() {
    const [owner, minter, user1, user2] = await ethers.getSigners();
    const organization = await (await ethers.getContractFactory("KarrotOrganization")).deploy(owner.address, minter.address, "Test Organization");
    return { organization, owner, minter, user1, user2 };
  };

  beforeEach("Init test environment", async () => {
    const fixture = await loadFixture(deployOrganization);
    organization = fixture.organization;
    owner = fixture.owner;
    minter = fixture.minter;
    user1 = fixture.user1;
    user2 = fixture.user2;
  });

  describe("Deployment", function () {
    it("Should be correctly initialized", async function () {
      expect(await organization.hasRole(ethers.constants.HashZero, owner.address)).to.equal(true);
      const minterRole = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("MINTER"));
      expect(await organization.hasRole(minterRole, minter.address)).to.equal(true);
      expect(await organization.name()).to.equal("Test Organization");
    });
    it("Should allows minter to mint a new token", async function () {
      const minterRole = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("MINTER"));
      await organization.grantRole(minterRole, minter.address);

      const data = ethers.utils.toUtf8Bytes("");
      await expect(organization.connect(minter).mintTo(user1.address, data))
        .to.emit(organization, 'Transfer')
        .withArgs(ethers.constants.AddressZero, user1.address, 1);

      const tokenId = await organization.ownerToken(user1.address);
      expect(tokenId).to.be.eq(1);
      expect(await organization.ownerOf(tokenId)).to.equal(user1.address);
    });

    it("Should prevents minting to the owner who already has a token", async function () {
      const data = ethers.utils.toUtf8Bytes("");
      await organization.connect(minter).mintTo(user1.address, data);
      await expect(organization.connect(minter).mintTo(user1.address, data))
        .to.be.revertedWith("IncorrectCondition");
    });
    it("Should prevents non-minter from minting tokens", async function () {
      const data = ethers.utils.toUtf8Bytes("");
      const minterRole = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("MINTER"));
      await expect(organization.connect(user2).mintTo(user1.address, data))
        .to.be.revertedWith("AccessControl: account " + user2.address.toLowerCase() + " is missing role " + minterRole);
    });
    it("Should revokes minter role and prevents token minting", async function () {
      const data = ethers.utils.toUtf8Bytes("");
      const minterRole = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("MINTER"));
      await organization.revokeRole(minterRole, minter.address);
      await expect(organization.connect(minter).mintTo(user2.address, data))
        .to.be.revertedWith("AccessControl: account " + minter.address.toLowerCase() + " is missing role " + minterRole);
    });
  });
  describe("KarrotErc7401Base", function () {
    it("Should checks if an address is approved or owner", async function () {
      await organization.connect(minter).mintTo(user1.address, ethers.utils.toUtf8Bytes(""));

      expect(await organization.isApprovedOrOwner(user1.address, 1)).to.equal(true);
      expect(await organization.isApprovedOrOwner(user2.address, 1)).to.equal(false);
    });

    it("Should reports total supply", async function () {
      await organization.connect(minter).mintTo(user1.address, ethers.utils.toUtf8Bytes(""));
      await organization.connect(minter).mintTo(user2.address, ethers.utils.toUtf8Bytes(""));

      expect(await organization.totalSupply()).to.equal(2);
    });
    it("Should support AccessControl interface", async function () {
      const accessControlInterfaceId = '0x7965db0b'; 
      expect(await organization.supportsInterface(accessControlInterfaceId)).to.equal(true);
    });
  
    it("Should support RMRKNestable interface", async function () {
      const rmrkNestableInterfaceId = '0x01ffc9a7'; 
      expect(await organization.supportsInterface(rmrkNestableInterfaceId)).to.equal(true);
    });
  
    it("Should not support a random interface", async function () {
      const randomInterfaceId = '0x12345678';
      expect(await organization.supportsInterface(randomInterfaceId)).to.equal(false);
    });
  });

  /*
    describe("Minting", async function () {
      it("Should allow minter to mint a new token", async function () {
        const tokenCount = 1;
        const data = "0x00";
        const mint = await expect(
          karrot.connect(minterAddress).mintTo(addr1.address, tokenCount, data)
        );
        console.log(mint);
        const owner = await karrot.balanceOf(addr1.address);
        console.log(owner);
        // .to.emit(karrot, 'Transfer')
        // .withArgs(ethers.constants.AddressZero, addr1.address, 1);
      });
  
      it("Should fail if non-minter tries to mint", async function () {
        const tokenCount = 1;
        const data = "0x00";
        await expect(
          karrot.connect(addr1).mintTo(addr1.address, tokenCount, data)
        ).to.be.revertedWith("CallerIsNotMinter");
      });
    });
  
  //   describe("burn", () => {
  //     it("allows the owner to burn a token", async () => {
  //       await karrot.burn(1, { from: addr1.address });
  //       // Перевіряємо, що токен був спалений
  //       const balance = await karrot.balanceOf(addr1.address);
  //       assert.equal(
  //         balance.toNumber(),
  //         2,
  //         "Balance should decrease after burning"
  //       );
  //     });
  
  //     it("prevents non-owners from burning a token", async () => {
  //       try {
  //         await karrot.burn(1, { from: addrs[1].address });
  //         assert.fail("Should have thrown an error");
  //       } catch (error) {
  //         assert.include(
  //           error.message,
  //           "Caller is not owner nor approved",
  //           "Error message should contain 'Caller is not owner nor approved'"
  //         );
  //       }
  //     });
  //   });
  
    describe("burnWithChildren", () => {
      it("allows the owner to burn a token with children", async () => {
        // Припустимо, що функція _burn враховує maxChilderBurns
        await karrot.burnWithChildren(1, 2, { from: addr1.address });
        const balance = await karrot.balanceOf(addr1.address);
        assert.equal(
          balance.toNumber(),
          2,
          "Balance should decrease after burning with children"
        );
      });
    });
  
    describe("burnBatch", () => {
      it("allows the owner to burn multiple tokens", async () => {
        await karrot.burnBatch([0, 2], { from: addr1.address });
        const balance = await karrot.balanceOf(addr1.address);
        assert.equal(
          balance.toNumber(),
          1,
          "Balance should decrease after batch burning"
        );
      });
    });
    */
});
