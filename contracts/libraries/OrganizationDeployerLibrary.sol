// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {KarrotOrganization} from "../KarrotOrganization.sol";

library OrganizationDeployerLibrary {
    function deployOrganizationContract(
        address defaultAdmin,
        address minter,
        uint organizationsCount,
        string memory organizationName
    ) external returns (address) {
        address newOrganization = address(
            new KarrotOrganization{
                salt: keccak256(abi.encodePacked(organizationsCount))
            }(defaultAdmin, minter, organizationName)
        );
        return newOrganization;
    }
}