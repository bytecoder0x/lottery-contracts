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

contract TicketRedemption is ITicketRedemption, AccessControl {
    using SafeERC20 for IERC20;

    uint public redemptionPrice;
    uint public redeemed;
    uint public redemptionCap;

    address lottery;

    IERC20 public rewardToken;

    constructor(address _defaultAdmin, address _lottery) {
        lottery = _lottery;
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
    }

    function setRewardToken(address _rewardToken) external onlyRole(DEFAULT_ADMIN_ROLE)  {
        if (Address.isContract(_rewardToken) == false) {
            revert IncorrectValue("Reward token is not a contract");
        }

        rewardToken = IERC20(_rewardToken);
    }

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
        bool isRegisteredTicket = _checkTiketRegistration(ticketContract, organizationAddress);
        if (!isRegisteredTicket) {
            revert IncorrectValue("The ticket is not registered");
        }

        uint campaignId = IKarrotCampaign(campaignAddress).ownerToken(organizationId);
        IKarrotCampaign(campaignAddress).burnTicketBatch(campaignId, amountOfTicketsToBurn);
        IERC20(rewardToken).safeTransfer(msg.sender, redemptionAmount);
        redeemed += redemptionAmount;
        emit TicketRedeemed(msg.sender, ticketContract, amountOfTicketsToBurn, redemptionAmount);
    }

    function setRedemptionPrice(uint _redemptionPrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_redemptionPrice == 0) {
            revert IncorrectValue("Redemption price can't be 0");
        }
        redemptionPrice = _redemptionPrice;
        emit SetRedemptionPrice(_redemptionPrice);
    }

    function setRedemptionCap(uint _redemptionCap) external onlyRole(DEFAULT_ADMIN_ROLE) {
        //redemptionCap can be 0, meaning no cap
        redemptionCap = _redemptionCap;
        emit SetRedemptionCap(_redemptionCap);
    }

    function _checkTiketRegistration(address _ticket, address _organization) view private returns(bool) {
        address[] memory tickets = ILottery(lottery).getOrganizationTicketsContracts(_organization);
        for (uint i = 0; i < tickets.length; i++) {
            if (tickets[i] == _ticket) {
                return true;
            }
        }
        return false;
    }
}
