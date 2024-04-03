// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC7401} from "@rmrk-team/evm-contracts/contracts/RMRK/nestable/IERC7401.sol";
import {IKarrotErc7401Base} from "./IKarrotErc7401Base.sol";

interface IKarrotCampaign is IERC7401, IKarrotErc7401Base {
    error MissingAdminRole(address caller);

    function mintToOrganization(uint256 parentId, bytes memory data) external returns (uint256);

    function setTicketContract(address ticketContract) external;

    function organization() external view returns (address); 

    function lottery() external view returns (address);

    function ticketsContract() external view returns (address);
}