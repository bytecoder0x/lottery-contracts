// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC7401} from "@rmrk-team/evm-contracts/contracts/RMRK/nestable/IERC7401.sol";
import {RMRKNestable} from "@rmrk-team/evm-contracts/contracts/RMRK/nestable/RMRKNestable.sol";

import {KarrotCheckMintTime} from "./base/KarrotCheckMintTime.sol";
import {KarrotErc7401Base} from "./base/KarrotErc7401Base.sol";

import {IKarrotOrganization} from "./interface/IKarrotOrganization.sol";
import {ILottery} from "./interface/ILottery.sol";
import {IKarrotTicket} from "./interface/IKarrotTicket.sol";
import {IKarrotCampaign} from "./interface/IKarrotCampaign.sol";

contract KarrotCampaign is 
    KarrotErc7401Base,
    KarrotCheckMintTime,
    IKarrotCampaign
{
    bytes32 public constant LOWER_ADMIN_ROLE = keccak256("LOWER_ADMIN");

    address public lottery;
    address public organization;
    address public ticketsContract;

    mapping(uint256 => uint256) public ownerToken;
    mapping(uint256 => uint256) public organizationToCampaign;

    /**
     * @notice Constructor function to initialize the KarrotCampaign contract.
     * @param _defaultAdmin The address of the default admin role.
     * @param _lowerAdmin The address of the lower admin role.
     * @param _minter The address of the minter role.
     * @param _organization The address of the KarrotOrganization contract.
     * @param _lottery The address of the Lottery contract.
     * @param _name The name of the contract.
     * @dev Reverts if the organization or lottery contracts do not support their respective interfaces.
     */
    constructor(
        address _defaultAdmin,
        address _lowerAdmin,
        address _minter,
        address _organization,
        address _lottery,
        string memory _name
    ) KarrotErc7401Base(_defaultAdmin, _minter, _name) {
        if (
            !IKarrotOrganization(_organization).supportsInterface(
                type(IKarrotOrganization).interfaceId
            ) ||
            !ILottery(_lottery).supportsInterface(type(ILottery).interfaceId)
        ) {
            revert InterfaceNotSupported();
        }

        organization = _organization;
        lottery = _lottery;

        _setupRole(LOWER_ADMIN_ROLE, _lowerAdmin);
    }

    /**
     * @notice Mints a new campaign token to the specified organization.
     * @param parentId The ID of the parent organization.
     * @param data Additional data to include in the minted token.
     * @return mintedTokenId The ID of the newly minted token.
     * @dev Reverts if the parent organization already has the campaign.
     */
    function mintToOrganization(
        uint256 parentId,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) notBeforeMintClosed returns (uint256 mintedTokenId) {
        if (organizationToCampaign[parentId] != 0) {
            revert IncorrectCondition("Organization already has this campaign");
        }

        mintedTokenId = ++_lastTokenId;
        _nestMint(organization, mintedTokenId, parentId, data);
        organizationToCampaign[parentId] = mintedTokenId;
        ownerToken[parentId] = mintedTokenId;
        _approve(msg.sender, mintedTokenId);
        emit CampaignTokenMintedToOrganization(mintedTokenId, msg.sender, parentId);
    }

    /**
     * @notice Sets the ticket contract address.
     * @param _ticketsContract The address of the ticket contract to set.
     * @dev Reverts if the sender does not have the required admin role.
     * @dev Reverts if the ticket contract does not support the IKarrotTicket interface.
     */
    function setTicketContract(
        address _ticketsContract
    ) public {
        if (!hasRole(LOWER_ADMIN_ROLE, msg.sender) && !hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert MissingAdminRole(msg.sender);
        }
        if (
            !IKarrotTicket(_ticketsContract).supportsInterface(
                type(IKarrotTicket).interfaceId
            )
        ) {
            revert InterfaceNotSupported();
        }
        emit TicketContractSet(_ticketsContract, msg.sender);

        ticketsContract = _ticketsContract;
    }

    /**
     * @notice Burns the user's ticket for the current campaign.
     * @dev Retrieves the campaign ID for the user and calls _burnTicket.
     */
    function burnTicket() external {
        uint campaignId = _getUserCampaignId();
        _burnTicket(campaignId);
    }

    /**
     * @notice Burns a batch of tickets for the current campaign.
     * @param amountOfTicketsToBurn The number of tickets to burn.
     * @dev Retrieves the campaign ID for the user and calls burnTicketBatch with the campaign ID and specified amount.
     */
    function burnTicketBatch(uint256 amountOfTicketsToBurn) public {
        uint campaignId = _getUserCampaignId();
        burnTicketBatch(campaignId, amountOfTicketsToBurn);
    }

    /**
     * @notice Burns the user's ticket for the specified campaign.
     * @param campaignId The ID of the campaign to burn the ticket for.
     * @dev Calls _burnTicket with the specified campaign ID.
     */
    function burnTicket(uint campaignId) public {
        _burnTicket(campaignId);
    }

    /**
     * @notice Burns a batch of tickets for the specified campaign.
     * @param campaignId The ID of the campaign to burn tickets for.
     * @param amountOfTicketsToBurn The number of tickets to burn.
     * @dev Reverts if the specified amount exceeds the available tickets for the campaign.
     * @dev Burns the specified number of tickets for the campaign.
     * @dev Note: This check doesn't guarantee 100% that the user is trying to burn the correct amount of tickets,
     * as _activeChildren may contain non-ticket items in case of manual child acceptance.
     * In such cases, the contract reverts with panic code 0x11, which is the desired behavior.
     */
    function burnTicketBatch(uint campaignId, uint256 amountOfTicketsToBurn) public {
        if (amountOfTicketsToBurn > _activeChildren[campaignId].length) {
            revert IncorrectValue("Not enough tickets to burn");
        }
        for(uint i; i < amountOfTicketsToBurn; i++) {
            _burnTicket(campaignId);
        }
    }

    /**
     * @notice Gets the owner of the specified token ID.
     * @param tokenId The ID of the token.
     * @return The address of the owner of the token.
     */
    function ownerOf(
        uint256 tokenId
    ) public view override(RMRKNestable, IERC7401) returns (address) {
        return super.ownerOf(tokenId);
    }

    /**
     * @notice Retrieves the address of the lottery contract.
     * @return The address of the lottery contract.
     */
    function getLotteryContract() public view override returns (address) {
        return lottery;
    }

    /**
     * @notice Checks if the contract supports a given interface.
     * @param interfaceId The interface identifier.
     * @return A boolean indicating whether the contract supports the interface.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(KarrotErc7401Base, IERC165) returns (bool) {
        return interfaceId == type(IKarrotCampaign).interfaceId || 
            super.supportsInterface(interfaceId);
    }

    /**
     * @notice Performs checks before accepting a child contract.
     * @param childAddress The address of the child contract.
     * @dev Ensures that only the ticket contract can be accepted as a child of the campaign.
     */
    function _beforeAcceptChild(
        uint256,
        uint256,
        address childAddress,
        uint256
    ) internal virtual override {
        if (childAddress != ticketsContract)
            revert IncorrectCondition("Only ticket can be child of campaign");
    }

    /**
     * @notice Burns a ticket associated with the given campaign ID.
     * @param campaignId The ID of the campaign owning the ticket to be burned.
     * @dev Reverts if the caller is not approved or the owner of the ticket.
     * @dev Transfers the burning ticket to the owner of the last ticket ID.
     * @dev Transfers the last ticket ID to the burning campaign.
     * @dev Burns the last ticket ID.
     */
    function _burnTicket(uint256 campaignId) internal {
        if(!_isApprovedOrOwner(msg.sender, campaignId)) {
            revert IncorrectCondition("User is not aprroved or owner");
        }

        Child[] storage campaignTickets = _activeChildren[campaignId];
        uint256 ticketIdToBurn = campaignTickets[campaignTickets.length - 1].tokenId;
        uint lastTiketId = IKarrotTicket(ticketsContract).totalSupply(); //last token id == total supply

        uint lastTiketOwnerId;
        if (lastTiketId != ticketIdToBurn) { //meaning that we are burning not the last ticket id
            (, lastTiketOwnerId, ) = IKarrotTicket(ticketsContract).directOwnerOf(lastTiketId);
        } else {
            lastTiketOwnerId = campaignId;
        }

        uint256 lastTiketIndexInChildren = 
            _findTiketIndex(lastTiketId, _activeChildren[lastTiketOwnerId]);

        _transferChild(
            campaignId,
            address(this),
            lastTiketOwnerId,
            campaignTickets.length - 1, 
            ticketsContract,
            ticketIdToBurn,
            false,
            new bytes(0)
        );
        _acceptChild(
            lastTiketOwnerId,
            _pendingChildren[lastTiketOwnerId].length - 1,
            ticketsContract,
            ticketIdToBurn
        );

        _transferChild(
            lastTiketOwnerId,
            address(this),
            campaignId,
            lastTiketIndexInChildren,
            ticketsContract,
            lastTiketId,
            false,
            new bytes(0)
        );

        _pendingChildren[campaignId].pop();
 
        IKarrotTicket(ticketsContract).burnLastTicket();
    }

    /**
     * @notice Retrieves the campaign ID of the caller's organization.
     * @return The ID of the campaign owned by the caller's organization.
     * @dev Reverts if the caller is not the owner of any organization.
     */
    function _getUserCampaignId() private view returns (uint256) {
        uint organizationId = IKarrotOrganization(organization).ownerToken(msg.sender);
        if (organizationId == 0) revert IncorrectValue("User is not an owner of any organization");
        return ownerToken[organizationId];
    }

    /**
     * @notice Finds the index of a ticket in the provided list of children.
     * @param ticketId The ID of the ticket to find.
     * @param tickets The list of children containing tickets.
     * @return The index of the ticket in the list.
     */
    function _findTiketIndex(uint256 ticketId, Child[] memory tickets) private view returns (uint256) {
        for (uint256 i = 0; i < tickets.length; i++) {
            if (tickets[i].tokenId == ticketId && tickets[i].contractAddress == ticketsContract) {
                return i;
            }
        }
        //there is no way to get here as the last ticket id must be in the children of the campaign
    }
}
