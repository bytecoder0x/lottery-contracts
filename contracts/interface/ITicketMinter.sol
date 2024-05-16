// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IKarrotErrors} from "./IKarrotErrors.sol";

/**
 * @title Ticket Minter Interface
 * @notice Interface for the TicketMinter contract that responsible for minting tickets for campaigns.
 */
interface ITicketMinter is IERC165, IKarrotErrors {

    /**
     * @notice Mints tickets for multiple end owners in batches.
     * @param endOwners An array of end owners to whom tickets will be minted.
     * @param campaign The address of the campaign for which tickets are being minted.
     * @param ticketsCounts An array specifying the number of tickets to mint for each end owner.
     * @return ticketsTokenIds An array of arrays containing the token IDs of the minted tickets for each end owner.
     * @dev Reverts if the length of `endOwners` does not match the length of `ticketsCounts`.
     */
    function mintTicketsBatch(
        address[] memory endOwners,
        address campaign,
        uint256[] memory ticketsCounts
    ) external returns (uint256[][] memory ticketsTokenIds);

    /**
     * @notice Mints tickets for a specific end owner in a campaign.
     * @param endOwner The address of the end owner who will receive the tickets.
     * @param campaign The address of the campaign for which tickets are being minted.
     * @param ticketsCount The number of tickets to mint.
     * @return ticketsTokenIds An array containing the token IDs of the minted tickets.
     * @dev If any organization is found for the endOwner, we will mint it for him.
     * @dev If any campaign is found for the endOwner, we will mint it for him.
     */
    function mintTickets(
        address endOwner,
        address campaign,
        uint256 ticketsCount
    ) external returns (uint256[] memory ticketsTokenIds);
}
