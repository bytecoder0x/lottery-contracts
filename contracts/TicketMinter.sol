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

contract TicketMinter is
    ITicketMinter,
    AccessControl
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");

    IKarrotFactory public factory;
    
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

    function _getOrganizationFromFactory(
        address campaign
    ) private view returns (address) {
        address organization = factory.campaignOrganization(campaign);
        if (organization == address(0)) {
            revert IncorrectValue("No organization found for campaign");
        }
        return organization;
    }

    function _getTicketFromCampaign(
        address campaign
    ) private view returns (address) {
        address ticket = IKarrotCampaign(campaign).ticketsContract();
        // There is no need to check if ticket == address(0) because this is an impossible scenario.
        return ticket;
    }

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
