# Solidity API

## ITicketMinter

The TicketMinter contract manages the creation of tickets for campaigns on the Karrot platform by interfacing with the KarrotFactory.

_TicketMinter ensures that tickets are minted for end owners within specified campaigns._

### mintTicketsBatch

```solidity
function mintTicketsBatch(address[] endOwners, address campaign, uint256[] ticketsCounts) external returns (uint256[][] ticketsTokenIds)
```

Mints tickets for multiple end owners in batches.

_Reverts if the length of `endOwners` does not match the length of `ticketsCounts`._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| endOwners | address[] | An array of end owners to whom tickets will be minted. |
| campaign | address | The address of the campaign for which tickets are being minted. |
| ticketsCounts | uint256[] | An array specifying the number of tickets to mint for each end owner. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| ticketsTokenIds | uint256[][] | An array of arrays containing the token IDs of the minted tickets for each end owner. |

### mintTickets

```solidity
function mintTickets(address endOwner, address campaign, uint256 ticketsCount) external returns (uint256[] ticketsTokenIds)
```

Mints tickets for a specific end owner in a campaign.

_If any organization is found for the endOwner, we will mint it for him.
If any campaign is found for the endOwner, we will mint it for him._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| endOwner | address | The address of the end owner who will receive the tickets. |
| campaign | address | The address of the campaign for which tickets are being minted. |
| ticketsCount | uint256 | The number of tickets to mint. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| ticketsTokenIds | uint256[] | An array containing the token IDs of the minted tickets. |

