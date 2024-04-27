// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {KarrotErc7401Base} from "../base/KarrotErc7401Base.sol";

import {IKarrotTicket} from "../interface/IKarrotTicket.sol";
import {IKarrotCampaign} from "../interface/IKarrotCampaign.sol";

contract KarrotCampaignMock is KarrotErc7401Base {
    address public lottery;
    address public ticketsContract;

    constructor(
        address _defaultAdmin,
        address _minter,
        address _lottery,
        string memory _name
    ) KarrotErc7401Base(_defaultAdmin, _minter, _name) {
        lottery = _lottery;
    }

    function mintTo(address to) external {
        _lastTokenId++;
        _safeMint(to, _lastTokenId, new bytes(0));
        _approve(msg.sender, _lastTokenId);
    }

    function burnTicket() external {
        IKarrotTicket(ticketsContract).burnLastTicket();
    }

    function setTicketContract(address _ticketsContract) public {
        ticketsContract = _ticketsContract;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(KarrotErc7401Base) returns (bool) {
        return
            interfaceId == type(IKarrotCampaign).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
