// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IKarrotErrors} from "./IKarrotErrors.sol";

interface ITicketRedemption is IERC165, IKarrotErrors {

    event TicketRedeemed(address indexed redeemer, address ticketContract, uint ticketsCount, uint redemptionAmount);
    event SetRedemptionPrice(uint redemptionPrice);
    event SetRedemptionCap(uint redemptionCap);

    function setRewardToken(address _rewardToken) external;

    function redeem(address ticketContract, uint amountOfTicketsToBurn) external;

    function setRedemptionPrice(uint _redemptionPrice) external;
    
    function setRedemptionCap(uint _redemptionCap) external;
}
