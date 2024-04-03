// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.21;

import {KarrotTicket} from "../KarrotTicket.sol";

library TicketDeployerLibrary {
    function deployTicket(
        address defaultAdmin,
        address minterContract,
        uint256 ticketsCount,
        address campaign,
        string memory campaignName
    ) external returns (address) {
        return address(
            new KarrotTicket{salt: keccak256(abi.encodePacked(ticketsCount))}(
                defaultAdmin,
                minterContract,
                campaign,
                string(abi.encodePacked(campaignName, " Tickets"))
            )
        );
    }
}