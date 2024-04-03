// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IKarrotErrors} from "./IKarrotErrors.sol";

interface ITicketMinter is IERC165, IKarrotErrors {
    function mintTicketsBatch(
        address[] memory endOwners,
        address campaign,
        uint256[] memory ticketsCounts
    ) external returns (uint256[][] memory ticketsTokenIds);

   function mintTickets(
        address endOwner,
        address campaign,
        uint256 ticketsCount
    ) external returns (uint256[] memory ticketsTokenIds);
}
