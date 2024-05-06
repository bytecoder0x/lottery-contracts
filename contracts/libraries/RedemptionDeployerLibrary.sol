// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {TicketRedemption} from "../TicketRedemption.sol";

library RedemptionDeployerLibrary {
    function deployRedemtionContract(
        address defaultAdmin,
        address lottery,
        uint256 redemptionsCount
    ) external returns (address) {
        return address(
            new TicketRedemption{salt: keccak256(abi.encodePacked(redemptionsCount))}(
                defaultAdmin,
                lottery
            )
        );
    }
}
