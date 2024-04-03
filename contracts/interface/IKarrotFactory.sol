// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IKarrotErrors} from "./IKarrotErrors.sol";

interface IKarrotFactory is IERC165, IKarrotErrors {
    event MinterContractUpdated(address indexed newMinterContract);

    function isOrganization(address organization) external view returns (bool);
    function isLottery(address lottery) external view returns (bool);
    function campaignOrganization(address campaign) external view returns (address organization);
    function ticketsCampaign(address ticketContract) external view returns (address campaign);
    function getAllLotteries() external view returns (address[] memory);
    function getAllOrganizations() external view returns (address[] memory);
    function getAllCampaigns() external view returns (address[] memory);
    function getAllTickets() external view returns (address[] memory);

    function setMinterContract(address _minterContract) external;

    function deployLotteryContract(
        address defaultAdmin,
        uint32 mintDeadline,
        uint32 burnDeadline,
        uint32 lotteryTime
    ) external returns (address deployedLottery);

    function deployOrganizationContract(
        address defaultAdmin,
        string memory organizationName
    ) external returns (address deployedOrganization);

    function deployCampaignAndTicketContract(
        address defaultAdmin,
        address lottery,
        address organization,
        string memory campaignName
    ) external returns (address deplyedCampaign, address deployedTicket);

    function deployOrganizationAndCampaigns(
        address defaultAdmin,
        address lottery,
        string memory organizationName,
        string[] memory campaignNames
    ) external returns (
        address deployedOrganization,
        address[] memory deployedCampaigns,
        address[] memory deployedTickets
    );
}
