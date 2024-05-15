// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {RMRKNestable} from "@rmrk-team/evm-contracts/contracts/RMRK/nestable/RMRKNestable.sol";
import {IERC7401} from "@rmrk-team/evm-contracts/contracts/RMRK/nestable/IERC7401.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {IKarrotCampaign} from "./interface/IKarrotCampaign.sol";
import {IKarrotOrganization} from "./interface/IKarrotOrganization.sol";
import {IKarrotTicket} from "./interface/IKarrotTicket.sol";
import {IKarrotFactory} from "./interface/IKarrotFactory.sol";
import {ITicketMinter} from "./interface/ITicketMinter.sol";

/**
 * @title TicketMinter contract
 * @dev Manages the minting of tickets for campaigns and end owners.
 */
contract TicketMinter is
    ITicketMinter,
    AccessControl
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");

    IKarrotFactory public factory;

    /**
     * @notice Constructor function to initialize the TicketMinter contract.
     * and factory contract address.
     * @param _defaultAdmin The address of the default admin role.
     * @param _minter The address of the minter role.
     * @param _factory The address of the KarrotFactory contract.
     * @dev Reverts if the factory contract does not support their respective interfaces.
     */
    constructor(address _defaultAdmin, address _minter, address _factory) {
        if (
            !IKarrotFactory(_factory).supportsInterface(
                type(IKarrotFactory).interfaceId
            )
        ) {
            revert InterfaceNotSupported();
        }
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(MINTER_ROLE, _minter);
        factory = IKarrotFactory(_factory);
    }

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
    )
        public
        returns (uint256[][] memory ticketsTokenIds)
    {
        if(endOwners.length != ticketsCounts.length) {
            revert IncorrectValue("endOwners and ticketsCounts length mismatch");
        }
        ticketsTokenIds = new uint256[][](endOwners.length);
        for (uint i; i < endOwners.length; i++) {
            uint256[] memory userTicketsTokenIds = mintTickets(endOwners[i], campaign, ticketsCounts[i]);
            ticketsTokenIds[i] = userTicketsTokenIds;
        }
    }

    /**
     * @notice Mints tickets for a specific end owner in a campaign.
     * @param endOwner The address of the end owner who will receive the tickets.
     * @param campaign The address of the campaign for which tickets are being minted.
     * @param ticketsCount The number of tickets to mint.
     * @return ticketsTokenIds An array containing the token IDs of the minted tickets.
     * @dev If no organization is found for the endOwner, we will mint it for him.
     * @dev If no campaign is found for the endOwner, we will mint it for him.
     */
    function mintTickets(
        address endOwner,
        address campaign,
        uint256 ticketsCount
    )
        public
        onlyRole(MINTER_ROLE)
        returns (uint256[] memory ticketsTokenIds)
    {
        address organization = _getOrganizationFromFactory(campaign);
        address ticket = _getTicketFromCampaign(campaign);

        uint256 organizationTokenId = IKarrotOrganization(organization)
            .ownerToken(endOwner);

        if (organizationTokenId == 0) {
            organizationTokenId = IKarrotOrganization(organization).mintTo(
                endOwner,
                new bytes(0)
            );
        }

        IERC7401.Child[] memory organizationChildren = 
            IKarrotOrganization(organization).childrenOf(organizationTokenId);
        
        uint256 campaignTokenId = _getCampaignTokenId(
            organizationChildren,
            campaign
        );

        if (campaignTokenId == 0) {
            campaignTokenId = _mintCampaignToOrganizationAndAccept(
                campaign,
                organization,
                organizationTokenId
            );
        }

        ticketsTokenIds = _mintTicketToCampaignAndAccept(
            ticket,
            campaign,
            ticketsCount,
            campaignTokenId
        );
    }

    /**
     * @notice Retrieves the organization address associated with a campaign from the factory contract.
     * @param campaign The address of the campaign.
     * @return organization The address of the organization associated with the campaign.
     * @dev Reverts if no organization is found for the provided campaign.
     */
    function _getOrganizationFromFactory(
        address campaign
    ) private view returns (address) {
        address organization = factory.campaignOrganization(campaign);
        if (organization == address(0)) {
            revert IncorrectValue("No organization found for campaign");
        }
        return organization;
    }

    /**
     * @notice Retrieves the ticket contract address associated with a campaign.
     * @param campaign The address of the campaign.
     * @return ticket The address of the ticket contract associated with the campaign.
     */
    function _getTicketFromCampaign(
        address campaign
    ) private view returns (address) {
        address ticket = IKarrotCampaign(campaign).ticketsContract();
        // There is no need to check if ticket == address(0) because this is an impossible scenario.
        return ticket;
    }

    /**
     * @notice Finds the token ID a campaign.
     * @param organizationChildren The list of children tokens owned by the organization.
     * @param campaign The address of the campaign.
     * @return campaignTokenId The token ID associated with the campaign, or 0 if not found.
     */
    function _getCampaignTokenId(
        IERC7401.Child[] memory organizationChildren,
        address campaign
    ) private pure returns (uint256) {
        uint256 campaignTokenId;

        if (organizationChildren.length != 0) {
            for (uint256 i = 0; i < organizationChildren.length; i++) {
                if (organizationChildren[i].contractAddress == campaign) {
                    campaignTokenId = organizationChildren[i].tokenId;
                    break;
                }
            }
        }

        return campaignTokenId;
    }

    /**
     * @notice Mints the campaign token to the organization and accepts it as a child.
     * @param campaign The address of the campaign contract.
     * @param organization The address of the organization contract.
     * @param organizationTokenId The ID of the organization token.
     * @return campaignTokenId The token ID associated with the minted campaign.
     */
    function _mintCampaignToOrganizationAndAccept(
        address campaign,
        address organization,
        uint256 organizationTokenId
    ) private returns (uint256 campaignTokenId) {
        campaignTokenId = IKarrotCampaign(campaign).mintToOrganization(
            organizationTokenId,
            new bytes(0)
        );

        IERC7401.Child[] memory pendingChildren = IKarrotOrganization(organization)
            .pendingChildrenOf(organizationTokenId);

        IKarrotOrganization(organization).acceptChild(
            organizationTokenId,
            pendingChildren.length - 1,
            campaign,
            campaignTokenId
        );
    }

    /**
     * @notice Mints tickets to the campaign and accepts them as children.
     * @param ticket The address of the ticket contract.
     * @param campaign The address of the campaign contract.
     * @param ticketsCount The number of tickets to mint.
     * @param campaignTokenId The ID of the campaign token.
     * @return ticketsTokenIds An array containing the IDs of the minted tickets.
     */
    function _mintTicketToCampaignAndAccept(
        address ticket,
        address campaign,
        uint256 ticketsCount,
        uint256 campaignTokenId
    ) private returns (uint256[] memory) {
        uint256[] memory ticketsTokenIds = new uint256[](ticketsCount);

        IERC7401.Child[] memory pendingChildren = IKarrotCampaign(campaign)
            .pendingChildrenOf(campaignTokenId);

        for (uint256 i = 0; i < ticketsCount; i++) {
            uint256 ticketTokenId = IKarrotTicket(ticket).mintToCampaign(
                campaignTokenId,
                new bytes(0)
            );

            IKarrotCampaign(campaign).acceptChild(
                campaignTokenId,
                pendingChildren.length,
                ticket,
                ticketTokenId
            );
            ticketsTokenIds[i] = ticketTokenId;
        }
        return ticketsTokenIds;
    }

    /**
     * @notice Checks if the contract supports a given interface.
     * @param interfaceId The interface identifier.
     * @return A boolean indicating whether the contract supports the interface.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(AccessControl, IERC165)
        returns (bool)
    {
        return 
            type(ITicketMinter).interfaceId == interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
