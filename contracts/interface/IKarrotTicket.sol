// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC7401} from "@rmrk-team/evm-contracts/contracts/RMRK/nestable/IERC7401.sol";
import {IKarrotErc7401Base} from "./IKarrotErc7401Base.sol";

interface IKarrotTicket is IERC7401, IKarrotErc7401Base {
    function mintToCampaign(uint256 parentId, bytes memory data) external returns (uint256);

    function mintToCampaignBatch(
        uint256 tokenCount,
        uint256 parentId,
        bytes memory data
    ) external returns (uint256[] memory);

    function getOrganisation() external view returns (address);
    function campaign() external view returns (address);
    function burnBatch(uint256[] memory tokenIds) external;
}
