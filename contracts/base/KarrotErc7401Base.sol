// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {RMRKNestable} from "@rmrk-team/evm-contracts/contracts/RMRK/nestable/RMRKNestable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IKarrotErc7401Base} from "../interface/IKarrotErc7401Base.sol";

/**
 * @title KarrotErc7401Base
 * @notice Abstract contract defines provides basic ERC-7401 functionality.
 * @dev KarrotErc7401Base contract must be inherited by others.
 */
abstract contract KarrotErc7401Base is RMRKNestable, AccessControl, IKarrotErc7401Base {
    /// @notice Сonstant that contains the MINTER role. Owner of this role can mint organization, campaigns and tickets.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");
    /// @notice Total amount of minted tokens. ID of the last ticket.
    uint256 internal _lastTokenId;
    /// @notice Name of the contract.
    string public name;

    /**
     * @notice Constructor function to initialize the KarrotErc7401Base contract.
     * @param _defaultAdmin The address of the admin contract that inherits this contract.
     * @param _minter The address of the minter.
     * @param _name The name of the contract.
     */
    constructor(address _defaultAdmin, address _minter, string memory _name) {
        name = _name;
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(MINTER_ROLE, _minter);
    }

    /**
     * @notice Checks if the spender is approved or the owner of the token.
     * @param spender The address being checked.
     * @param tokenId The ID of the token.
     * @return A boolean indicating whether the spender is approved or the owner of the token.
     */
    function isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool) {
        return _isApprovedOrOwner(spender, tokenId);
    }

    /**
     * @notice Retrieves the total supply of tokens.
     * @return The total number of tokens minted.
     */
    function totalSupply() external view returns (uint256) {
        return _lastTokenId;
    }

    /**
     * @notice Checks if the contract supports a given interface.
     * @param interfaceId The interface identifier.
     * @return A boolean indicating whether the contract supports the interface.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(AccessControl, RMRKNestable) returns (bool) {
        return  
            AccessControl.supportsInterface(interfaceId) || 
            RMRKNestable.supportsInterface(interfaceId);
    }
}