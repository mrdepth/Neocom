//
//  FittingLoadoutsPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/23/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import TreeController
import Expressible
import CoreData

class FittingLoadoutsPresenter: TreePresenter {
	typealias View = FittingLoadoutsViewController
	typealias Interactor = FittingLoadoutsInteractor
	typealias Presentation = [AnyTreeItem]
	
	weak var view: View?
	lazy var interactor: Interactor! = Interactor(presenter: self)
	
	var content: Interactor.Content?
	var presentation: Presentation?
	var loading: Future<Presentation>?
	var loadouts: Atomic<[Tree.Item.Section<Tree.Content.LoadoutsSection, Tree.Item.LoadoutRow>]?> = Atomic(nil)
	
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
		
		switch view?.input {
		case .ship?:
			view?.title = NSLocalizedString("Ships", comment: "")
		case .structure?:
			view?.title = NSLocalizedString("Structures", comment: "")
		default:
			break
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		guard let input = view?.input else {return .init(.failure(NCError.invalidInput(type: type(of: self))))}
		
		let treeController = view?.treeController
		
		let storageContext = interactor.storageContext
		return storageContext.perform { [weak self] () -> [Tree.Item.Section<Tree.Content.LoadoutsSection, Tree.Item.LoadoutRow>] in
			guard let strongSelf = self else {throw NCError.cancelled(type: type(of: self), function: #function)}
			let loadouts = try storageContext.managedObjectContext
				.from(Loadout.self)
				.fetch()

			return strongSelf.presentation(for: loadouts, categoryID: input, treeController: treeController)
		}.then(on: .main) { [weak self] result -> Presentation in
			self?.loadouts.value = result
			
			let menu: [Tree.Item.RoutableRow<Tree.Content.Default>]
			
			switch input {
			case .ship:
				menu = [
					Tree.Item.RoutableRow(Tree.Content.Default(title: NSLocalizedString("New Ship Fit", comment: ""), image:Image( #imageLiteral(resourceName: "fitting")), accessoryType: .disclosureIndicator), route: nil),
					Tree.Item.RoutableRow(Tree.Content.Default(title: NSLocalizedString("Import/Export", comment: ""), image:Image( #imageLiteral(resourceName: "browser")), accessoryType: .disclosureIndicator), route: nil)
				]
			case .structure:
				menu = [
					Tree.Item.RoutableRow(Tree.Content.Default(title: NSLocalizedString("New Structure Fit", comment: ""), image:Image( #imageLiteral(resourceName: "station")), accessoryType: .disclosureIndicator), route: nil)
				]
			default:
				menu = []
			}
			
			
			return [Tree.Item.Virtual(children: menu, diffIdentifier: "Menu").asAnyItem,
					Tree.Item.Virtual(children: result, diffIdentifier: "Loadouts").asAnyItem
			]
		}
	}
	
	private func presentation(for loadouts: [Loadout], categoryID: SDECategoryID, treeController: TreeController?) -> [Tree.Item.Section<Tree.Content.LoadoutsSection, Tree.Item.LoadoutRow>] {
		let context = Services.sde.newBackgroundContext()
		
		return context.performAndWait { () -> [Tree.Item.Section<Tree.Content.LoadoutsSection, Tree.Item.LoadoutRow>] in
			
			let items = loadouts.compactMap { i -> (loadout: Loadout, type: SDEInvType)? in
				context.invType(Int(i.typeID)).map {(loadout: i, type: $0)}
				}.filter {$0.type.group?.category?.categoryID == categoryID.rawValue}
				.sorted {$0.type.typeName ?? "" < $1.type.typeName ?? ""}
			
			let groups = Dictionary(grouping: items) {$0.type.group}.sorted {$0.key?.groupName ?? "" < $1.key?.groupName ?? ""}
			
			return groups.map { i -> Tree.Item.Section<Tree.Content.LoadoutsSection, Tree.Item.LoadoutRow> in
				
				let rows = i.value.sorted{$0.0.name ?? "" < $1.0.name ?? ""}
					.map{
						Tree.Item.LoadoutRow(Tree.Content.Loadout(loadoutID: $0.loadout.objectID, loadoutName: $0.loadout.name ?? "", typeID: $0.type.objectID), diffIdentifier: $0.loadout.objectID)
				}
				let section = Tree.Content.LoadoutsSection(groupID: Int(i.key!.groupID), groupName: i.key?.groupName?.uppercased() ?? NSLocalizedString("Unknown", comment: "").uppercased())
				return Tree.Item.Section(section,
										 diffIdentifier: i.key!.objectID,
										 expandIdentifier: i.key!.objectID,
										 treeController: treeController,
										 children: rows)
			}
		}
	}
	
	func didUpdateLoaoduts(updated: [Loadout]?, inserted: [Loadout]?, deleted: [Loadout]?) {
		guard var loadouts = loadouts.value else {return}
		guard let input = view?.input else {return}
		
		if let updated = updated, !updated.isEmpty {
			
			let pairs = loadouts.enumerated().compactMap { i in
				i.element.children?.enumerated().map { j in
					(j.element.content.loadoutID, IndexPath(row: j.offset, section: i.offset))
				}
			}.joined()
			
			let map = Dictionary(pairs, uniquingKeysWith: { a, _ in a})
			for i in updated {
				guard let indexPath = map[i.objectID], let row = loadouts[indexPath.section].children?[indexPath.row] else {continue}
				let new = Tree.Item.LoadoutRow(Tree.Content.Loadout(loadoutID: i.objectID, loadoutName: i.name ?? "", typeID: row.content.typeID), diffIdentifier: i.objectID)
				loadouts[indexPath.section].children?[indexPath.row] = new
			}
		}
		
		deleted?.forEach { i in
			for (j, section) in loadouts.enumerated() {
				if let index = section.children?.firstIndex(where: {$0.content.loadoutID == i.objectID}) {
					section.children?.remove(at: index)
					if section.children?.isEmpty == true {
						loadouts.remove(at: j)
					}
					return
				}
			}
		}

		
		let treeController = (try? DispatchQueue.main.async {self.view?.treeController}.get()) ?? nil
		
		if let inserted = inserted, !inserted.isEmpty {
			let newSections = presentation(for: inserted, categoryID: input, treeController: treeController)
			for i in newSections {
				let r = loadouts.lowerBound(where: {$0.content.groupName <= i.content.groupName })
				if let j = r.last, j.content == i.content {
					let children = [j.children, i.children].compactMap{$0}.joined().sorted(by: {$0.content.loadoutName < $1.content.loadoutName})
					j.children? = children
				}
				else {
					loadouts.insert(i, at: r.indices.upperBound)
				}
			}
		}
		
		DispatchQueue.main.async {
			guard var presentation = self.presentation, presentation.count == 2 else {return}
			presentation[1] = Tree.Item.Virtual(children: loadouts, diffIdentifier: "Loadouts").asAnyItem
			self.presentation = presentation
			self.loadouts.value = loadouts
			self.view?.present(presentation, animated: true)
		}
	}
}

extension Tree.Item {
	class LoadoutRow: Row<Tree.Content.Loadout> {
		override var prototype: Prototype? {
			return Prototype.TreeDefaultCell.default
		}
		
		lazy var type: SDEInvType = try! Services.sde.viewContext.existingObject(with: content.typeID)
		
		override func configure(cell: UITableViewCell, treeController: TreeController?) {
			super.configure(cell: cell, treeController: treeController)
			guard let cell = cell as? TreeDefaultCell else {return}
			cell.accessoryType = .disclosureIndicator
			cell.titleLabel?.text = type.typeName
			cell.subtitleLabel?.text = content.loadoutName
			cell.subtitleLabel?.isHidden = false
			cell.iconView?.image = type.icon?.image?.image ?? Services.sde.viewContext.eveIcon(.defaultType)?.image?.image
		}
	}
}

extension Tree.Content {
	struct Loadout: Hashable {
		var loadoutID: NSManagedObjectID
		var loadoutName: String
		var typeID: NSManagedObjectID
	}
	
	struct LoadoutsSection: Hashable, CellConfigurable {
		var prototype: Prototype? = Prototype.TreeSectionCell.default
		var groupID: Int
		var groupName: String
		
		func configure(cell: UITableViewCell, treeController: TreeController?) {
			guard let cell = cell as? TreeSectionCell else {return}
			cell.titleLabel?.text = groupName
		}
		
		init(groupID: Int, groupName: String) {
			self.groupID = groupID
			self.groupName = groupName
		}
	}
}

