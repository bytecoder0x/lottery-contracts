// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IKarrotErrors} from "./IKarrotErrors.sol";

interface IKarrotErc7401Base is IKarrotErrors {
    function totalSupply() external view returns (uint256);
    function name() external view returns (string memory);
    function isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool);
}