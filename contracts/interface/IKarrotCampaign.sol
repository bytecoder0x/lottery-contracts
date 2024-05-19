// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC7401} from "@rmrk-team/evm-contracts/contracts/RMRK/nestable/IERC7401.sol";
import {IKarrotErc7401Base} from "./IKarrotErc7401Base.sol";

/**
 * @title KarrotCampaign contract
 * @notice The KarrotCampaign contract manages the creation and ownership of campaign tokens within the Karrot platform.
 * @dev KarrotCampaign allows minting campaign tokens for specific organizations, setting ticket contracts,
 * burning tickets, and retrieving campaign-related information.
 */
interface IKarrotCampaign is IERC7401, IKarrotErc7401Base {
    /**
     * @notice Error emitted when an account lacks admin role permissions.
     * @param caller The address of the account that attempted an action without sufficient permissions.
     */
    error MissingAdminRole(address caller);

    /**
     * @notice Emitted when a campaign token is minted to parent organization.
     * @param tokenId The ID of the newly minted campaign token.
     * @param minter The address that minted the campaign token.
     * @param organizationTokenParentId The ID of the parent organization associated with the campaign token.
     */
    event CampaignTokenMintedToOrganization(uint256 indexed tokenId, address indexed minter, uint256 indexed organizationTokenParentId);
    /**
     * @notice Emitted when the ticket contract address is set for the campaign.
     * @param ticketsContract The address of the ticket contract.
     * @param setter The address that set the ticket contract.
     */
    event TicketContractSet(address indexed ticketsContract, address indexed setter);

    /**
     * @notice Retrieves the address of the parent organization contract.
     * @return The address of the organization contract that is the parent of this campaign.
     */
    function organization() external view returns (address); 

    /**
     * @notice Retrieves the address of the lottery contract.
     * @return The address of the lottery contract in that the campaign participates.
     */
    function lottery() external view returns (address);

    /**
     * @notice Retrieves the address of the ticket contract.
     * @return The address of the ticket contract associated with the campaign token.
     */
    function ticketsContract() external view returns (address);

    /**
     * @notice Returns the token ID of the specified owner.
     * @param tokenId The ID of the token.
     * @return The organization token ID associated with the specified token ID.
     */
    function ownerToken(uint256 tokenId) external view returns (uint256);

    /**
     * @notice Retrieves the associated campaign ID for the given organization ID.
     * @param organizationId The ID of the organization.
     * @return The associated campaign ID.
     * @dev Used to prevent duplicate campaign tokens within organizations.
     */
    function organizationToCampaign(uint256 organizationId) external view returns (uint256);

    /**
     * @notice Mints a new campaign token to the specified parent organization.
     * @param parentId The ID of the parent organization.
     * @param data Additional data to include in the minted token.
     * @return mintedTokenId The ID of the newly minted token.
     * @dev Reverts if the parent organization already has the campaign token.
     */
    function mintToOrganization(uint256 parentId, bytes memory data) external returns (uint256);

    /**
     * @notice Sets the ticket contract address.
     * @param _ticketContract The address of the ticket contract to set.
     * @dev Reverts if the sender does not have the required admin role.
     * @dev Reverts if the ticket contract does not support the IKarrotTicket interface.
     */
    function setTicketContract(address _ticketContract) external;

    /**
     * @notice Burns the user's ticket for the current campaign.
     * @dev Retrieves the campaign ID for the user and calls _burnTicket.
     * @dev Transfers the burning ticket to the owner of the last ticket ID.
     * @dev Transfers the last ticket ID to the burning campaign.
     * @dev The owner of the last ticket loses it, but received the burning ticket.
     * @dev We swap the ticket to be burned with the last ticket, then burn the last one.
     * Due this swap approach user's ticket ID(s) may change and it's expected behaviour,
     * since it does not change the chance of winning lottery
     */
    function burnTicket() external;
    
    /**
     * @notice Burns the user's ticket for the specified campaign.
     * @param campaignId The ID of the campaign to burn the ticket for.
     */
    function burnTicket(uint campaignId) external;
    
    /**
     * @notice Burns a batch of tickets for the current campaign.
     * @param amountOfTicketsToBurn The number of tickets to burn.
     */
    function burnTicketBatch(uint256 amountOfTicketsToBurn) external;
    
    /**
     * @notice Burns a batch of tickets for the specified campaign.
     * @param campaignId The ID of the campaign to burn tickets for.
     * @param amountOfTicketsToBurn The number of tickets to burn.
     * @dev Reverts if the specified amount exceeds the available campaign tickets.
     */
    function burnTicketBatch(uint campaignId, uint256 amountOfTicketsToBurn) external;

    /**
     * @notice Retrieves the campaign ID associated with a specific user.
     * @param _owner The address of the user whose campaign ID is to be retrieved.
     * @return The campaign ID associated with the specified user.
     */
    function getUserCampaignId(address _owner) external view returns (uint256);
}