//
//  MainPresenter.swift
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

class MainPresenter: TreePresenter {
	typealias Item = AnyTreeItem
	var presentation: [AnyTreeItem]?
	var isLoading: Bool = false
	
	weak var view: MainViewController!
	lazy var interactor: MainInteractor! = MainInteractor(presenter: self)
	
	required init(view: MainViewController) {
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
		let account = interactor.storage.viewContext.currentAccount
		let api = interactor.api(cachePolicy: .useProtocolCachePolicy)
		
		func characterSheet() -> Future<CachedValue<Tree.Content.Default>> {
			return api.skills().then {$0.map { skills -> Tree.Content.Default in
				let subtitle = UnitFormatter.localizedString(from: skills.totalSP, unit: .skillPoints, style: .long)
				return Tree.Content.Default(title:NSLocalizedString("Character Sheet", comment: ""), subtitle: subtitle, image: #imageLiteral(resourceName: "charactersheet"))
			}}
		}
		
		let menu = [
			Tree.Item.Section<Tree.Item.MainMenuAPI>(treeController: view.treeController, content: Tree.Content.Section(title: NSLocalizedString("Character", comment: "")), diffIdentifier: "character", expandIdentifier: "character", children: [
				Tree.Item.MainMenuAPI(treeController: view.treeController,
									  account: account,
									  content: Tree.Content.Default(title:NSLocalizedString("Character Sheet", comment: ""), image: #imageLiteral(resourceName: "charactersheet")),
									  value: characterSheet(),
									  diffIdentifier: "characterSheet",
									  require: [.esiWalletReadCharacterWalletV1,
												.esiSkillsReadSkillsV1,
												.esiLocationReadLocationV1,
												.esiLocationReadShipTypeV1,
												.esiClonesReadImplantsV1]),
				Tree.Item.MainMenuAPI(treeController: view.treeController,
									  account: account,
									  content: Tree.Content.Default(title:NSLocalizedString("Jump Clones", comment: ""), image: #imageLiteral(resourceName: "jumpclones")),
									  value: characterSheet(),
									  diffIdentifier: "jumpClones",
									  require: [.esiClonesReadClonesV1,
												.esiClonesReadImplantsV1])
				
				].compactMap{$0}).asAnyItem,
			
			Tree.Item.Section<Tree.Item.MainMenu>(treeController: view.treeController, content: Tree.Content.Section(title: NSLocalizedString("Database", comment: "")), diffIdentifier: "database", expandIdentifier: "database", children: [
				Tree.Item.MainMenu(content: Tree.Content.Default(title: NSLocalizedString("Database", comment: ""), image: #imageLiteral(resourceName: "items")))
				]).asAnyItem
		]
		
		return .init(menu)
	}
	
}

extension Tree.Item {
	class MainMenu: Tree.Item.Row<Tree.Content.Default> {
	}
	
	class MainMenuAPI: CachedRow<Tree.Content.Default> {

		init?<T: Hashable>(treeController: TreeController, account: Account?, content: Tree.Content.Default, value: @autoclosure () -> Future<CachedValue<Tree.Content.Default>>, diffIdentifier: T, require scopes: [ESI.Scope]) {
			if !scopes.isEmpty {
				let scopes = Set(scopes)
				let current = account?.scopes?.compactMap {($0 as? Scope)?.name}.compactMap {ESI.Scope($0)} ?? []
				guard scopes.isSubset(of: current) else {return nil}
			}
			super.init(treeController: treeController, content: content, value: value(), diffIdentifier: diffIdentifier)
		}
		
		override func didFail(_ error: Error) {
			content.subtitle = error.localizedDescription
			treeController?.reloadRow(for: self, with: .fade)
		}
	}

}

