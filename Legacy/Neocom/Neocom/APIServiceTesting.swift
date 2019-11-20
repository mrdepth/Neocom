//
//  APIServiceTesting.swift
//  Neocom
//
//  Created by Artem Shimanski on 15/12/2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI
import Futures

#if DEBUG

class APIServiceTesting: APIService {
	override func make(for account: Account?) -> API {
		let esi = ESI(token: account?.oAuth2Token, clientID: Config.current.esi.clientID, secretKey: Config.current.esi.secretKey, server: .tranquility)
		return APITesting(esi: esi)
	}

}

class APITesting: APIClient {
	
	override func serverStatus(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<ESI.Status.ServerStatus>> {
		let value = ESI.Status.ServerStatus(players: 0, serverVersion: "1", startTime: Date(), vip: false)
		return .init(ESI.Result(value: value, expires: Date(timeIntervalSinceNow: 60), metadata: nil))
	}
	
	override func openOrders(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Market.CharacterOrder]>> {
		return Services.sde.performBackgroundTask { context -> ESI.Result<[ESI.Market.CharacterOrder]> in
			let solarSystem = try! context.managedObjectContext.from(SDEMapSolarSystem.self).first()!
			let orders = [ESI.Market.CharacterOrder(duration: 3600 * 2, escrow: 1000, isBuyOrder: true, isCorporation: false, issued: Date.init(timeIntervalSinceNow: -3600), locationID: Int64(solarSystem.solarSystemID), minVolume: 1000, orderID: 1, price: 1000, range: ESI.Market.CharacterOrder.GetCharactersCharacterIDOrdersRange.solarsystem, regionID: Int(solarSystem.constellation!.region!.regionID), typeID: 645, volumeRemain: 50, volumeTotal: 10000),
						  ESI.Market.CharacterOrder(duration: 3600*3, escrow: 1000, isBuyOrder: false, isCorporation: false, issued: Date.init(timeIntervalSinceNow: -3600), locationID: Int64(solarSystem.solarSystemID), minVolume: 1000, orderID: 1, price: 1000, range: ESI.Market.CharacterOrder.GetCharactersCharacterIDOrdersRange.solarsystem, regionID: Int(solarSystem.constellation!.region!.regionID), typeID: 645, volumeRemain: 50, volumeTotal: 10000)]
			return ESI.Result(value: orders, expires: nil, metadata: nil)
		}
	}
	
	override func industryJobs(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Industry.Job]>> {
		return Services.sde.performBackgroundTask { context -> ESI.Result<[ESI.Industry.Job]> in
			let station = try! context.managedObjectContext.from(SDEStaStation.self).first()!
			let activities = try! context.managedObjectContext.from(SDERamActivity.self).fetch()
			let blueprint = context.invType("Dominix Blueprint")!
			let locationID = Int64(station.stationID)
			
			let jobs = [
				
				ESI.Industry.Job(activityID: Int(activities.first!.activityID), blueprintID: 1, blueprintLocationID: locationID, blueprintTypeID: Int(blueprint.typeID), completedCharacterID: nil, completedDate: nil, cost: 1000, duration: 3600 * 2, endDate: Date.init(timeIntervalSinceNow: 3600), facilityID: locationID, installerID: 0, jobID: 0, licensedRuns: 1, outputLocationID: locationID, pauseDate: nil, probability: 1, productTypeID: nil, runs: 1, startDate: Date.init(timeIntervalSinceNow: -3600), stationID: locationID, status: .active, successfulRuns: 1),
				
				ESI.Industry.Job(activityID: Int(activities.first!.activityID), blueprintID: 1, blueprintLocationID: locationID, blueprintTypeID: Int(blueprint.typeID), completedCharacterID: nil, completedDate: nil, cost: 1000, duration: 3600 * 23, endDate: Date.init(timeIntervalSinceNow: -3600), facilityID: locationID, installerID: 0, jobID: 1, licensedRuns: 10, outputLocationID: locationID, pauseDate: nil, probability: 1, productTypeID: nil, runs: 10, startDate: Date.init(timeIntervalSinceNow: -3600 * 24), stationID: locationID, status: .delivered, successfulRuns: 10)
				
			]
			
			return ESI.Result(value: jobs, expires: nil, metadata: nil)
		}
	}
	
	override func contracts(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Contracts.Contract]>> {
		return Services.sde.performBackgroundTask { context -> ESI.Result<[ESI.Contracts.Contract]> in
			let characterID = try! Services.storage.performBackgroundTask {context in Int(context.currentAccount?.characterID ?? 0)}.get()
			
			let station = Int64((try! context.managedObjectContext.from(SDEStaStation.self).first()!).stationID)
			
			let contracts = [
				ESI.Contracts.Contract(acceptorID: characterID, assigneeID: characterID, availability: .personal, buyout: 1000, collateral: 40, contractID: 1, dateAccepted: nil, dateCompleted: nil, dateExpired: Date(timeIntervalSinceNow: 3600), dateIssued: Date(timeIntervalSinceNow: -3600 * 23), daysToComplete: 1, endLocationID: station, forCorporation: false, issuerCorporationID: 0, issuerID: characterID, price: 1000, reward: 100, startLocationID: station, status: .inProgress, title: "Test Contract 1", type: .courier, volume: 100),
				
				ESI.Contracts.Contract(acceptorID: characterID, assigneeID: characterID, availability: .personal, buyout: 10000, collateral: 40, contractID: 1, dateAccepted: Date(timeIntervalSinceNow: -3600), dateCompleted: Date(timeIntervalSinceNow: -3600/2), dateExpired: Date(timeIntervalSinceNow: 3600), dateIssued: Date.init(timeIntervalSinceNow: -3600 * 24 * 2), daysToComplete: 3, endLocationID: station, forCorporation: false, issuerCorporationID: 0, issuerID: characterID, price: 1000, reward: 100, startLocationID: station, status: .finished, title: "Test Contract 2", type: .auction, volume: 100)
			]
			return ESI.Result(value: contracts, expires: nil, metadata: nil)
		}
	}
	
	override func contractItems(contractID: Int64, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Contracts.Item]>> {
		let value = [ESI.Contracts.Item(isIncluded: true, isSingleton: false, quantity: 1, rawQuantity: 1, recordID: 1, typeID: 645),
					 ESI.Contracts.Item(isIncluded: false, isSingleton: false, quantity: 10, rawQuantity: 10, recordID: 2, typeID: 34)]
		return .init(ESI.Result(value: value, expires: nil, metadata: nil))
		
	}
	
	override func contractBids(contractID: Int64, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Contracts.Bid]>> {
		return Services.storage.performBackgroundTask {context -> ESI.Result<[ESI.Contracts.Bid]> in
			let characterID = Int(context.currentAccount?.characterID ?? 0)
			let value = [ESI.Contracts.Bid(amount: 100, bidID: 1, bidderID: characterID, dateBid: Date.init(timeIntervalSinceNow: -3600 * 24)),
						 ESI.Contracts.Bid(amount: 1000, bidID: 1, bidderID: characterID, dateBid: Date.init(timeIntervalSinceNow: -3600 * 12))]
			return ESI.Result(value: value, expires: nil, metadata: nil)
		}
	}
	
	override func walletJournal(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Wallet.WalletJournalItem]>> {
		let value = [
			ESI.Wallet.WalletJournalItem(amount: 1000, balance: 1000000, contextID: 1, contextIDType: .characterID, date: Date(timeIntervalSinceNow: -3600), localizedDescription: "Test Item 1", firstPartyID: nil, id: 1, reason: "Reason", refType: .agentDonation, secondPartyID: nil, tax: 10, taxReceiverID: nil),
			ESI.Wallet.WalletJournalItem(amount: 1000, balance: 1000000, contextID: 1, contextIDType: .characterID, date: Date(timeIntervalSinceNow: -3600 * 24), localizedDescription: "Test Item 1", firstPartyID: nil, id: 1, reason: "Reason", refType: .agentDonation, secondPartyID: nil, tax: 10, taxReceiverID: nil),
			ESI.Wallet.WalletJournalItem(amount: 1000, balance: 1000000, contextID: 1, contextIDType: .characterID, date: Date(timeIntervalSinceNow: -3600 * 25), localizedDescription: "Test Item 1", firstPartyID: nil, id: 1, reason: "Reason", refType: .agentDonation, secondPartyID: nil, tax: 10, taxReceiverID: nil),
			ESI.Wallet.WalletJournalItem(amount: 1000, balance: 1000000, contextID: 1, contextIDType: .characterID, date: Date(timeIntervalSinceNow: -3600 * 50), localizedDescription: "Test Item 1", firstPartyID: nil, id: 1, reason: "Reason", refType: .agentDonation, secondPartyID: nil, tax: 10, taxReceiverID: nil)]
		return .init(ESI.Result(value: value, expires: nil, metadata: nil))
	}
	
	override func walletTransactions(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Wallet.Transaction]>> {
		return Services.sde.performBackgroundTask { context -> ESI.Result<[ESI.Wallet.Transaction]> in
			let characterID = try! Services.storage.performBackgroundTask {context in Int(context.currentAccount?.characterID ?? 0)}.get()
			let station = Int64((try! context.managedObjectContext.from(SDEStaStation.self).first()!).stationID)
			
			let value = [ESI.Wallet.Transaction(clientID: characterID, date: Date(timeIntervalSinceNow: -3600), isBuy: true, isPersonal: true, journalRefID: 1, locationID: station, quantity: 1, transactionID: 1, typeID: 645, unitPrice: 100),
						 ESI.Wallet.Transaction(clientID: characterID, date: Date(timeIntervalSinceNow: -3600 * 12), isBuy: true, isPersonal: true, journalRefID: 1, locationID: station, quantity: 1, transactionID: 1, typeID: 645, unitPrice: 100),
						 ESI.Wallet.Transaction(clientID: characterID, date: Date(timeIntervalSinceNow: -3600 * 24), isBuy: true, isPersonal: true, journalRefID: 1, locationID: station, quantity: 1, transactionID: 1, typeID: 645, unitPrice: 100),
						 ESI.Wallet.Transaction(clientID: characterID, date: Date(timeIntervalSinceNow: -3600 * 32), isBuy: true, isPersonal: true, journalRefID: 1, locationID: station, quantity: 1, transactionID: 1, typeID: 645, unitPrice: 100)]
			
			return ESI.Result(value: value, expires: nil, metadata: nil)
		}
	}
	
	override func killmails(page: Int?, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Killmails.Recent]>> {
		let killmails = [[ESI.Killmails.Recent(killmailHash: "efdb83e99260384589123b1a57a3655de3641937", killmailID: 45560841),
						  //						  ESI.Killmails.Recent(killmailHash: "f8ffc770033a08e65a34632dedad0e31e72f17d5", killmailID: 45560150),
			//						  ESI.Killmails.Recent(killmailHash: "29ad254d50bf5441ad9bc88905ba70f538f92b5d", killmailID: 45560149),
			//						  ESI.Killmails.Recent(killmailHash: "454fb2665b2a0b3caf79d514c8e243698dc5c450", killmailID: 41319377),
			//						  ESI.Killmails.Recent(killmailHash: "179c08c241c44708345bbfba16dbd5c2c0c92672", killmailID: 22855674),
			//						  ESI.Killmails.Recent(killmailHash: "9391667ed550122012a4c5c905c7125be6e9b390", killmailID: 22855653),
			//						  ESI.Killmails.Recent(killmailHash: "7461ee7dc068a5a8e38b7a33c86d5a1daf42eaa6", killmailID: 22555322),
			//						  ESI.Killmails.Recent(killmailHash: "ead9868acb601ad5c5ccbac55c9540d89fd907b7", killmailID: 22425400),
			//						  ESI.Killmails.Recent(killmailHash: "9a8ff6cb0a263c22cbd061a0e7ad46c7dbd8c273", killmailID: 22425359),
			//						  ESI.Killmails.Recent(killmailHash: "0d43aa624ed5ffbf96093fe1369987068d57c2d6", killmailID: 22271902),
			//						  ESI.Killmails.Recent(killmailHash: "c9e56846f73b4cb82c3868e91d173bec99c7d630", killmailID: 22044992),
			//						  ESI.Killmails.Recent(killmailHash: "328acec61a214a767fe0c4b113770fe5bdc29bd6", killmailID: 21694267),
			//						  ESI.Killmails.Recent(killmailHash: "199cf3e15eb0838e12fdb14441b32148dab9485a", killmailID: 21692061),
			//						  ESI.Killmails.Recent(killmailHash: "8e0b0178c8b66df32f337713bd344b0ca92f7308", killmailID: 21580394),
			//						  ESI.Killmails.Recent(killmailHash: "161093ae9991927f77f3af02a82b7c945a560698", killmailID: 21580365),
			//						  ESI.Killmails.Recent(killmailHash: "d396c18bfd7ba8a7720066f8553120f208ed1508", killmailID: 20670536),
			//						  ESI.Killmails.Recent(killmailHash: "ad5d689c6c454e6a433a547a9669fef39e34402d", killmailID: 20651988),
			//						  ESI.Killmails.Recent(killmailHash: "cfdf3fcd83d5a970148ce51272d5ead21db7a7ee", killmailID: 20651966),
			//						  ESI.Killmails.Recent(killmailHash: "d7df6240cee794710839b78da936d8f6a1c33f65", killmailID: 20651176),
			ESI.Killmails.Recent(killmailHash: "5da34e22ad57076268245d81259bf493e099ed29", killmailID: 20528926)],
						 [ESI.Killmails.Recent(killmailHash: "8cb34090a8421573f04b01e494ef95e5a45ac52d", killmailID: 20260582),
						  //						  ESI.Killmails.Recent(killmailHash: "0b9f0b0e795cd96ea4b538f6252788f2e5d78b78", killmailID: 20235343),
							//						  ESI.Killmails.Recent(killmailHash: "25d09ce03d6aee6ace8923c127882f04595cf1d9", killmailID: 20094091),
							//						  ESI.Killmails.Recent(killmailHash: "d50706f96ee2125237727d80936117fab87cafef", killmailID: 20094083),
							//						  ESI.Killmails.Recent(killmailHash: "0240a30a4d3e66030108f084463ad0ac582f0768", killmailID: 20093815),
							//						  ESI.Killmails.Recent(killmailHash: "ed40e7c62b5425f969c06db9f230272e139f71d6", killmailID: 20093713),
							//						  ESI.Killmails.Recent(killmailHash: "d789d850011401db7fe5d886ebbd2f2a3463d8a8", killmailID: 20017378),
							//						  ESI.Killmails.Recent(killmailHash: "8e9569109a1b71390cf2b1584ccd34a4956fb3dc", killmailID: 20017253),
							//						  ESI.Killmails.Recent(killmailHash: "85f9e729baa46c472d93eee77fac8317324d090a", killmailID: 20017250),
							//						  ESI.Killmails.Recent(killmailHash: "661a5e01fc2fa5aa3921b1ff96deacf136e4c8a8", killmailID: 20017167),
							//						  ESI.Killmails.Recent(killmailHash: "f1ce232dafee19a098d2fe50fd7a5ab83dd030ab", killmailID: 20016632),
							//						  ESI.Killmails.Recent(killmailHash: "f7863fe81b5ede0ffce60a709afad81bdb6d923a", killmailID: 20016615),
							//						  ESI.Killmails.Recent(killmailHash: "51d02e4807418d2c16b880d388531a4895206dfa", killmailID: 20016507),
							//						  ESI.Killmails.Recent(killmailHash: "0141d78545a5d88de0d03ec28f970190616d9cd3", killmailID: 20016494),
							//						  ESI.Killmails.Recent(killmailHash: "688a576aafce981fe1015d0a0cb494833e888edb", killmailID: 20016457),
							//						  ESI.Killmails.Recent(killmailHash: "d0233fe4f31b33819c5aa1cafd626df215288ac1", killmailID: 20016448),
							//						  ESI.Killmails.Recent(killmailHash: "8d7e100bf72ef7f1b4400d8511767cdd12c456d3", killmailID: 20015608),
							//						  ESI.Killmails.Recent(killmailHash: "32e141f06bb900da2495eab525acc5ffa81dc3c4", killmailID: 20006134),
							//						  ESI.Killmails.Recent(killmailHash: "88ee0b163878c6270117b019dede18305db66f4d", killmailID: 20006102),
							ESI.Killmails.Recent(killmailHash: "79e01350497c7263c132e051188acb78b546e676", killmailID: 20004908)],
						 [ESI.Killmails.Recent(killmailHash: "5eb318ddf1c29554ad58f8e950a87f2d646c7b27", killmailID: 20004886),
						  //						  ESI.Killmails.Recent(killmailHash: "442f9a058fe34bba9766f3be810e6dfa04686d5c", killmailID: 19993060),
							//						  ESI.Killmails.Recent(killmailHash: "6b436f8345450f0bb9da9fa1b8b095a56a0dc0ec", killmailID: 19993055),
							//						  ESI.Killmails.Recent(killmailHash: "e22b413fcdf2a930dbd4da6d35f0632272aa43b8", killmailID: 19993015),
							//						  ESI.Killmails.Recent(killmailHash: "b647257c51f32049336d0c6b99929d485b21ba65", killmailID: 19992787),
							//						  ESI.Killmails.Recent(killmailHash: "5ae2443cd77eeca2a6a363d33bbd757b720a03d4", killmailID: 19992540),
							//						  ESI.Killmails.Recent(killmailHash: "d6df5de283ecdb04ade71294e11652a07261790d", killmailID: 19992388),
							//						  ESI.Killmails.Recent(killmailHash: "a95c9bd3ee93df4db9d673170a5ab97b3d946972", killmailID: 19992118),
							//						  ESI.Killmails.Recent(killmailHash: "95691e8dc6db2ef2efa1541f488d9aa017b15277", killmailID: 19991553),
							//						  ESI.Killmails.Recent(killmailHash: "cb9e78594e413e05f91d3ecfcc82d887bbffd411", killmailID: 19991494),
							//						  ESI.Killmails.Recent(killmailHash: "5053e3ce7378ad770c721cf97110a10c17166aed", killmailID: 19991490),
							//						  ESI.Killmails.Recent(killmailHash: "ebd41809beb716489c63d5a61c1b00154195c180", killmailID: 19990541),
							//						  ESI.Killmails.Recent(killmailHash: "0b956c3b565a06cfba6dc90bf9e97adf34003256", killmailID: 19990524),
							//						  ESI.Killmails.Recent(killmailHash: "62b40223aaaacc1bd45ab2ac0fa511a25e4a10f8", killmailID: 19723501),
							//						  ESI.Killmails.Recent(killmailHash: "f384e8f72f41a9b5e26bd6c6e1e7a26e5dc9cf6c", killmailID: 19722359),
							//						  ESI.Killmails.Recent(killmailHash: "2115e5c5b611dfc131e074d77075863c5bcddec7", killmailID: 19228046),
							//						  ESI.Killmails.Recent(killmailHash: "333f2815bd7bbc1f5c84e2b12ce0f092ad532ee3", killmailID: 19228006),
							//						  ESI.Killmails.Recent(killmailHash: "2edb2248c9bb38aff537972adff73b3949b1ed98", killmailID: 19227820),
							//						  ESI.Killmails.Recent(killmailHash: "5fd09a102de306e540ea81ef29abfc2b9ccc5cfe", killmailID: 19227793),
							ESI.Killmails.Recent(killmailHash: "edce860bcd4e091740fed7cb7969be6dbe9be06c", killmailID: 19227706)],
						 [ESI.Killmails.Recent(killmailHash: "ad32a8d373881eda8adcb17567c175b7ff6995e5", killmailID: 19227673),
						  //						  ESI.Killmails.Recent(killmailHash: "6951ede344b33a90a29f6c6ad21e8971d7a8e4cb", killmailID: 19227628),
							//						  ESI.Killmails.Recent(killmailHash: "c6b2db007029c574be635df9467beabf6ed7416d", killmailID: 19227086),
							//						  ESI.Killmails.Recent(killmailHash: "ac1f466158cdcc6d8437ad2517a78d0db7d7ffe8", killmailID: 19226715),
							//						  ESI.Killmails.Recent(killmailHash: "b38663844fc538c3d631f56e0ccf18a05031be2f", killmailID: 19226676),
							//						  ESI.Killmails.Recent(killmailHash: "42dc609a48f66ab76c1e66b4d93b158cd4eb64c8", killmailID: 19226583),
							//						  ESI.Killmails.Recent(killmailHash: "c7858520df56383719a8d67ecbc1cee69ae5c9ab", killmailID: 18702408),
							//						  ESI.Killmails.Recent(killmailHash: "e2383e281d4002066b7e6f4318b7c48aaf58c971", killmailID: 18549694),
							//						  ESI.Killmails.Recent(killmailHash: "d7c1e7ffb52e2bf1993fcbfed85754a009d6c77e", killmailID: 18456533),
							//						  ESI.Killmails.Recent(killmailHash: "55ca2684d1452181006c28074867b345e74d895f", killmailID: 18266339),
							//						  ESI.Killmails.Recent(killmailHash: "6792608440c49ab0c6f6862510403ca99189176c", killmailID: 18266334),
							//						  ESI.Killmails.Recent(killmailHash: "e91a034a5787d18e9338d4ae1d8c533e5bc29932", killmailID: 18192425),
							//						  ESI.Killmails.Recent(killmailHash: "069927b0061e3adcd6af3496f4ba37fd4163979b", killmailID: 18160202),
							//						  ESI.Killmails.Recent(killmailHash: "4930d269c28379776814cb6c17f7094949982301", killmailID: 18047929),
							//						  ESI.Killmails.Recent(killmailHash: "dcc57407358b88ee0874002655173fbd01abc3ff", killmailID: 18047747),
							//						  ESI.Killmails.Recent(killmailHash: "45d127eae96d99c861741af961ef2ea462a58c6a", killmailID: 18047492),
							//						  ESI.Killmails.Recent(killmailHash: "f5cf3b801b15f6bef92ca28fafee07b2cb29892f", killmailID: 18046284),
							//						  ESI.Killmails.Recent(killmailHash: "39f339e0220d8864f7dd53296d2ea66be9e2f861", killmailID: 17929797),
							//						  ESI.Killmails.Recent(killmailHash: "b51aed7c724f8fc4194c6300c41f36e716af04f1", killmailID: 17912469),
							ESI.Killmails.Recent(killmailHash: "988d7ee16d4621eb1e5ba3340aafe99887fa7288", killmailID: 17911835)],
						 [ESI.Killmails.Recent(killmailHash: "fa31d3951b476a9abb4e8a836677400c632011ba", killmailID: 17909861),
						  //						  ESI.Killmails.Recent(killmailHash: "292dc20ea99dd4ba6301a8d3d6c7fafd29ca0479", killmailID: 17823858),
							//						  ESI.Killmails.Recent(killmailHash: "9abfa64d07da6466fec807e38ba346ad6ef680fb", killmailID: 17753934),
							//						  ESI.Killmails.Recent(killmailHash: "cca4e388e5b4811a5867b102597d805c18a8c643", killmailID: 17357983),
							//						  ESI.Killmails.Recent(killmailHash: "0856af7ac76b89b2bb591a6395a2473435a4649d", killmailID: 17357968),
							//						  ESI.Killmails.Recent(killmailHash: "5ad136f4beaccab409d2ab83f748c1f43145bc9c", killmailID: 17216734),
							//						  ESI.Killmails.Recent(killmailHash: "5ace5d23c3c26e21833aee614674b15dc302dbf1", killmailID: 17199050),
							//						  ESI.Killmails.Recent(killmailHash: "ebdd139bfb95dc5ef7ec9f263b21a244997765e3", killmailID: 17198997),
							//						  ESI.Killmails.Recent(killmailHash: "fbdf389a04ef73bfe01c675c7689c7bf76a9902a", killmailID: 17197288),
							//						  ESI.Killmails.Recent(killmailHash: "e24153813cdd602767d8c57cc9177db0529b49e2", killmailID: 17177435),
							//						  ESI.Killmails.Recent(killmailHash: "318934af09c6b69eaf1559add1817af4a09db539", killmailID: 17146086),
							//						  ESI.Killmails.Recent(killmailHash: "34dea32e3a10119653d398f35d3f13b974980b6f", killmailID: 17146079),
							//						  ESI.Killmails.Recent(killmailHash: "a3d8ba67ab493e0439621e8450c1f58a64043189", killmailID: 16962950),
							//						  ESI.Killmails.Recent(killmailHash: "6a40f778a7850e49098846604195c59ad334bccd", killmailID: 15449858),
							//						  ESI.Killmails.Recent(killmailHash: "bdefead924c961b30ea03346f54442b3abece1f7", killmailID: 15417173),
							//						  ESI.Killmails.Recent(killmailHash: "c24704b8676a61b9779ff76cb7c0281e2af1ae67", killmailID: 15318134),
							//						  ESI.Killmails.Recent(killmailHash: "3c75c03a38c7413861fce7e8f15b033a01674975", killmailID: 15315140),
							//						  ESI.Killmails.Recent(killmailHash: "bda2cf4e57555cd294fd4b1abfa4f2f03ced9ee8", killmailID: 15272883),
							//						  ESI.Killmails.Recent(killmailHash: "12fd738f83ca34bb878f316ea1fed627cc05c44c", killmailID: 15261558),
							ESI.Killmails.Recent(killmailHash: "d933e2baa7ec13f55f9f2907739c38593728ebd4", killmailID: 15149922)],
						 [ESI.Killmails.Recent(killmailHash: "6f3a3c2e89a91a1276828de58d3f3c5b7cb316ef", killmailID: 15138881),
						  //						  ESI.Killmails.Recent(killmailHash: "328f98d008ad866a2b2d2d7aac74c84ec25b0672", killmailID: 15138868),
							//						  ESI.Killmails.Recent(killmailHash: "2879725bf50c18ee456008b0d87534c13e104081", killmailID: 14995414),
							//						  ESI.Killmails.Recent(killmailHash: "62c39aee3fd3823154ad7d690e85ea11726f1800", killmailID: 14933564),
							//						  ESI.Killmails.Recent(killmailHash: "11bf50e9c553b3ef17758efaeced924337d8ddfa", killmailID: 14933555),
							//						  ESI.Killmails.Recent(killmailHash: "a53db2e6eddd38063068f39990b1bd0debb861d7", killmailID: 14887581),
							//						  ESI.Killmails.Recent(killmailHash: "406076c479ae2f99fb1054dc975cdb87804ca00c", killmailID: 14577895),
							//						  ESI.Killmails.Recent(killmailHash: "2434b5400b8881819e19f3f25691879d1461a8da", killmailID: 14379843),
							//						  ESI.Killmails.Recent(killmailHash: "a07b6f7927a057df86ebdf16f65253cfb06f3043", killmailID: 14379829),
							//						  ESI.Killmails.Recent(killmailHash: "fa03bb508ed171a9791134103327ce4047b33460", killmailID: 14379819),
							//						  ESI.Killmails.Recent(killmailHash: "2bbda385c959a3aabfbbab7a63bc69d2ba1e8d1d", killmailID: 14379807),
							//						  ESI.Killmails.Recent(killmailHash: "78adb51cce39e2bed7ce471b9515c0d9334f740f", killmailID: 14379161),
							//						  ESI.Killmails.Recent(killmailHash: "43b0562b8ec6a28aa0c6bc0f3b84f149519218f6", killmailID: 14176265),
							//						  ESI.Killmails.Recent(killmailHash: "0ee261c10780ed23b393f578201b885c1b0f5c90", killmailID: 14176247),
							//						  ESI.Killmails.Recent(killmailHash: "3bf94daf279d159cfdd91a1e775745edba2ff4c9", killmailID: 14077407),
							//						  ESI.Killmails.Recent(killmailHash: "5fc4ff38c2adf2569180a1fb064b27ff12995d52", killmailID: 13880842),
							//						  ESI.Killmails.Recent(killmailHash: "52fcd179da689d9096e4e68f5eaf6116407b77d7", killmailID: 13407928),
							//						  ESI.Killmails.Recent(killmailHash: "d3a325d227e801a87ff24ffbbdec7fce06accaab", killmailID: 13332045),
							//						  ESI.Killmails.Recent(killmailHash: "270c842cb6f7de0b8f1c5bf6cff545c350fb4e5f", killmailID: 13297664),
							ESI.Killmails.Recent(killmailHash: "559a226865863fc99ba4964a0ae3d249afd9a1fe", killmailID: 12429912)],
						 [ESI.Killmails.Recent(killmailHash: "0b56cfce9255eae6623fd0f3f17af36db4e3f8bc", killmailID: 12363310),
						  ESI.Killmails.Recent(killmailHash: "1a6e4dba56259753b932d457ee4bc34a0a292571", killmailID: 11587535)]]
		return .init(ESI.Result(value: killmails[(page ?? 1) - 1], expires: .distantFuture, metadata: ["x-pages" : "\(killmails.count)"]))
	}
}

#endif
