# Short list of Backend and Frontend functions

This is a list of the most used functions for frontend and backend developers. A detailed description of each function can be found in another file.

## KarrotFactory

- [ticketsCampaign](./interface/IKarrotFactory.md#ticketscampaign)
- [campaignOrganization](./interface/IKarrotFactory.md#campaignorganization)
- [getAllLotteries](./KarrotFactory.md#getalllotteries)
- [getAllRedemptions](./KarrotFactory.md#getallredemptions)
- [getAllOrganizations](./KarrotFactory.md#getallorganizations)
- [getAllCampaigns](./KarrotFactory.md#getallcampaigns)
- [getAllTickets](./KarrotFactory.md#getalltickets)

## KarrotOrganization

- [ownerToken](./interface/IKarrotOrganization.md#ownertoken)
- [ownerOf](./KarrotOrganization.md#ownerof)

## KarrotCampaign

- [ownerToken](./interface/IKarrotCampaign.md#ownertoken)
- [ownerOf](./KarrotCampaign.md#ownerof)
- [getLotteryContract](./KarrotCampaign.md#getlotterycontract)
- [getUserCampaignId](./KarrotCampaign.md#getusercampaignid)

## KarrotTicket

- [getLotteryContract](./KarrotTicket.md#getlotterycontract)
- [ownerOf](./KarrotTicket.md#ownerof)
- [getOrganisation](./KarrotTicket.md#getorganisation)
- [getUserTicketIds](./KarrotTicket.md#getuserticketids)

## TicketMinter

- [mintTicketsBatch](./TicketMinter.md#mintticketsbatch)
- [mintTickets](./TicketMinter.md#minttickets)

## Lottery

- [mintDeadline](./interface/ILottery.md#mintdeadline)
- [burnDeadline](./interface/ILottery.md#burndeadline)
- [lotteryTime](./interface/ILottery.md#lotterytime)
- [isRegisteredTicket](./interface/ILottery.md#isregisteredticket)
- [isOrganizationAdded](./interface/ILottery.md#isorganizationadded)
- [organizationTicketsContracts](./interface/ILottery.md#organizationticketscontracts)
- [winnerAmount](./interface/ILottery.md#winneramount)
- [tierWinners](./interface/ILottery.md#tierwinners)
- [getAllTiers](./Lottery.md#getalltiers)
- [getAllOrganizations](./Lottery.md#getallorganizations)
- [getOrganizationTicketsContracts](./Lottery.md#getorganizationticketscontracts)
- [getOrganizationSharesForFixedTiers](./Lottery.md#getorganizationsharesforfixedtiers)
- [getAllCampaignTickets](./Lottery.md#getallcampaigntickets)


## TicketRedemption

- [redeem](./TicketRedemption.md#redeem)