// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC7401} from "@rmrk-team/evm-contracts/contracts/RMRK/nestable/IERC7401.sol";
import {IKarrotErc7401Base} from "./IKarrotErc7401Base.sol";

interface IKarrotOrganization is IERC7401, IKarrotErc7401Base {
    function mintTo(address to, bytes memory data) external returns (uint256);

    function ownerToken(address owner) external view returns (uint256);
}