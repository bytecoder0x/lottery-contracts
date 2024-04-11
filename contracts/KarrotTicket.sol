// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IERC7401} from "@rmrk-team/evm-contracts/contracts/RMRK/nestable/IERC7401.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {RMRKNestable} from "@rmrk-team/evm-contracts/contracts/RMRK/nestable/RMRKNestable.sol";

import {KarrotErc7401Base} from "./base/KarrotErc7401Base.sol";
import {KarrotCheckMintTime} from "./base/KarrotCheckMintTime.sol";

import {IKarrotCampaign} from "./interface/IKarrotCampaign.sol";
import {IKarrotTicket} from "./interface/IKarrotTicket.sol";

contract KarrotTicket is KarrotErc7401Base, KarrotCheckMintTime, IKarrotTicket {
    address public campaign;

    event TicketMintedToCampaign(uint256 indexed tokenId, uint256 indexed parentId, address indexed campaignAddress);
    event TicketBatchMintedToCampaign(uint256[] tokenIds, uint256 indexed parentId, address indexed campaignAddress);
    event TicketBurned(uint256 indexed tokenId);

    modifier notTokenIdLowerLastTokenId(uint256 tokenId) {
        if (tokenId > _lastTokenId)
            revert IncorrectValue("Cannot burn token with id higher than last token id");
        _;
    }

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

    function mintToCampaign(
        uint256 parentId,
        bytes memory data
    )
        public
        onlyRole(MINTER_ROLE)
        notBeforeMintClosed
        returns (uint256)
    {
        _lastTokenId++;
        _nestMint(campaign, _lastTokenId, parentId, data);
        _approve(msg.sender, _lastTokenId);

        emit TicketMintedToCampaign(_lastTokenId, parentId, campaign);

        return _lastTokenId;
    }

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
            _lastTokenId++;
            _nestMint(campaign, _lastTokenId, parentId, data);
            _approve(msg.sender, _lastTokenId);
            tokenIds[i] = _lastTokenId;
        }

        emit TicketBatchMintedToCampaign(tokenIds, parentId, campaign);

        return tokenIds;
    }

    function burnBatch(uint256[] memory tokenIds) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _burnTicket(tokenIds[i]);
            emit TicketBurned(tokenIds[i]);

        }
    }

    function getLotteryContract() public view override returns (address) {
        return IKarrotCampaign(campaign).lottery();
    }

    function ownerOf(
        uint256 tokenId
    ) public view override(RMRKNestable, IERC7401) returns (address) {
        return super.ownerOf(tokenId);
    }

    function getOrganisation() public view returns (address) {
        return IKarrotCampaign(campaign).organization();
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(KarrotErc7401Base, IERC165) returns (bool) {
        return
            interfaceId == type(IKarrotTicket).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _burnTicket(
        uint256 tokenId
    ) internal onlyApprovedOrDirectOwner(tokenId) {
        (
            address burningTokenOwner,
            uint256 burningTokenParentId,

        ) = directOwnerOf(tokenId);

        if (tokenId != _lastTokenId) {
            (
                address lastTokenOwner,
                uint256 lastTokenParentId,

            ) = directOwnerOf(_lastTokenId);
            _updateOwnerAndClearApprovals(
                tokenId,
                lastTokenParentId,
                lastTokenOwner
            );
            _updateOwnerAndClearApprovals(
                _lastTokenId,
                burningTokenParentId,
                burningTokenOwner
            );
        }
        _burn(_lastTokenId, 0);
        _lastTokenId--;
    }
}
