## KarrotFactory

- [ticketsCampaign](./interface/IKarrotFactory.md#ticketscampaign)
- [campaignOrganization](./interface/IKarrotFactory.md#campaignorganization)
- [getAllLotteries](./KarrotFactory.md#getalllotteries)
- [getAllRedemptions](./KarrotFactory.md#getallredemptions)
- [getAllOrganizations](./KarrotFactory.md#getallorganizations)
- [getAllCampaigns](./KarrotFactory.md#getallcampaigns)
- [getAllTickets](./KarrotFactory.md#getalltickets)
- [getLotteriesCount](./KarrotFactory.md#getlotteriescount)
- [getRedemptionsCount](./KarrotFactory.md#getredemptionscount)
- [getOrganizationsCount](./KarrotFactory.md#getorganizationscount)
- [getCampaignsCount](./KarrotFactory.md#getcampaignscount)
- [getTicketsCount](./KarrotFactory.md#getticketscount)

## KarrotOrganization

- [ownerToken](./interface/IKarrotOrganization.md#ownertoken)
- [mintTo](./KarrotOrganization.md#mintto)
- [ownerOf](./KarrotOrganization.md#ownerof)

## KarrotCampaign

- [ownerToken](./interface/IKarrotCampaign.md#ownertoken)
- [mintToOrganization](./KarrotCampaign.md#minttoorganization)
- [burnTicket](./KarrotCampaign.md#burnticket) 
- [burnTicket](./KarrotCampaign.md#burnticket-1) (by campaign id)
- [burnTicketBatch](./KarrotCampaign.md#burnticketbatch)
- [burnTicketBatch](./KarrotCampaign.md#burnticketbatch-1) (by campaign id)
- [ownerOf](./KarrotCampaign.md#ownerof)
- [getLotteryContract](./KarrotCampaign.md#getlotterycontract)
- [getUserCampaignId](./KarrotCampaign.md#getusercampaignid)

## KarrotTicket

- [mintToCampaign](./KarrotTicket.md#minttocampaign)
- [mintToCampaignBatch](./KarrotTicket.md#minttocampaignbatch)
- [burnLastTicket](./KarrotTicket.md#burnlastticket)
- [getLotteryContract](./KarrotTicket.md#getlotterycontract)
- [ownerOf](./KarrotTicket.md#ownerof)
- [getOrganisation](./KarrotTicket.md#getorganisation)
- [getUserTicketIds](./KarrotTicket.md#getuserticketids)

## TicketMinter

- [MINTER_ROLE](./base/KarrotErc7401Base.md#minter_role)
- [mintTicketsBatch](./TicketMinter.md#mintticketsbatch)
- [mintTickets](./TicketMinter.md#minttickets)

## Lottery

- [mintDeadline](./interface/ILottery.md#mintdeadline)
- [burnDeadline](./interface/ILottery.md#burndeadline)
- [lotteryTime](./interface/ILottery.md#lotterytime)
- [isRegisteredTicket](./interface/ILottery.md#isregisteredticket)
- [isOrganizationAdded](./interface/ILottery.md#isorganizationadded)
- [organizationTicketsContracts](./interface/ILottery.md#organizationticketscontracts)
- [organizationTicketsRange](./interface/ILottery.md#organizationticketsrange)
- [winnerAmount](./interface/ILottery.md#winneramount)
- [tierWinners](./interface/ILottery.md#tierwinners)
- [getUnderlyingTicket](./Lottery.md#getunderlyingticket)
- [getTier](./Lottery.md#gettier)
- [getAllTiers](./Lottery.md#getalltiers)
- [getAllOrganizations](./Lottery.md#getallorganizations)
- [getTiersCount](./Lottery.md#gettierscount)
- [getOrganizationsCount](./Lottery.md#getorganizationscount)
- [getOrganizationTicketsContracts](./Lottery.md#getorganizationticketscontracts)
- [getOrganizationSharesForFixedTiers](./Lottery.md#getorganizationsharesforfixedtiers)
- [getAllCampaignTickets](./Lottery.md#getallcampaigntickets)

## RandomGetter

- [requestIds](./interface/IRandomGetter.md#requestids)
- [randomNumbersByRequestId](./interface/IRandomGetter.md#randomnumbersbyrequestid)
- [requestRandomNumber](./RandomGetter.md#requestrandomnumber)
- [getRandomNumber](./RandomGetter.md#getrandomnumber) (by id)
- [getRandomNumber](./RandomGetter.md#getrandomnumber-1) (by address)

## TicketRedemption

- [redeem](./TicketRedemption.md#redeem)