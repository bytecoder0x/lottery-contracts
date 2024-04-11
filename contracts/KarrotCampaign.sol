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
    ) public onlyRole(MINTER_ROLE) notBeforeMintClosed returns (uint256) {
        _lastTokenId++;
        _nestMint(organization, _lastTokenId, parentId, data);
        _approve(msg.sender, _lastTokenId);
        emit CampaignTokenMintedToOrganization(_lastTokenId, msg.sender, parentId);
        return _lastTokenId;
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
}
