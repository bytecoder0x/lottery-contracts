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

      await expect(organization.connect(minter).mintTo(user1.address, []))
        .to.emit(organization, 'Transfer')
        .withArgs(ethers.constants.AddressZero, user1.address, 1);

      const tokenId = await organization.ownerToken(user1.address);
      expect(tokenId).to.be.eq(1);
      expect(await organization.ownerOf(tokenId)).to.equal(user1.address);
    });

    it("Should prevents minting to the owner who already has a token", async function () {
      await organization.connect(minter).mintTo(user1.address, []);
      await expect(organization.connect(minter).mintTo(user1.address, []))
        .to.be.revertedWith("IncorrectCondition");
    });
    it("Should prevents non-minter from minting tokens", async function () {
      const minterRole = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("MINTER"));
      await expect(organization.connect(user2).mintTo(user1.address, []))
        .to.be.revertedWith("AccessControl: account " + user2.address.toLowerCase() + " is missing role " + minterRole);
    });
    it("Should revokes minter role and prevents token minting", async function () {
      const minterRole = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("MINTER"));
      await organization.revokeRole(minterRole, minter.address);
      await expect(organization.connect(minter).mintTo(user2.address, []))
        .to.be.revertedWith("AccessControl: account " + minter.address.toLowerCase() + " is missing role " + minterRole);
    });
  });
  describe("KarrotErc7401Base", function () {
    it("Should checks if an address is approved or owner", async function () {
      await organization.connect(minter).mintTo(user1.address, []);

      expect(await organization.isApprovedOrOwner(user1.address, 1)).to.equal(true);
      expect(await organization.isApprovedOrOwner(user2.address, 1)).to.equal(false);
    });

    it("Should report total supply", async function () {
      await organization.connect(minter).mintTo(user1.address, []);
      await organization.connect(minter).mintTo(user2.address, []);

      expect(await organization.totalSupply()).to.equal(2);
    });
    it("Should support AccessControl interface", async function () {
      let functionSignature = [
        'hasRole(bytes32,address)',
        'getRoleAdmin(bytes32)',
        'grantRole(bytes32,address)',
        'revokeRole(bytes32,address)',
        'renounceRole(bytes32,address)'
      ];
      let interfaceID = BigInt(0);

      for (const signature of functionSignature) {
        const selector = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(signature)).slice(2, 10);
        interfaceID ^= BigInt('0x' + selector);
      }

      const interfaceIDHex = '0x' + interfaceID.toString(16).padStart(8, '0');
      expect(await organization.supportsInterface(interfaceIDHex)).to.equal(true);
    });

    it("Should support RMRKNestable interface", async function () {
      const functionSignatures = [
        'ownerOf(uint256)',
        'directOwnerOf(uint256)',
        'burn(uint256,uint256)',
        'addChild(uint256,uint256,bytes)',
        'acceptChild(uint256,uint256,address,uint256)',
        'rejectAllChildren(uint256,uint256)',
        'transferChild(uint256,address,uint256,uint256,address,uint256,bool,bytes)',
        'childrenOf(uint256)',
        'pendingChildrenOf(uint256)',
        'childOf(uint256,uint256)',
        'pendingChildOf(uint256,uint256)',
        'nestTransferFrom(address,address,uint256,uint256,bytes)'
      ];
      let interfaceID = BigInt(0);

      for (const signature of functionSignatures) {
        const selector = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(signature)).slice(2, 10);
        interfaceID ^= BigInt('0x' + selector);
      }

      const interfaceIDHex = '0x' + interfaceID.toString(16).padStart(8, '0');
      expect(await organization.supportsInterface(interfaceIDHex)).to.equal(true);
    });

    it("Should not support a random interface", async function () {
      //IERC1363 
      let interfaceID = BigInt(0);
      const functionSignatures = [
        'transferAndCall(address,uint256)',
        'transferAndCall(address,uint256,bytes)',
        'transferFromAndCall(address,address,uint256)',
        'transferFromAndCall(address,address,uint256,bytes)',
        'approveAndCall(address,uint256)',
        'approveAndCall(address,uint256,bytes)'
      ];

      for (const signature of functionSignatures) {
        const selector = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(signature)).slice(2, 10);
        interfaceID ^= BigInt('0x' + selector);
      }

      const interfaceIDHex = '0x' + interfaceID.toString(16).padStart(8, '0');
      expect(await organization.supportsInterface(interfaceIDHex)).to.equal(false);
    });
  });
});
