// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC7401} from "@rmrk-team/evm-contracts/contracts/RMRK/nestable/IERC7401.sol";
import {RMRKNestable} from "@rmrk-team/evm-contracts/contracts/RMRK/nestable/RMRKNestable.sol";

import {KarrotErc7401Base} from "./base/KarrotErc7401Base.sol";

import {IKarrotOrganization} from "./interface/IKarrotOrganization.sol";
import {IKarrotCampaign} from "./interface/IKarrotCampaign.sol";

contract KarrotOrganization is KarrotErc7401Base, IKarrotOrganization {
    
    mapping(address => uint256) public ownerToken;

    event OrganizationTokenMinted(address indexed to, uint256 indexed tokenId);

    constructor(address _defaultAdmin, address _minter, string memory _name) 
        KarrotErc7401Base(_defaultAdmin, _minter, _name) { }

    /**
     * @notice Mints a new organization token to the specified address.
     * @param to The address to mint the token to.
     * @param data Additional data to include in the minted token.
     * @return The ID of the newly minted token.
     * @dev Reverts if the recipient already owns an organization token.
     */
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

    /**
     * @notice Retrieves the owner of the specified token ID.
     * @param tokenId The ID of the token to query.
     * @return The address of the owner of the token.
     */
    function ownerOf(uint256 tokenId) public view override(RMRKNestable, IERC7401) returns (address) {
        return super.ownerOf(tokenId);
    }

    /**
     * @notice Checks if the contract supports a given interface.
     * @param interfaceId The interface identifier.
     * @return A boolean indicating whether the contract supports the interface.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(KarrotErc7401Base, IERC165) returns (bool) {
        return interfaceId == type(IKarrotOrganization).interfaceId || 
            super.supportsInterface(interfaceId);
    }

    /**
     * @notice Performs operations before accepting a child contract.
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
