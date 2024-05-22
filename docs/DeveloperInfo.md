## KarrotFactory

- [ticketsCampaign](./interface/IKarrotFactory.md#ticketscampaign)
- [campaignOrganization](./interface/IKarrotFactory.md#campaignorganization)
- [getAllLotteries](./interface/IKarrotFactory.md#getalllotteries)
- [getAllRedemptions](./interface/IKarrotFactory.md#getallredemptions)
- [getAllOrganizations](./interface/IKarrotFactory.md#getallorganizations)
- [getAllCampaigns](./interface/IKarrotFactory.md#getallcampaigns)
- [getAllTickets](./interface/IKarrotFactory.md#getalltickets)
- [getLotteriesCount](./interface/IKarrotFactory.md#getlotteriescount)
- [getRedemptionsCount](./interface/IKarrotFactory.md#getredemptionscount)
- [getOrganizationsCount](./interface/IKarrotFactory.md#getorganizationscount)
- [getCampaignsCount](./interface/IKarrotFactory.md#getcampaignscount)
- [getTicketsCount](./interface/IKarrotFactory.md#getticketscount)

## KarrotOrganization

- [ownerToken](./interface/IKarrotOrganization.md#ownertoken)
- [mintTo](./interface/IKarrotOrganization.md#mintto)
- [ownerOf](./KarrotOrganization.md#ownerof)

## KarrotCampaign

- [ownerToken](./interface/IKarrotCampaign.md#ownertoken)
- [mintToOrganization](./interface/IKarrotCampaign.md#minttoorganization)
- [burnTicket](./interface/IKarrotCampaign.md#burnticket) (two functions)
- [burnTicketBatch](./interface/IKarrotCampaign.md#burnticketbatch) (two functions)
- [ownerOf](./KarrotCampaign.md#ownerof)
- [getLotteryContract](./interface/IKarrotCampaign.md#getlotterycontract)
- [getUserCampaignId](./interface/IKarrotCampaign.md#getusercampaignid)

## KarrotTicket

- [mintToCampaign](./interface/IKarrotTicket.md#minttocampaign)
- [mintToCampaignBatch](./interface/IKarrotTicket.md#minttocampaignbatch)
- [burnLastTicket](./interface/IKarrotTicket.md#burnlastticket)
- [getLotteryContract](./interface/IKarrotTicket.md#getlotterycontract)
- [ownerOf](./KarrotTicket.md#ownerof)
- [getOrganisation](./interface/IKarrotTicket.md#getorganisation)
- [getUserTicketIds](./interface/IKarrotTicket.md#getuserticketids)

## TicketMinter

- [MINTER_ROLE](./base/KarrotErc7401Base.md#minter_role)
- [mintTicketsBatch](./interface/ITicketMinter.md#mintticketsbatch)
- [mintTickets](./interface/ITicketMinter.md#minttickets)

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
- [getUnderlyingTicket](./interface/ILottery.md#getunderlyingticket)
- [getTier](./interface/ILottery.md#gettier)
- [getAllTiers](./interface/ILottery.md#getalltiers)
- [getAllOrganizations](./interface/ILottery.md#getallorganizations)
- [getTiersCount](./interface/ILottery.md#gettierscount)
- [getOrganizationsCount](./interface/ILottery.md#getorganizationscount)
- [getOrganizationTicketsContracts](./interface/ILottery.md#getorganizationticketscontracts)
- [getOrganizationSharesForFixedTiers](./interface/ILottery.md#getorganizationsharesforfixedtiers)
- [getAllCampaignTickets](./interface/ILottery.md#getallcampaigntickets)

## RandomGetter

- [requestIds](./interface/IRandomGetter.md#requestids)
- [randomNumbersByRequestId](./interface/IRandomGetter.md#randomnumbersbyrequestid)
- [requestRandomNumber](./interface/IRandomGetter.md#requestrandomnumber)
- [getRandomNumber](./interface/IRandomGetter.md#getrandomnumber) (two functions)

## TicketRedemption

- [redeem](./interface/ITicketRedemption.md#redeem)