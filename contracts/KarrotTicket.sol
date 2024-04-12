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
        _mintToCampaign(parentId, data);
        
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
            _mintToCampaign(parentId, data);
            tokenIds[i] = _lastTokenId;
        }
        return tokenIds;
    }
    
    function burnLastTicket() external {
        if(msg.sender != campaign){
            revert IncorrectValue("Only Campaign can burn tickets");
        }
        uint previousLastTiketId = _lastTokenId;
        _burn(previousLastTiketId, 0);
        emit TicketBurned(previousLastTiketId);
        _lastTokenId--;
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

    function _mintToCampaign(uint parentId, bytes memory data) internal {
        _lastTokenId++;
        _nestMint(campaign, _lastTokenId, parentId, data);
        _approve(msg.sender, _lastTokenId);

        emit TicketMintedToCampaign(_lastTokenId, parentId, campaign);

    }
}
