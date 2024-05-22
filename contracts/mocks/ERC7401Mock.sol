// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {KarrotErc7401Base} from "../base/KarrotErc7401Base.sol";

contract ERC7401Mock is KarrotErc7401Base {
    constructor(
        address _defaultAdmin,
        address _minter,
        string memory _name
    ) KarrotErc7401Base(_defaultAdmin, _minter, _name) {}

    function mintTo(uint parentId, address to) external {
        _lastTokenId++;
        _nestMint(to, _lastTokenId, parentId, new bytes(0));
        _approve(msg.sender, _lastTokenId);
    }
}
