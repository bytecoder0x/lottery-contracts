// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC7401} from "@rmrk-team/evm-contracts/contracts/RMRK/nestable/IERC7401.sol";
import {RMRKNestable} from "@rmrk-team/evm-contracts/contracts/RMRK/nestable/RMRKNestable.sol";

import {KarrotErc7401Base} from "./base/KarrotErc7401Base.sol";

import {IKarrotPassport} from "./interface/IKarrotPassport.sol";
import {IKarrotOrganization} from "./interface/IKarrotOrganization.sol";
import {IKarrotCampaign} from "./interface/IKarrotCampaign.sol";

/**
 * @title KarrotOrganization contract
 * @notice The KarrotOrganization contract handles the creation and ownership of organization tokens in Karrot.
 * @dev KarrotOrganization allows minting new tokens for specific parent passport and ensures each passport can own only one organization token.
 */
contract KarrotOrganization is KarrotErc7401Base, IKarrotOrganization {
    /// @inheritdoc IKarrotOrganization
    address public passport;

    /// @inheritdoc IKarrotOrganization
    mapping(uint256 => uint256) public ownerToken;

    /**
     * @notice Constructor function to initialize the KarrotOrganization contract.
     * @param _defaultAdmin The address of the admin this contract.
     * @param _minter The address of the minter role.
     * @param _passport The address of the passport contract that is the parent of this organization.
     * @param _name The name of the contract.
     */
    constructor(
        address _defaultAdmin,
        address _minter,
        address _passport,
        string memory _name
    ) KarrotErc7401Base(_defaultAdmin, _minter, _name) {
        if (
            !IKarrotPassport(_passport).supportsInterface(
                type(IKarrotPassport).interfaceId
            )
        ) {
            revert InterfaceNotSupported();
        }

        passport = _passport;
    }

    /// @inheritdoc IKarrotOrganization
    function mintToPassport(
        uint256 parentId,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) returns (uint256 mintedTokenId) {
        if (ownerToken[parentId] != 0) {
            revert IncorrectCondition("Passport already has organization token");
        }

        mintedTokenId = ++_lastTokenId;
        _nestMint(passport, mintedTokenId, parentId, data);
        ownerToken[parentId] = mintedTokenId;
        _approve(msg.sender, mintedTokenId);
        emit OrganizationTokenMintedToPassport(mintedTokenId, msg.sender, parentId); 
    }

    function getUserOrganizationId(address _owner) external view returns (uint256) {
        uint256 passportId = IKarrotPassport(passport).ownerToken(_owner);
        return ownerToken[passportId];
    }

    /// @inheritdoc IERC7401
    function ownerOf(uint256 tokenId) public view override(RMRKNestable, IERC7401) returns (address owner_) {
        return super.ownerOf(tokenId);
    }

    /// @inheritdoc IERC165
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(KarrotErc7401Base, IERC165) returns (bool) {
        return interfaceId == type(IKarrotOrganization).interfaceId || 
            super.supportsInterface(interfaceId);
    }

    /**
     * @notice Performs check whether the child has IKarrotCampaign interface before accepting it.
     * @param childAddress The address of the child contract.
     * @dev Throws an error if the child contract does not support the IKarrotCampaign interface.
     */
    function _beforeAcceptChild(
        uint256,
        uint256,
        address childAddress,
        uint256
    ) internal virtual override {
        if (
            !IKarrotCampaign(childAddress).supportsInterface(
                type(IKarrotCampaign).interfaceId
            )
        ) {
            revert IncorrectCondition("Only campaign can be child of organization");
        }
    }
}
