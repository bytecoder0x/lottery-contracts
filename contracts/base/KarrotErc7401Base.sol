// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {RMRKNestable} from "@rmrk-team/evm-contracts/contracts/RMRK/nestable/RMRKNestable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IKarrotErc7401Base} from "../interface/IKarrotErc7401Base.sol";

abstract contract KarrotErc7401Base is RMRKNestable, AccessControl, IKarrotErc7401Base {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");
    uint256 internal _lastTokenId;
    string public name;

    constructor(address _defaultAdmin, address _minter, string memory _name) {
        name = _name;
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(MINTER_ROLE, _minter);
    }

    function isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool) {
        return _isApprovedOrOwner(spender, tokenId);
    }

    function totalSupply() external view returns (uint256) {
        return _lastTokenId;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(AccessControl, RMRKNestable) returns (bool) {
        return  
            AccessControl.supportsInterface(interfaceId) || 
            RMRKNestable.supportsInterface(interfaceId);
    }
}