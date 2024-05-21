// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {KarrotTicket} from "../KarrotTicket.sol";

/**
 * @title TicketDeployerLibrary
 * @notice Library for deploying ticket contracts.
 * @dev This library provides a function to deploy ticket contracts with specific parameters.
 */
library TicketDeployerLibrary {
    /**
     * @notice Deploys a new ticket contract.
     * @param defaultAdmin The address of the admin for the contract.
     * @param minterContract The address that can mint organizations, campaigns and tickets.
     * @param ticketsCount The amount of ticket contracts deployed.
     * @param campaign The address of the associated campaign contract.
     * @param campaignName The name of the campaign.
     * @return The address of the newly deployed ticket contract.
     */
    function deployTicket(
        address defaultAdmin,
        address minterContract,
        uint256 ticketsCount,
        address campaign,
        string memory campaignName
    ) external returns (address) {
        return address(
            new KarrotTicket{salt: keccak256(abi.encodePacked(ticketsCount))}(
                defaultAdmin,
                minterContract,
                campaign,
                string(abi.encodePacked(campaignName, " Tickets"))
            )
        );
    }
}