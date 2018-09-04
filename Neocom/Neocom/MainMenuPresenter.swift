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
	typealias Item = AnyTreeItem

	weak var view: MainMenuViewController!
	lazy var interactor: MainMenuInteractor! = MainMenuInteractor(presenter: self)

	var presentation: [AnyTreeItem]?
	var isLoading: Bool = false
	
	
	required init(view: MainMenuViewController) {
		self.view = view
	}
	
	func configure() {
		view.tableView.register([Prototype.TreeHeaderCell.default,
								 Prototype.TreeDefaultCell.default])
		
		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?

	func presentation(for content: Void) -> Future<[Item]> {
		let account = Services.storage.viewContext.currentAccount
		let api = Services.api.current
		
		func characterSheet() -> Future<ESI.Result<Tree.Content.Default>> {
			return api.skills(cachePolicy: .useProtocolCachePolicy).then {$0.map { skills -> Tree.Content.Default in
				let subtitle = UnitFormatter.localizedString(from: skills.totalSP, unit: .skillPoints, style: .long)
				return Tree.Content.Default(title:NSLocalizedString("Character Sheet", comment: ""), subtitle: subtitle, image: #imageLiteral(resourceName: "charactersheet"))
			}}
		}
//		return .init([])
		
		let menu = [Tree.Item.SimpleSection<Tree.Item.MainMenuAPIRow>(title: NSLocalizedString("Character", comment: ""),
																   treeController: view.treeController,
																   children: [
																	Tree.Item.MainMenuAPIRow(title: NSLocalizedString("Character Sheet", comment: ""),
																							 image: #imageLiteral(resourceName: "charactersheet"),
																							 account: account,
																							 value: characterSheet(),
																							 treeController: view.treeController,
																							 route: nil,
																							 require: [.esiWalletReadCharacterWalletV1,
																									   .esiSkillsReadSkillsV1,
																									   .esiLocationReadLocationV1,
																									   .esiLocationReadShipTypeV1,
																									   .esiClonesReadImplantsV1]),
																	Tree.Item.MainMenuAPIRow(title: NSLocalizedString("Jump Clones", comment: ""),
																							 image: #imageLiteral(resourceName: "jumpclones"),
																							 account: account,
																							 value: characterSheet(),
																							 treeController: view.treeController,
																							 route: nil,
																							 require: [.esiClonesReadClonesV1,
																									   .esiClonesReadImplantsV1]),
																	Tree.Item.MainMenuAPIRow(title: NSLocalizedString("Skills", comment: ""),
																							 image: #imageLiteral(resourceName: "skills"),
																							 account: account,
																							 value: characterSheet(),
																							 treeController: view.treeController,
																							 route: nil,
																							 require: [.esiSkillsReadSkillqueueV1,
																									   .esiSkillsReadSkillsV1,
																									   .esiClonesReadImplantsV1]),
																	Tree.Item.MainMenuAPIRow(title: NSLocalizedString("EVE Mail", comment: ""),
																							 image: #imageLiteral(resourceName: "evemail"),
																							 account: account,
																							 value: characterSheet(),
																							 treeController: view.treeController,
																							 route: nil,
																							 require: [.esiMailReadMailV1,
																									   .esiMailSendMailV1,
																									   .esiMailOrganizeMailV1]),
																	Tree.Item.MainMenuAPIRow(title: NSLocalizedString("Calendar", comment: ""),
																							 image: #imageLiteral(resourceName: "calendar"),
																							 account: account,
																							 value: characterSheet(),
																							 treeController: view.treeController,
																							 route: nil,
																							 require: [.esiCalendarReadCalendarEventsV1,
																									   .esiCalendarRespondCalendarEventsV1]),
																	Tree.Item.MainMenuAPIRow(title: NSLocalizedString("Wealth", comment: ""),
																							 image: #imageLiteral(resourceName: "folder"),
																							 account: account,
																							 value: characterSheet(),
																							 treeController: view.treeController,
																							 route: nil,
																							 require: [.esiWalletReadCharacterWalletV1,
																									   .esiAssetsReadAssetsV1]),
																	Tree.Item.MainMenuAPIRow(title: NSLocalizedString("Loyalty Points", comment: ""),
																							 image: #imageLiteral(resourceName: "lpstore"),
																							 account: account,
																							 value: characterSheet(),
																							 treeController: view.treeController,
																							 route: nil,
																							 require: [.esiCharactersReadLoyaltyV1])

																	].compactMap{$0}).asAnyItem,
					Tree.Item.SimpleSection<Tree.Item.MainMenuRow>(title: NSLocalizedString("Database", comment: ""),
																   treeController: view.treeController,
																   children: [
																	Tree.Item.MainMenuRow(title: NSLocalizedString("Database", comment: ""), image: #imageLiteral(resourceName: "items"), route: nil),
																	Tree.Item.MainMenuRow(title: NSLocalizedString("Certificates", comment: ""), image: #imageLiteral(resourceName: "certificates"), route: nil),
																	Tree.Item.MainMenuRow(title: NSLocalizedString("Market", comment: ""), image: #imageLiteral(resourceName: "market"), route: nil),
																	Tree.Item.MainMenuRow(title: NSLocalizedString("NPC", comment: ""), image: #imageLiteral(resourceName: "criminal"), route: nil),
																	Tree.Item.MainMenuRow(title: NSLocalizedString("Wormholes", comment: ""), image: #imageLiteral(resourceName: "terminate"), route: nil),
																	Tree.Item.MainMenuRow(title: NSLocalizedString("Incursions", comment: ""), image: #imageLiteral(resourceName: "incursions"), route: nil)
						]).asAnyItem,
					]
		return .init(menu)
		
		/*let menu = [
			Tree.Item.Section<Tree.Item.MainMenuAPI>(Tree.Content.Section(title: NSLocalizedString("Character", comment: "")), diffIdentifier: "character", expandIdentifier: "character", treeController: view.treeController, children: [
				Tree.Item.MainMenuAPI(Tree.Content.Default(title:NSLocalizedString("Character Sheet", comment: ""), image: #imageLiteral(resourceName: "charactersheet")),
									  account: account,
									  value: characterSheet(),
									  diffIdentifier: "characterSheet",
									  treeController: view.treeController,
									  require: [.esiWalletReadCharacterWalletV1,
												.esiSkillsReadSkillsV1,
												.esiLocationReadLocationV1,
												.esiLocationReadShipTypeV1,
												.esiClonesReadImplantsV1]),
				Tree.Item.MainMenuAPI(Tree.Content.Default(title:NSLocalizedString("Jump Clones", comment: ""), image: #imageLiteral(resourceName: "jumpclones")),
									  account: account,
									  value: characterSheet(),
									  diffIdentifier: "jumpClones",
									  treeController: view.treeController,
									  require: [.esiClonesReadClonesV1,
												.esiClonesReadImplantsV1])
				
				].compactMap{$0}).asAnyItem,
			
			Tree.Item.Section<Tree.Item.MainMenu>(Tree.Content.Section(title: NSLocalizedString("Database", comment: "")), diffIdentifier: "database", expandIdentifier: "database", treeController: view.treeController, children: [
				Tree.Item.MainMenu(Tree.Content.Default(title: NSLocalizedString("Database", comment: ""), image: #imageLiteral(resourceName: "items")))
				]).asAnyItem
		]
		
		return .init(menu)*/
	}
	
}

extension Tree.Item {
	
	class MainMenuRow: Tree.Item.Row<Tree.Content.Default>, Routable {
		let route: Routing?
		init(title: String, image: UIImage, route: Routing?) {
			self.route = route
			let identifier = "\(type(of: self)).\(title)"
			super.init(Tree.Content.Default(title: title, image: image), diffIdentifier: identifier)
		}
	}

	class MainMenuAPIRow: ESIResultRow<Tree.Content.Default>, Routable {
		let route: Routing?
		init?(title: String, image: UIImage, account: Account?, value: @autoclosure () -> Future<ESI.Result<Tree.Content.Default>>, treeController: TreeController, route: Routing?, require scopes: [ESI.Scope]) {
			if !scopes.isEmpty {
				let scopes = Set(scopes)
				let current = account?.scopes?.compactMap {($0 as? Scope)?.name}.compactMap {ESI.Scope($0)} ?? []
				guard scopes.isSubset(of: current) else {return nil}
			}
			self.route = route
			super.init(Tree.Content.Default(title: title, image: image),
					   value: value(),
					   diffIdentifier: title,
					   treeController: treeController)
		}
		
		override func didFail(_ error: Error) {
			content.subtitle = error.localizedDescription
			treeController?.reloadRow(for: self, with: .fade)
		}
	}

}

