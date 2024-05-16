// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC7401} from "@rmrk-team/evm-contracts/contracts/RMRK/nestable/IERC7401.sol";
import {IKarrotErc7401Base} from "./IKarrotErc7401Base.sol";

/**
 * @title KarrotOrganization Interface
 * @notice Interface for the KarrotOrganization contract that handles the creation and ownership of organization tokens in Karrot
 */
interface IKarrotOrganization is IERC7401, IKarrotErc7401Base {
    /**
     * @notice Emitted when a new organization token is minted.
     * @param to The address to which the token is minted.
     * @param tokenId The ID of the minted token.
     */
    event OrganizationTokenMinted(address indexed to, uint256 indexed tokenId);

    /**
     * @notice Mints a new organization token and assigns it to the specified address.
     * @param to The address to which the token will be minted.
     * @param data Additional data to pass during minting.
     * @return The ID of the newly minted token.
     */
    function mintTo(address to, bytes memory data) external returns (uint256);

    /**
     * @notice Retrieves the token ID owned by the specified address.
     * @param owner The address of the token owner.
     * @return The ID of the token owned by the specified address.
     */
    function ownerToken(address owner) external view returns (uint256);
}