// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IKarrotCampaign} from "./interface/IKarrotCampaign.sol";
import {ILottery} from "./interface/ILottery.sol";
import {IKarrotTicket} from "./interface/IKarrotTicket.sol";

contract Lottery is AccessControl, ILottery {
    using SafeERC20 for IERC20;

    bytes32 public constant REGISTRAR_ROLE = keccak256("REGISTRAR");
    uint256 public constant BIPS = 100_00;

    uint32 public mintDeadline;
    uint32 public burnDeadline;
    uint32 public lotteryTime;
    
    uint256 public lotteryTicketsTotalSupply;
    uint256 public randomSalt;

    address[] public organizations;
    uint[] public organizationSharesForFixedTiers;

    uint public initializedOrganizationsCount;
    mapping(address => bool) public isOrganizationAdded;
    mapping(address => address[]) public organizationTicketsContracts;
    mapping(address => TicketRange) public organizationTicketsRange;
    CampaignTickets[] public allCampaignTickets;

    Tier[] public tiers;
    uint256 public processedTiersCount;
    IERC20 public rewardToken;

    mapping(uint256 => uint256) public winnerAmount;
    mapping(uint256 => uint256[]) public tierWinners;
    bool public lotteryProcessed;
    
    constructor(
        address _defaultAdmin,
        address _registrar,
        uint32 _mintDeadline,
        uint32 _burnDeadline,
        uint32 _lotteryTime
    ) {
        if (block.timestamp > _mintDeadline || _mintDeadline > _burnDeadline || _burnDeadline > _lotteryTime) {
            revert IncorrectValue("Incorrect time values");
        }
        mintDeadline = _mintDeadline;
        burnDeadline = _burnDeadline;
        lotteryTime = _lotteryTime;

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(REGISTRAR_ROLE, _registrar); //expected to be factory contract
    }

    function registerTicketContract(address _ticketContract) external onlyRole(REGISTRAR_ROLE) {
        if (IERC165(_ticketContract).supportsInterface(type(IKarrotTicket).interfaceId) == false) {
            revert InterfaceNotSupported();
        }
        address organization = IKarrotTicket(_ticketContract).getOrganisation();
        if (!isOrganizationAdded[organization]) {
            organizations.push(organization);
            isOrganizationAdded[organization] = true;
        }
        organizationTicketsContracts[organization].push(_ticketContract);
        emit RegisterTicketContract(organization, _ticketContract);
    }

    function initializeLottery(uint organizationsCount) external {
        if (block.timestamp < burnDeadline) {
            revert IncorrectCondition("Burn period not finished yet");
        }
        if (initializedOrganizationsCount == organizations.length) {
            revert ActionPerformed("Lottery already initialized");
        }

        uint initializedOrganizationIndex = initializedOrganizationsCount; //cache value for gas optimization
        if (organizationsCount == 0 || organizationsCount > organizations.length - initializedOrganizationIndex) {
            organizationsCount = organizations.length - initializedOrganizationIndex;
        }

        uint startIndex;
        uint lotteryTotalSupply;
        for (uint o = initializedOrganizationIndex; o < initializedOrganizationIndex + organizationsCount; o++) {
            address[] memory organizationTickets = organizationTicketsContracts[organizations[o]];
            organizationTicketsRange[organizations[o]].firstLotteryTicketId = lotteryTotalSupply;
            for (uint t; t < organizationTickets.length; t++) {
                uint campaignTotalSupply = IKarrotTicket(organizationTickets[t]).totalSupply();
                lotteryTotalSupply = startIndex + campaignTotalSupply;
                allCampaignTickets.push(CampaignTickets(organizationTickets[t], TicketRange(startIndex, lotteryTotalSupply - 1)));
                //if (o != organizations.length - 1 && t != organizationTickets.length - 1) {
                    startIndex = lotteryTotalSupply;
                //}
            }
            organizationTicketsRange[organizations[o]].lastLotteryTicketId = lotteryTotalSupply - 1;
            initializedOrganizationsCount++;
        }
        lotteryTicketsTotalSupply += lotteryTotalSupply;

        for (uint i; i < tiers.length; i++) {
            if (tiers[i].tierType == TierType.Random) {    
                tiers[i].winnersCount = lotteryTicketsTotalSupply * tiers[i].winnersShare / BIPS;
            }
        }
        emit LotteryInitialized(organizations.length);
    }

    function setupLottery(
        address _rewardToken,
        Tier[] memory _tiers,
        uint[] memory _organizationSharesForFixedTiers
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (block.timestamp > lotteryTime) {
            revert IncorrectCondition("Can't setup after lottery time");
        }
        if (Address.isContract(_rewardToken) == false) {
            revert IncorrectValue("Reward token is not a contract");
        }
        if (_organizationSharesForFixedTiers.length != organizations.length) {
            revert IncorrectValue("Incorrect organization shares count");
        }

        rewardToken = IERC20(_rewardToken);

        for (uint i; i < _tiers.length; i++) {
            Tier memory tier = _tiers[i]; 
            if (i == 0) {
                if (tier.tierType != TierType.Jackpot) {
                    revert IncorrectValue("First tier must be Jackpot");
                }
                if (tier.winnersCount != 1) {
                    revert IncorrectValue("There must be 1 winner in Jackpot tier");
                }
            } else {
                if (_tiers[i - 1].tierType > _tiers[i].tierType) {
                    revert IncorrectValue("Incorrect tier order");
                }
                
                if (tier.tierType == TierType.Random) {
                    if (tier.winnersShare == 0) {
                        revert IncorrectValue("Winners share can't be 0 for random tier");
                    }
                    tier.winnersCount = lotteryTicketsTotalSupply * tier.winnersShare / BIPS;
                } else if (tier.winnersCount == 0) {
                    revert IncorrectValue("Winners count can't be 0 for fixed tier");
                }
            }
            if (tier.rewardAmount == 0) {
                revert IncorrectValue("Incorrect tier values");
            }
            tiers.push(_tiers[i]);

        }

        uint totalShares;
        for (uint i; i < _organizationSharesForFixedTiers.length; i++) {
            if (_organizationSharesForFixedTiers[i] == 0 || _organizationSharesForFixedTiers[i] > BIPS) {
                revert IncorrectValue("Incorrect organization shares");
            }
            totalShares += _organizationSharesForFixedTiers[i];
        }
        if (totalShares != BIPS) {
            revert IncorrectValue("Total shares sum must be 100%");
        }
        organizationSharesForFixedTiers = _organizationSharesForFixedTiers;
        emit LotterySetup(_rewardToken, tiers, organizationSharesForFixedTiers);
    }

    function runLottery() external {
        if (block.timestamp < lotteryTime) {
            revert IncorrectCondition("Lottery time not reached yet");
        }
        if (randomSalt != 0) {
            revert ActionPerformed("Lottery already run");
        }
        randomSalt = uint256(keccak256(abi.encodePacked(block.prevrandao)));
    }

    function rewardWinners(uint tiersCount) external {
        if (lotteryProcessed) {
            revert ActionPerformed("Lottery already processed");
        }
        uint processedTiersCountCache = processedTiersCount; //cache value for gas optimization
        if (tiersCount == 0 || tiersCount > tiers.length - processedTiersCountCache) {
            tiersCount = tiers.length - processedTiersCountCache;
        }
        for (uint t = processedTiersCountCache; t < processedTiersCountCache + tiersCount; t++) {
            Tier memory tier = tiers[t];
            if (tier.tierType != TierType.Fixed) {
                uint tierTotalRewardAmount = _rewardWinnersForTier(0, lotteryTicketsTotalSupply - 1, t, tier);
                emit TierProcessed(t, address(0), tierTotalRewardAmount);
            } else {
                for (uint o; o < organizations.length; o++) {
                    uint startTicketId = organizationTicketsRange[organizations[o]].firstLotteryTicketId;
                    uint endTicketId = organizationTicketsRange[organizations[o]].lastLotteryTicketId;
                    uint organizationWinnersCount = tier.winnersCount * organizationSharesForFixedTiers[o]  / BIPS;
                    Tier memory tierForFixed = Tier(tier.tierType, 0, organizationWinnersCount, tier.rewardAmount);
                    uint tierTotalRewardAmount = _rewardWinnersForTier(startTicketId, endTicketId, t, tierForFixed);
                    emit TierProcessed(t, organizations[o], tierTotalRewardAmount);
                }
            }
            processedTiersCount++;
        }
        if (processedTiersCount == tiers.length) {
            lotteryProcessed = true;
            emit LotteryFinished();
        }
    }

    function getUnderlyingTicket(uint lotteryTicketId) public view returns (address, uint256) {
        uint256 lower = 0;
        uint256 upper = allCampaignTickets.length - 1;
        while (upper > lower) {
            uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            CampaignTickets memory tickets = allCampaignTickets[center];
            if (lotteryTicketId >= tickets.ticketRange.firstLotteryTicketId && 
                tickets.ticketRange.lastLotteryTicketId >= lotteryTicketId
            ) {
                return 
                    (tickets.campaignTicketContract, 
                    tickets.ticketRange.lastLotteryTicketId - lotteryTicketId + 1);

            } else if (tickets.ticketRange.firstLotteryTicketId < lotteryTicketId) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        CampaignTickets memory tickets_ = allCampaignTickets[lower];
        return (tickets_.campaignTicketContract,  tickets_.ticketRange.lastLotteryTicketId - lotteryTicketId + 1);
        //TODO: refactor
    }

    function getTier(uint tierIndex) public view returns (Tier memory) {
        return tiers[tierIndex];
    }

    function getAllTiers() public view returns (Tier[] memory) {
        return tiers;
    }

    function getAllOrganizations() public view returns (address[] memory) {
        return organizations;
    }

    function getOrganizationTicketsContracts(address organization) public view returns (address[] memory) {
        return organizationTicketsContracts[organization];
    }

    function getOrganizationSharesForFixedTiers() public view returns (uint[] memory) {
        return organizationSharesForFixedTiers;
    }

    function getAllCampaignTickets() public view returns (CampaignTickets[] memory) {
        return allCampaignTickets;
    }

    function _checkTickedIsNotWinner(uint lotteryTicketId) internal view returns (uint) {
        if (winnerAmount[lotteryTicketId] > 0) {
            uint newId = lotteryTicketId + 1;
            if (newId > lotteryTicketsTotalSupply - 1) {
                newId = 0;
            }
            return _checkTickedIsNotWinner(newId);
        } else {
            return lotteryTicketId;
        }
    }

    function _rewardWinnersForTier(
        uint startTicketId,
        uint endTicketId,
        uint tierIndex,
        Tier memory tier
    ) internal returns (uint tierTotalRewardAmount) {
        uint ticketsInRange = endTicketId - startTicketId + 1;
        for(uint w; w < tier.winnersCount; w++) {
            uint lotteryTicketId = uint(keccak256(abi.encode(randomSalt, tierIndex, w))) % ticketsInRange + startTicketId;
            lotteryTicketId = _checkTickedIsNotWinner(lotteryTicketId);
            (address campaignTicketContract, uint campaignTicketId) = getUnderlyingTicket(lotteryTicketId);
            address owner = IKarrotTicket(campaignTicketContract).ownerOf(campaignTicketId);
            rewardToken.safeTransfer(owner, tier.rewardAmount);
            winnerAmount[lotteryTicketId] = tier.rewardAmount;
            tierWinners[tierIndex].push(lotteryTicketId);
            emit WinnerDefined(owner, lotteryTicketId, campaignTicketContract, campaignTicketId, uint256(tier.tierType), tier.rewardAmount);
            tierTotalRewardAmount += tier.rewardAmount;
        }
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(AccessControl, IERC165) returns (bool) {
        return interfaceId == type(ILottery).interfaceId || 
            AccessControl.supportsInterface(interfaceId);
    }
}