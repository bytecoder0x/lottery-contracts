// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IKarrotCampaign} from "./interface/IKarrotCampaign.sol";
import {ILottery} from "./interface/ILottery.sol";
import {IRandomGetter} from "./interface/IRandomGetter.sol";
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
    uint256 public requestRandomNumberId;

    address[] public organizations;
    uint[] public organizationSharesForFixedTiers;

    uint public initializedOrganizationsCount;
    mapping(address => bool) public isRegisteredTicket;
    mapping(address => bool) public isOrganizationAdded;
    mapping(address => address[]) public organizationTicketsContracts;
    mapping(address => TicketRange) public organizationTicketsRange;
    CampaignTickets[] public allCampaignTickets;

    Tier[] public tiers;
    uint256 public processedTiersCount;
    IERC20 public rewardToken;
    IRandomGetter public randomGetter;

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

    /**
     * @notice Registers a ticket contract for the lottery.
     * @param _ticketContract The address of the ticket contract to register.
     * @dev Reverts if the ticket contract does not support the IKarrotTicket interface.
     */
    function registerTicketContract(address _ticketContract) external onlyRole(REGISTRAR_ROLE) {
        if (IERC165(_ticketContract).supportsInterface(type(IKarrotTicket).interfaceId) == false) {
            revert InterfaceNotSupported();
        }
        address organization = IKarrotTicket(_ticketContract).getOrganisation();
        if (!isOrganizationAdded[organization]) {
            organizations.push(organization);
            isOrganizationAdded[organization] = true;
        }
        isRegisteredTicket[_ticketContract] = true;
        organizationTicketsContracts[organization].push(_ticketContract);
        emit RegisterTicketContract(organization, _ticketContract);
    }

    /**
     * @notice Initializes the lottery by assigning ticket ranges to each organization's tickets.
     * @param organizationsCount The number of organizations to initialize in the lottery.
     * @dev Reverts if the burn period has not finished yet or if the lottery is already initialized.
     */
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

    /**
     * @notice Sets up the lottery with specified parameters.
     * @param _rewardToken The address of the token used as rewards.
     * @param _randomGetter The address of the contract providing random numbers.
     * @param _tiers An array containing the configuration of lottery tiers.
     * @param _organizationSharesForFixedTiers An array containing the percentage shares of organizations for fixed tiers.
     * @dev Reverts if the current block timestamp is after the specified lottery time.
     * @dev Reverts if the reward token is not a contract or if the random getter contract does not support the required interface.
     * @dev Reverts if the number of organization shares for fixed tiers does not match the number of organizations.
     * @dev Reverts if there are any incorrect tier configurations or if the total organization shares do not sum up to 100%.
     */
    function setupLottery(
        address _rewardToken,
        address _randomGetter,
        Tier[] memory _tiers,
        uint[] memory _organizationSharesForFixedTiers
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (block.timestamp > lotteryTime) {
            revert IncorrectCondition("Can't setup after lottery time");
        }
        if (Address.isContract(_rewardToken) == false) {
            revert IncorrectValue("Reward token is not a contract");
        }
        if (
            !IRandomGetter(_randomGetter).supportsInterface(
                type(IRandomGetter).interfaceId
            )
        ) {
            revert InterfaceNotSupported();
        }
        if (_organizationSharesForFixedTiers.length != organizations.length) {
            revert IncorrectValue("Incorrect organization shares count");
        }

        rewardToken = IERC20(_rewardToken);
        randomGetter = IRandomGetter(_randomGetter);

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

    /**
     * @notice Initiates the lottery process.
     * @dev Reverts if the current block timestamp is before the specified lottery time.
     * @dev Reverts if a random number request is already pending.
     * @dev Reverts if the lottery is not fully initialized with all organizations.
     */
    function runLottery() external {
        if (block.timestamp < lotteryTime) {
            revert IncorrectCondition("Lottery time not reached yet");
        }
        if (requestRandomNumberId != 0) {
            revert ActionPerformed("Lottery already run");
        }
        if (initializedOrganizationsCount != organizations.length) {
            revert IncorrectCondition("Lottery is not fully initialized");
        }
        requestRandomNumberId = randomGetter.requestRandomNumber();
    }

    /**
     * @notice Rewards the winners of the lottery tiers.
     * @param tiersCount The number of tiers to process.
     * @dev If `randomSalt` is not set, it fetches a random number from the random getter contract.
     * @dev Reverts if a random number is still pending or if the lottery is not yet run.
     * @dev Reverts if the lottery has already been processed.
     */
    function rewardWinners(uint tiersCount) external {
        if (randomSalt == 0) randomSalt = randomGetter.getRandomNumber(requestRandomNumberId);

        if (randomSalt == 0) {
            revert IncorrectCondition("Request is pending or lottery is not run");
        }
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

    /**
     * @notice Retrieves the underlying ticket information for a given lottery ticket ID.
     * @param lotteryTicketId The ID of the lottery ticket.
     * @return The address of the ticket contract and the corresponding ticket ID within that contract.
     */
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

    /**
     * @notice Retrieves information about a specific tier in the lottery.
     * @param tierIndex The index of the tier to retrieve.
     * @return Tier information including tier type, winners count, reward amount, etc.
     */
    function getTier(uint tierIndex) public view returns (Tier memory) {
        return tiers[tierIndex];
    }

    /**
     * @notice Retrieves information about all tiers in the lottery.
     * @return An array containing information about all tiers including tier type, winners count, reward amount, etc.
     */
    function getAllTiers() public view returns (Tier[] memory) {
        return tiers;
    }

    /**
     * @notice Retrieves the addresses of all organizations participating in the lottery.
     * @return An array containing the addresses of all participating organizations.
     */
    function getAllOrganizations() public view returns (address[] memory) {
        return organizations;
    }

    /**
     * @notice Retrieves the addresses of all ticket contracts associated with a specific organization.
     * @param organization The address of the organization.
     * @return An array containing the addresses of ticket contracts associated with the organization.
     */
    function getOrganizationTicketsContracts(address organization) public view returns (address[] memory) {
        return organizationTicketsContracts[organization];
    }

    /**
     * @notice Retrieves the shares assigned to each organization for fixed tiers.
     * @return An array containing the shares assigned to each organization for fixed tiers.
     */
    function getOrganizationSharesForFixedTiers() public view returns (uint[] memory) {
        return organizationSharesForFixedTiers;
    }

    /**
     * @notice Retrieves all campaign tickets stored in the lottery.
     * @return An array containing all campaign tickets stored in the lottery.
     */
    function getAllCampaignTickets() public view returns (CampaignTickets[] memory) {
        return allCampaignTickets;
    }

    /**
     * @dev Recursively checks if the ticket with the given ID is not a winner.
     * @param lotteryTicketId The ID of the lottery ticket to check.
     * @return The ID of the first non-winning ticket found after the provided ID.
     */
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

    /**
     * @dev Rewards the winners for the specified tier.
     * @param startTicketId The starting ID of the lottery tickets range.
     * @param endTicketId The ending ID of the lottery tickets range.
     * @param tierIndex The index of the tier.
     * @param tier The details of the tier.
     * @return tierTotalRewardAmount The total amount rewarded for the tier.
     */
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

    /**
     * @notice Checks if the contract supports a given interface.
     * @param interfaceId The interface identifier.
     * @return A boolean indicating whether the contract supports the interface.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(AccessControl, IERC165) returns (bool) {
        return interfaceId == type(ILottery).interfaceId || 
            AccessControl.supportsInterface(interfaceId);
    }
}