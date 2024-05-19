// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IKarrotOrganization} from "./interface/IKarrotOrganization.sol";
import {IKarrotCampaign} from "./interface/IKarrotCampaign.sol";
import {IKarrotTicket} from "./interface/IKarrotTicket.sol";
import {ILottery} from "./interface/ILottery.sol";
import {ITicketRedemption} from "./interface/ITicketRedemption.sol";

/**
 * @title TicketRedemption contract
 * @notice TicketRedemption enables users to exchange tickets for rewards on Karrot platform before the burn deadline.
 * @dev TicketRedemption manages reward token addresses, handles ticket redemption, and oversees redemption price and caps.
 */
contract TicketRedemption is ITicketRedemption, AccessControl {
    using SafeERC20 for IERC20;

    /// @notice Price per redeemed one ticket.
    uint public redemptionPrice;
    /// @notice The amount of tokens spent on ticket redemption.
    uint public redeemed;
    /// @notice Maximum total redemption amount of tokens allowed.
    uint public redemptionCap;

    /// @notice The address of the associated lottery contract.
    address public lottery;

    /// @notice Token contract for rewards.
    IERC20 public rewardToken;

    /**
     * @dev Constructor function to initialize the TicketRedemption contract.
     * @param _defaultAdmin The address of the admin this contract.
     * @param _lottery The address of the Lottery contract.
     * @dev Reverts if the lottery contract does not support their respective interfaces.
     */
    constructor(address _defaultAdmin, address _lottery) {
        if (
            !ILottery(_lottery).supportsInterface(
                type(ILottery).interfaceId
            )
        ) {
            revert InterfaceNotSupported();
        }

        lottery = _lottery;
        
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
    }

    /**
     * @notice Sets the reward token contract address.
     * @param _rewardToken The address of the reward token contract.
     * @dev Only can be called by accounts with the DEFAULT_ADMIN_ROLE.
     * @dev Reverts if reward token is not a contract.
     */
    function setRewardToken(address _rewardToken) external onlyRole(DEFAULT_ADMIN_ROLE)  {
        if (Address.isContract(_rewardToken) == false) {
            revert IncorrectValue("Reward token is not a contract");
        }

        rewardToken = IERC20(_rewardToken);
    }

    /**
     * @notice Redeems(burns) tickets for a reward.
     * @param ticketContract The ticket contract address.
     * @param amountOfTicketsToBurn The number of tickets to redeem.
     * @dev It is possible to redeem if the TicketRedemption must be approved from KarrotCampaing contract.
     * @dev After burn, user receives a reward in tokens.
     * @dev Only callable if burn period hasn't ended, redemption price is set, redemption cap.
     * isn't reached, user owns an organization and the ticket is registered in the lottery.
     */
    function redeem(address ticketContract, uint amountOfTicketsToBurn) external {
        address campaignAddress = IKarrotTicket(ticketContract).campaign();
        address organizationAddress = IKarrotCampaign(campaignAddress).organization();
        uint32 burnDeadline = ILottery(lottery).burnDeadline();

        if (block.timestamp > burnDeadline) {
            revert IncorrectCondition("Burn period finished yet");
        }
        if (redemptionPrice == 0) {
            revert IncorrectValue("Redemption price not set");
        }
        uint redemptionAmount = amountOfTicketsToBurn * redemptionPrice;
        if (redemptionCap > 0 && redeemed + redemptionAmount > redemptionCap) {
            revert IncorrectValue("Redemption cap reached");
        }
        uint organizationId = IKarrotOrganization(organizationAddress).ownerToken(msg.sender);
        if (organizationId == 0) {
            revert IncorrectValue("User is not an owner of any organization");
        }
        bool isRegisteredTicket = ILottery(lottery).isRegisteredTicket(ticketContract);
        if (!isRegisteredTicket) {
            revert IncorrectValue("The ticket is not registered");
        }

        uint campaignId = IKarrotCampaign(campaignAddress).ownerToken(organizationId);
        IKarrotCampaign(campaignAddress).burnTicketBatch(campaignId, amountOfTicketsToBurn);
        IERC20(rewardToken).safeTransfer(msg.sender, redemptionAmount);
        redeemed += redemptionAmount;
        emit TicketRedeemed(msg.sender, ticketContract, amountOfTicketsToBurn, redemptionAmount);
    }

    /**
     * @dev Sets the redemption price.
     * @param _redemptionPrice The new redemption price.
     * @dev Only can be called by accounts with the DEFAULT_ADMIN_ROLE.
     * @dev Reverts if the caller doesn't have admin role or if the redemption price is set to 0.
     */
    function setRedemptionPrice(uint _redemptionPrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_redemptionPrice == 0) {
            revert IncorrectValue("Redemption price can't be 0");
        }
        redemptionPrice = _redemptionPrice;
        emit SetRedemptionPrice(_redemptionPrice);
    }

    /**
     * @notice Sets the redemption cap.
     * @param _redemptionCap The new redemption cap. A value of 0 indicates no cap.
     * @dev Only can be called by accounts with the DEFAULT_ADMIN_ROLE.
     * @dev redemptionCap can be 0, meaning no cap
     */
    function setRedemptionCap(uint _redemptionCap) external onlyRole(DEFAULT_ADMIN_ROLE) {
        //redemptionCap can be 0, meaning no cap
        redemptionCap = _redemptionCap;
        emit SetRedemptionCap(_redemptionCap);
    }

    /**
     * @notice Checks if the contract supports a given interface.
     * @param interfaceId The interface identifier.
     * @return A boolean indicating whether the contract supports the interface.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(AccessControl, IERC165) returns (bool) {
        return interfaceId == type(ITicketRedemption).interfaceId || 
            super.supportsInterface(interfaceId);
    }
}
