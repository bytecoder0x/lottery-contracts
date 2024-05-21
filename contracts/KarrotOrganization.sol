// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC7401} from "@rmrk-team/evm-contracts/contracts/RMRK/nestable/IERC7401.sol";
import {RMRKNestable} from "@rmrk-team/evm-contracts/contracts/RMRK/nestable/RMRKNestable.sol";

import {KarrotErc7401Base} from "./base/KarrotErc7401Base.sol";

import {IKarrotOrganization} from "./interface/IKarrotOrganization.sol";
import {IKarrotCampaign} from "./interface/IKarrotCampaign.sol";

/**
 * @title KarrotOrganization contract
 * @notice The KarrotOrganization contract handles the creation and ownership of organization tokens in Karrot.
 * @dev KarrotOrganization allows minting new tokens for specific addresses and ensures each address can own only one organization token.
 */
contract KarrotOrganization is KarrotErc7401Base, IKarrotOrganization {
    /// @inheritdoc IKarrotOrganization
    mapping(address => uint256) public ownerToken;

    /**
     * @notice Constructor function to initialize the KarrotOrganization contract.
     * @param _defaultAdmin The address of the admin this contract.
     * @param _minter The address of the minter role.
     * @param _name The name of the contract.
     */
    constructor(address _defaultAdmin, address _minter, string memory _name) 
        KarrotErc7401Base(_defaultAdmin, _minter, _name) { }

    /// @inheritdoc IKarrotOrganization
    function mintTo(
        address to,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) returns (uint256) {
        if (ownerToken[to] != 0) {
            revert IncorrectCondition("Owner already has organization token");
        }
        _lastTokenId++;
        _safeMint(to, _lastTokenId, data);
        _approve(msg.sender, _lastTokenId);
        ownerToken[to] = _lastTokenId;
        
        emit OrganizationTokenMinted(to, _lastTokenId); 

        return _lastTokenId;
    }

    /// @inheritdoc IERC7401
    function ownerOf(uint256 tokenId) public view override(RMRKNestable, IERC7401) returns (address) {
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
