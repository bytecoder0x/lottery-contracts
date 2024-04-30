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

    function burnTicket() external {
        uint campaignId = _getUserCampaignId();
        _burnTicket(campaignId);
    }

    function burnTicketBatch(uint256 amountOfTicketsToBurn) public {
        uint campaignId = _getUserCampaignId();
        burnTicketBatch(campaignId, amountOfTicketsToBurn);
    }

    function burnTicket(uint campaignId) public {
        _burnTicket(campaignId);
    }

    function burnTicketBatch(uint campaignId, uint256 amountOfTicketsToBurn) public {
        //this check doesn't give 100% guarantee that the user is trying to burn the correct amount of tickets
        //as _activeChildren may have not only tickets in case of manual child accepting.
        //If this scenario happens the contract will revert with panic code 0x11 
        //that is also a desired behaviour
        if (amountOfTicketsToBurn > _activeChildren[campaignId].length) {
            revert IncorrectValue("Not enough tickets to burn");
        }
        for(uint i; i < amountOfTicketsToBurn; i++) {
            _burnTicket(campaignId);
        }
    }

    function ownerOf(
        uint256 tokenId
    ) public view override(RMRKNestable, IERC7401) returns (address) {
        return super.ownerOf(tokenId);
    }

    function getLotteryContract() public view override returns (address) {
        return lottery;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(KarrotErc7401Base, IERC165) returns (bool) {
        return interfaceId == type(IKarrotCampaign).interfaceId || 
            super.supportsInterface(interfaceId);
    }

    function _beforeAcceptChild(
        uint256,
        uint256,
        address childAddress,
        uint256
    ) internal virtual override {
        if (childAddress != ticketsContract)
            revert IncorrectCondition("Only ticket can be child of campaign");
    }


    function _burnTicket(uint256 campaignId) internal {
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

        //transfer the burning ticket from children of the burning campaign to the owner of the last ticket id
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

        //transfer the last ticket id from the owner of the last ticket id to the burning campaign
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

    function _getUserCampaignId() private view returns (uint256) {
        uint organizationId = IKarrotOrganization(organization).ownerToken(msg.sender);
        if (organizationId == 0) revert IncorrectValue("User is not an owner of any organization");
        return ownerToken[organizationId];
    }

    function _findTiketIndex(uint256 ticketId, Child[] memory tickets) private view returns (uint256) {
        for (uint256 i = 0; i < tickets.length; i++) {
            if (tickets[i].tokenId == ticketId && tickets[i].contractAddress == ticketsContract) {
                return i;
            }
        }
        //there is no way to get here as the last ticket id must be in the children of the campaign
    }
}
