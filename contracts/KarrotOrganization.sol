// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC7401} from "@rmrk-team/evm-contracts/contracts/RMRK/nestable/IERC7401.sol";
import {RMRKNestable} from "@rmrk-team/evm-contracts/contracts/RMRK/nestable/RMRKNestable.sol";

import {KarrotErc7401Base} from "./base/KarrotErc7401Base.sol";

import {IKarrotOrganization} from "./interface/IKarrotOrganization.sol";

contract KarrotOrganization is KarrotErc7401Base, IKarrotOrganization {
    
    mapping(address => uint256) public ownerToken;

    event OrganizationTokenMinted(address indexed to, uint256 indexed tokenId);

    constructor(address _defaultAdmin, address _minter, string memory _name) 
        KarrotErc7401Base(_defaultAdmin, _minter, _name) { }

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

    function ownerOf(uint256 tokenId) public view override(RMRKNestable, IERC7401) returns (address) {
        return super.ownerOf(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(KarrotErc7401Base, IERC165) returns (bool) {
        return interfaceId == type(IKarrotOrganization).interfaceId || 
            super.supportsInterface(interfaceId);
    }

    function _beforeAcceptChild(
        uint256,
        uint256,
        address childAddress,
        uint256
    ) internal virtual override {
        if (
            !IKarrotOrganization(childAddress).supportsInterface(
                type(IKarrotOrganization).interfaceId
            )
        ) {
            revert IncorrectCondition("Only campaign can be child of organization");
        }
    }
}
