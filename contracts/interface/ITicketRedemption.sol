// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IKarrotErrors} from "./IKarrotErrors.sol";

/**
 * @title Ticket Redemption Interface
 * @notice Interface for the TicketRedemption contract that enables users to exchange tickets for rewards on Karrot platform.
 */
interface ITicketRedemption is IERC165, IKarrotErrors {

    /**
     * @notice Emitted when tickets are redeemed for a reward.
     * @param redeemer The address of the redeemer that burned his tiсket.
     * @param ticketContract The address of the ticket contract.
     * @param ticketsCount The number of tickets redeemed.
     * @param redemptionAmount The amount of reward tokens redeemed.
     */
    event TicketRedeemed(address indexed redeemer, address ticketContract, uint ticketsCount, uint redemptionAmount);

    /**
     * @notice Emitted when the redemption price is set.
     * @param redemptionPrice The new redemption price.
     */
    event SetRedemptionPrice(uint redemptionPrice);

    /**
     * @notice Emitted when the redemption cap is set.
     * @param redemptionCap The new redemption cap.
     */
    event SetRedemptionCap(uint redemptionCap);


    /** 
     * @notice Represents the total tokens utilized for ticket redemption.
     * @return The amount of tokens spent on ticket redemption.
     */
    function redeemed() external view returns (uint);

    /**
     * @notice Indicates the maximum tokens permitted for redemption.
     * @return The maximum total redemption amount of tokens allowed.
     */
    function redemptionCap() external view returns (uint);

    /**
     * @notice Address of the lottery contract associated with this redemption.
     * @return The address of the associated lottery contract.
     */
    function lottery() external view returns (address);

    /**
     * @notice Token contract used as rewards in the lottery and redemption.
     * @return The address contract for rewards.
     */
    function rewardToken() external view returns (IERC20);

    /**
     * @notice Sets the reward token contract address.
     * @param _rewardToken The address of the reward token contract.
     */
    function setRewardToken(address _rewardToken) external;

    /**
     * @notice Redeems(burns) tickets for a reward.
     * @param ticketContract The ticket contract address.
     * @param amountOfTicketsToBurn The number of tickets to redeem.
     * @dev It is possible to redeem if the TicketRedemption has approved from KarrotCampaing contract.
     */
    function redeem(address ticketContract, uint amountOfTicketsToBurn) external;

    /**
     * @dev Sets the redemption price.
     * @param _redemptionPrice The new redemption price.0.
     */
    function setRedemptionPrice(uint _redemptionPrice) external;
    
    /**
     * @notice Sets the redemption cap.
     * @param _redemptionCap The new redemption cap. A value of 0 indicates no cap.
     */
    function setRedemptionCap(uint _redemptionCap) external;
}
