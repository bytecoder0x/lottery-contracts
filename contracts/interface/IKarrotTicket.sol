// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC7401} from "@rmrk-team/evm-contracts/contracts/RMRK/nestable/IERC7401.sol";
import {IKarrotErc7401Base} from "./IKarrotErc7401Base.sol";

/**
 * @title KarrotTicket Interface
 * @notice Interface for the KarrotTicket contract that managing ticket minting and burning within the Karrot platform.
 */
interface IKarrotTicket is IERC7401, IKarrotErc7401Base {

    /**
     * @notice Emitted when a ticket is minted to a parent campaign.
     * @param tokenId The ID of the minted ticket.
     * @param parentId The ID of the parent campaign.
     * @param campaignAddress The address of the campaign to which the ticket is minted.
     */
    event TicketMintedToCampaign(uint256 indexed tokenId, uint256 indexed parentId, address indexed campaignAddress);
    /**
     * @notice Emitted when a ticket is burned.
     * @param tokenId The ID of the burned ticket.
     */
    event TicketBurned(uint256 indexed tokenId);

    /**
     * @notice Mints a new ticket to the specified parent campaign.
     * @param parentId The ID of the parent campaign.
     * @param data Additional data to include in the minted ticket.
     * @return The ID of the last minted ticket.
     */
    function mintToCampaign(uint256 parentId, bytes memory data) external returns (uint256);

    /**
     * @notice Mints multiple tickets to the specified parent campaign.
     * @param tokenCount The number of tickets to mint.
     * @param parentId The ID of the parent campaign.
     * @param data Additional data to include in the minted tickets.
     * @return An array containing the IDs of the minted tickets.
     */
    function mintToCampaignBatch(
        uint256 tokenCount,
        uint256 parentId,
        bytes memory data
    ) external returns (uint256[] memory);

    /**
     * @notice Retrieves the ticket IDs owned by a specific user.
     * @param _owner The address of the user whose ticket IDs are to be retrieved.
     * @return An array containing the IDs of the tickets owned by the specified user.
     */
    function getUserTicketIds(address _owner) external view returns (uint256[] memory);
    /**
     * @notice Retrieves the address of the parent organization associated with the parent campaign.
     * @return The address of the organization.
     */
    function getOrganisation() external view returns (address);
    /**
     * @notice Retrieves the address of the parent campaign associated with the ticket.
     * @return The address of the campaign.
     */
    function campaign() external view returns (address);
    /**
     * @notice Burns the last minted ticket.
     * @dev After swapping the ticket to be burned with the last ticket in KarrotCampaign,
     * we burn the last ticket using this function.
     */
    function burnLastTicket() external;
}
