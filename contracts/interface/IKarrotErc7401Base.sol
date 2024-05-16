// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IKarrotErrors} from "./IKarrotErrors.sol";

/**
 * @title IKarrotErc7401Base
 * @notice Interface for IKarrotErc7401Base that defines provides basic ERC-7401 functionality.
 */
interface IKarrotErc7401Base is IKarrotErrors {
    /**
     * @notice Retrieves the total supply of tokens.
     * @return The total number of tokens minted.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Retrieves the name of the contract.
     * @return The name of the contract.
     */
    function name() external view returns (string memory);

    /**
     * @notice Checks if the spender is approved or the owner of the token.
     * @param spender The address being checked.
     * @param tokenId The ID of the token.
     * @return A boolean indicating whether the spender is approved or the owner of the token.
     */
    function isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool);
}