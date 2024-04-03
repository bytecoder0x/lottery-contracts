// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.21;

import {KarrotCampaign} from "../KarrotCampaign.sol";

library CampaignDeployerLibrary {
    function deployCampaignContract(
        address defaultAdmin,
        address lowerAdmin,
        address minterContract,
        uint256 campaignsCount,
        address lottery,
        address organization,
        string memory campaignName
    ) external returns (address) {
        return address(
            new KarrotCampaign{
                salt: keccak256(abi.encodePacked(campaignsCount))
            }(
                defaultAdmin,
                lowerAdmin,
                minterContract,
                organization,
                lottery,
                campaignName
            )
        );
    }
}