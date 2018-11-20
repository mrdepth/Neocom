//
//  MainMenuPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 27.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController
import Futures
import EVEAPI
import CloudData

class MainMenuPresenter: TreePresenter {
	typealias View = MainMenuViewController
	typealias Interactor = MainMenuInteractor
	typealias Presentation = [AnyTreeItem]
	
	weak var view: View?
	lazy var interactor: Interactor! = Interactor(presenter: self)
	
	var presentation: Presentation?
	var loading: Future<Presentation>?
	
	required init(view: View) {
		self.view = view
	}
	
	func configure() {
		view?.tableView.register([Prototype.TreeSectionCell.default,
								 Prototype.TreeDefaultCell.default])

		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		let account = Services.storage.viewContext.currentAccount
		let api = interactor.api
		func characterSheet() -> Future<ESI.Result<Tree.Content.Default>> {
			return api.skills(cachePolicy: .useProtocolCachePolicy).then {$0.map { skills -> Tree.Content.Default in
				let subtitle = UnitFormatter.localizedString(from: skills.totalSP, unit: .skillPoints, style: .long)
				return Tree.Content.Default(title:NSLocalizedString("Character Sheet", comment: ""), subtitle: subtitle, image: Image( #imageLiteral(resourceName: "charactersheet")))
			}}
		}
		
		let menu = [Tree.Item.SimpleSection(title: NSLocalizedString("Character", comment: "").uppercased(),
																   treeController: view?.treeController,
																   children: [
																	Tree.Item.MainMenuAPIRow(title: NSLocalizedString("Character Sheet", comment: ""),
																							 image: Image( #imageLiteral(resourceName: "charactersheet")),
																							 account: account,
																							 value: characterSheet(),
																							 treeController: view?.treeController,
																							 route: Router.Character.characterInfo(),
																							 require: [.esiWalletReadCharacterWalletV1,
																									   .esiSkillsReadSkillsV1,
																									   .esiLocationReadLocationV1,
																									   .esiLocationReadShipTypeV1,
																									   .esiClonesReadImplantsV1]),
																	Tree.Item.MainMenuAPIRow(title: NSLocalizedString("Jump Clones", comment: ""),
																							 image: Image( #imageLiteral(resourceName: "jumpclones")),
																							 account: account,
//																							 value: characterSheet(),
																							 treeController: view?.treeController,
																							 route: Router.Character.jumpClones(),
																							 require: [.esiClonesReadClonesV1,
																									   .esiClonesReadImplantsV1]),
																	Tree.Item.MainMenuAPIRow(title: NSLocalizedString("Skills", comment: ""),
																							 image: Image( #imageLiteral(resourceName: "skills")),
																							 account: account,
//																							 value: characterSheet(),
																							 treeController: view?.treeController,
																							 route: Router.Character.skills(),
																							 require: [.esiSkillsReadSkillqueueV1,
																									   .esiSkillsReadSkillsV1,
																									   .esiClonesReadImplantsV1]),
																	Tree.Item.MainMenuAPIRow(title: NSLocalizedString("EVE Mail", comment: ""),
																							 image: Image( #imageLiteral(resourceName: "evemail")),
																							 account: account,
//																							 value: characterSheet(),
																							 treeController: view?.treeController,
																							 route: Router.MainMenu.mail(),
																							 require: [.esiMailReadMailV1,
																									   .esiMailSendMailV1,
																									   .esiMailOrganizeMailV1]),
																	Tree.Item.MainMenuAPIRow(title: NSLocalizedString("Calendar", comment: ""),
																							 image: Image( #imageLiteral(resourceName: "calendar")),
																							 account: account,
//																							 value: characterSheet(),
																							 treeController: view?.treeController,
																							 route: nil,
																							 require: [.esiCalendarReadCalendarEventsV1,
																									   .esiCalendarRespondCalendarEventsV1]),
																	Tree.Item.MainMenuAPIRow(title: NSLocalizedString("Wealth", comment: ""),
																							 image: Image( #imageLiteral(resourceName: "folder")),
																							 account: account,
//																							 value: characterSheet(),
																							 treeController: view?.treeController,
																							 route: nil,
																							 require: [.esiWalletReadCharacterWalletV1,
																									   .esiAssetsReadAssetsV1]),
																	Tree.Item.MainMenuAPIRow(title: NSLocalizedString("Loyalty Points", comment: ""),
																							 image: Image( #imageLiteral(resourceName: "lpstore")),
																							 account: account,
//																							 value: characterSheet(),
																							 treeController: view?.treeController,
																							 route: nil,
																							 require: [.esiCharactersReadLoyaltyV1])

																	].compactMap{$0}).asAnyItem,
					Tree.Item.SimpleSection(title: NSLocalizedString("Database", comment: "").uppercased(),
																   treeController: view?.treeController,
																   children: [
																	Tree.Item.MainMenuRow(title: NSLocalizedString("Database", comment: ""), image: Image( #imageLiteral(resourceName: "items")), route: Router.SDE.invCategories()),
																	Tree.Item.MainMenuRow(title: NSLocalizedString("Certificates", comment: ""), image: Image( #imageLiteral(resourceName: "certificates")), route: Router.SDE.certGroups()),
																	Tree.Item.MainMenuRow(title: NSLocalizedString("Market", comment: ""), image: Image( #imageLiteral(resourceName: "market")), route: Router.SDE.invMarket()),
																	Tree.Item.MainMenuRow(title: NSLocalizedString("NPC", comment: ""), image: Image( #imageLiteral(resourceName: "criminal")), route: Router.MainMenu.npc()),
																	Tree.Item.MainMenuRow(title: NSLocalizedString("Wormholes", comment: ""), image: Image( #imageLiteral(resourceName: "terminate")), route: Router.SDE.whTypes()),
																	Tree.Item.MainMenuRow(title: NSLocalizedString("Incursions", comment: ""), image: Image( #imageLiteral(resourceName: "incursions")), route: Router.MainMenu.incursion())
						]).asAnyItem,
					Tree.Item.SimpleSection(title: NSLocalizedString("Business", comment: "").uppercased(),
																	  treeController: view?.treeController,
																	  children: [
																		Tree.Item.MainMenuAPIRow(title: NSLocalizedString("Assets", comment: ""),
																								 image: Image( #imageLiteral(resourceName: "assets")),
																								 account: account,
																								 treeController: view?.treeController,
																								 route: Router.Business.assets(),
																								 require: [.esiAssetsReadAssetsV1]),
																		Tree.Item.MainMenuAPIRow(title: NSLocalizedString("Market Orders", comment: ""),
																								 image: Image( #imageLiteral(resourceName: "marketdeliveries")),
																								 account: account,
																								 treeController: view?.treeController,
																								 route: Router.Business.marketOrders(),
																								 require: [.esiMarketsReadCharacterOrdersV1]),
																		Tree.Item.MainMenuAPIRow(title: NSLocalizedString("Contracts", comment: ""),
																								 image: Image( #imageLiteral(resourceName: "contracts")),
																								 account: account,
																								 treeController: view?.treeController,
																								 route: Router.Business.contracts(),
																								 require: [.esiContractsReadCharacterContractsV1]),
																		Tree.Item.MainMenuAPIRow(title: NSLocalizedString("Wallet Transactions", comment: ""),
																								 image: Image( #imageLiteral(resourceName: "journal")),
																								 account: account,
																								 treeController: view?.treeController,
																								 route: Router.Business.walletTransactions(),
																								 require: [.esiWalletReadCharacterWalletV1]),
																		Tree.Item.MainMenuAPIRow(title: NSLocalizedString("Wallet Journal", comment: ""),
																								 image: Image( #imageLiteral(resourceName: "wallet")),
																								 account: account,
																								 treeController: view?.treeController,
																								 route: Router.Business.walletJournal(),
																								 require: [.esiWalletReadCharacterWalletV1]),
																		Tree.Item.MainMenuAPIRow(title: NSLocalizedString("Industry Jobs", comment: ""),
																								 image: Image( #imageLiteral(resourceName: "industry")),
																								 account: account,
																								 treeController: view?.treeController,
																								 route: Router.Business.industryJobs(),
																								 require: [.esiIndustryReadCharacterJobsV1]),
																		].compactMap{$0}).asAnyItem,
					Tree.Item.SimpleSection(title: NSLocalizedString("Fitting/Kills", comment: "").uppercased(),
											treeController: view?.treeController,
											children: [
												Tree.Item.MainMenuAPIRow(title: NSLocalizedString("Kill Reports", comment: ""),
																		 image: Image( #imageLiteral(resourceName: "killreport")),
																		 account: account,
																		 treeController: view?.treeController,
																		 route: Router.KillReports.killmails(),
																		 require: [.esiKillmailsReadKillmailsV1])?.asAnyItem,
												Tree.Item.MainMenuRow(title: NSLocalizedString("zKillboard Reports", comment: ""),
																	  image: Image( #imageLiteral(resourceName: "killreport")),
																	  route: Router.KillReports.zKillboard()).asAnyItem,
												].compactMap{$0}).asAnyItem,
					]

		return .init(menu)
	}
}

extension Tree.Item {
	
	class MainMenuRow: Tree.Item.Row<Tree.Content.Default>, Routable {
		let route: Routing?
		init(title: String, image: Image, route: Routing?) {
			self.route = route
			let identifier = "\(type(of: self)).\(title)"
			super.init(Tree.Content.Default(title: title, image: image), diffIdentifier: identifier)
		}
	}

	class MainMenuAPIRow: Row<Tree.Content.Default>, Routable {
		weak var treeController: TreeController?
		let route: Routing?
		
		init?(title: String, image: Image, account: Account?, value: @autoclosure () -> Future<ESI.Result<Tree.Content.Default>>, treeController: TreeController?, route: Routing?, require scopes: [ESI.Scope]) {
			if !scopes.isEmpty {
				let scopes = Set(scopes)
				let current = account?.scopes?.compactMap {($0 as? Scope)?.name}.compactMap {ESI.Scope($0)} ?? []
				guard scopes.isSubset(of: current) else {return nil}
			}
			self.route = route
			self.treeController = treeController
			super.init(Tree.Content.Default(title: title, image: image), diffIdentifier: title)
			
			value().then(on: .main) { [weak self] value -> Void in
				guard let strongSelf = self else {return}
				strongSelf.content = value.value
				strongSelf.treeController?.reloadRow(for: strongSelf, with: .fade)
			}.catch(on: .main) {  [weak self] error in
				guard let strongSelf = self else {return}
				strongSelf.content.subtitle = error.localizedDescription
				strongSelf.treeController?.reloadRow(for: strongSelf, with: .fade)
			}

		}

		init?(title: String, image: Image, account: Account?, treeController: TreeController?, route: Routing?, require scopes: [ESI.Scope]) {
			if !scopes.isEmpty {
				let scopes = Set(scopes)
				let current = account?.scopes?.compactMap {($0 as? Scope)?.name}.compactMap {ESI.Scope($0)} ?? []
				guard scopes.isSubset(of: current) else {return nil}
			}
			self.route = route
			self.treeController = treeController
			super.init(Tree.Content.Default(title: title, image: image), diffIdentifier: title)
		}
	}

}

