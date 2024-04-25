// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {KarrotErc7401Base} from "../base/KarrotErc7401Base.sol";

import {IKarrotCampaign} from "../interface/IKarrotCampaign.sol";

contract ERC7401Mock is KarrotErc7401Base {
    address campaign;

    constructor(
        address _campaign,
        address _defaultAdmin,
        address _minter,
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

    function mintToCampaign(uint parentId, bytes memory data) internal {
        _lastTokenId++;
        _nestMint(campaign, _lastTokenId, parentId, data);
        _approve(msg.sender, _lastTokenId);
    }
}
