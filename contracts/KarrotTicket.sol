// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IERC7401} from "@rmrk-team/evm-contracts/contracts/RMRK/nestable/IERC7401.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {RMRKNestable} from "@rmrk-team/evm-contracts/contracts/RMRK/nestable/RMRKNestable.sol";

import {KarrotErc7401Base} from "./base/KarrotErc7401Base.sol";
import {KarrotCheckMintTime} from "./base/KarrotCheckMintTime.sol";

import {IKarrotCampaign} from "./interface/IKarrotCampaign.sol";
import {IKarrotTicket} from "./interface/IKarrotTicket.sol";

/**
 * @title KarrotTicket
 * @notice The KarrotTicket contract manages the minting and burning of ticket within the Karrot platform.
 * @dev KarrotTicket contract allows minting tokens to specific campaigns, burning the last minted token,
 * and retrieving contract-related information.
 */
contract KarrotTicket is KarrotErc7401Base, KarrotCheckMintTime, IKarrotTicket {
    /// @inheritdoc IKarrotTicket
    address public campaign;

    /**
     * @notice Constructor function to initialize the KarrotTicket contract.
     * @param _defaultAdmin The address of the admin this contract.
     * @param _minter The address of the minter role.
     * @param _campaign The address of the KarrotCampaign contract.
     * @param _name The name of the contract.
     * @dev Reverts if the campaign contract does not support their respective interfaces.
     */
    constructor(
        address _defaultAdmin,
        address _minter,
        address _campaign,
        string memory _name
    ) KarrotErc7401Base(_defaultAdmin, _minter, _name) {
        if (
            !IKarrotCampaign(_campaign).supportsInterface(
                type(IKarrotCampaign).interfaceId
            )
        ) {
            revert InterfaceNotSupported();
        }
        campaign = _campaign;
    }

    /// @inheritdoc IKarrotTicket
    function mintToCampaign(
        uint256 parentId,
        bytes memory data
    )
        public
        onlyRole(MINTER_ROLE)
        notBeforeMintClosed
        returns (uint256)
    {
        _mintToCampaign(parentId, data);
        
        return _lastTokenId;
    }

    /// @inheritdoc IKarrotTicket
    function mintToCampaignBatch(
        uint256 tokenCount,
        uint256 parentId,
        bytes memory data
    )
        public
        onlyRole(MINTER_ROLE)
        notBeforeMintClosed
        returns (uint256[] memory)
    {
        uint256[] memory tokenIds = new uint256[](tokenCount);

        for (uint256 i; i < tokenCount; i++) {
            _mintToCampaign(parentId, data);
            tokenIds[i] = _lastTokenId;
        }
        return tokenIds;
    }
    
    /// @inheritdoc IKarrotTicket
    function burnLastTicket() external {
        if(msg.sender != campaign){
            revert IncorrectValue("Only Campaign can burn tickets");
        }
        uint previousLastTiketId = _lastTokenId;
        _burn(previousLastTiketId, 0);
        emit TicketBurned(previousLastTiketId);
        _lastTokenId--;
    }

    /// @inheritdoc KarrotCheckMintTime
    function getLotteryContract() public view override returns (address) {
        return IKarrotCampaign(campaign).lottery();
    }

    /// @inheritdoc IERC7401
    function ownerOf(
        uint256 tokenId
    ) public view override(RMRKNestable, IERC7401) returns (address) {
        return super.ownerOf(tokenId);
    }

    /// @inheritdoc IKarrotTicket
    function getOrganisation() public view returns (address) {
        return IKarrotCampaign(campaign).organization();
    }

    /// @inheritdoc IKarrotTicket
    function getUserTicketIds(address _owner) view external returns (uint256[] memory){
        uint256 campaignId = IKarrotCampaign(campaign).getUserCampaignId(_owner);
        // code campaign contract ensures that a campaign can only have tickets in its children
        Child[] memory tickets = IKarrotCampaign(campaign).childrenOf(campaignId);

        uint256[] memory tiketIds = new uint256[](tickets.length);

        for (uint256 i; i < tickets.length; i++) {
            tiketIds[i] = tickets[i].tokenId;
        }

        return tiketIds;
    }

    /// @inheritdoc IERC165
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(KarrotErc7401Base, IERC165) returns (bool) {
        return
            interfaceId == type(IKarrotTicket).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @notice Mints a new token and assigns it to the specified parent campaign.
     * @param parentId The ID of the parent campaign.
     * @param data Additional data to include in the minted token.
     */
    function _mintToCampaign(uint parentId, bytes memory data) internal {
        _lastTokenId++;
        _nestMint(campaign, _lastTokenId, parentId, data);
        _approve(msg.sender, _lastTokenId);

        emit TicketMintedToCampaign(_lastTokenId, parentId, campaign);

    }
}
