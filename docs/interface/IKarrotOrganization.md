# Solidity API

## IKarrotOrganization

The KarrotOrganization contract handles the creation and ownership of organization tokens in Karrot.

_KarrotOrganization allows minting new tokens for specific addresses and ensures each address can own only one organization token._

### OrganizationTokenMinted

```solidity
event OrganizationTokenMinted(address to, uint256 tokenId)
```

Emitted when a new organization token is minted.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | The address to which the token is minted. |
| tokenId | uint256 | The ID of the minted token. |

### mintTo

```solidity
function mintTo(address to, bytes data) external returns (uint256)
```

Mints a new organization token to the specified address.

_Reverts if the recipient already owns an organization token._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | The address to mint the token to. |
| data | bytes | Additional data to include in the minted token. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The ID of the newly minted token. |

### ownerToken

```solidity
function ownerToken(address owner) external view returns (uint256)
```

Retrieves the token ID owned by the specified address.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| owner | address | The address of the token owner. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The ID of the token owned by the specified address. |

