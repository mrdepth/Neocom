//
//  KillmailInfoPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/14/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import TreeController
import EVEAPI

class KillmailInfoPresenter: TreePresenter {
	typealias View = KillmailInfoViewController
	typealias Interactor = KillmailInfoInteractor
	typealias Presentation = [AnyTreeItem]
	
	weak var view: View?
	lazy var interactor: Interactor! = Interactor(presenter: self)
	
	var content: Interactor.Content?
	var presentation: Presentation?
	var loading: Future<Presentation>?
	
	required init(view: View) {
		self.view = view
	}
	
	func configure() {
		view?.tableView.register([Prototype.TreeSectionCell.default,
								  Prototype.TreeHeaderCell.default,
								  Prototype.TreeDefaultCell.default,
								  Prototype.TreeDefaultCell.contact,
								  Prototype.KillmailAttackerCell.default,
								  Prototype.KillmailAttackerCell.npc])
		
		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		guard let killmail = view?.input else {return .init(.failure(NCError.invalidInput(type: type(of: self))))}
		let api = interactor.api
		
		let treeController = view?.treeController
		let context = Services.sde.viewContext
		
		let location = context.mapSolarSystem(killmail.solarSystemID).map{EVELocation($0)} ?? .unknown
		let locationRow = Tree.Item.RoutableRow(Tree.Content.Default(attributedTitle: location.displayName,
																	 subtitle: DateFormatter.localizedString(from: killmail.killmailTime, dateStyle: .medium, timeStyle: .medium),
																	 accessoryType: .disclosureIndicator),
												diffIdentifier: "Location")
		
		let assets = killmail.victim.allItems
		
		let items = assets.map { items -> [Tree.Item.Header<Tree.Item.Row<Tree.Content.Default>>] in
			items.sorted(by: {$0.key.rawValue < $1.key.rawValue}).map { i -> Tree.Item.Header<Tree.Item.Row<Tree.Content.Default>> in
				let rows = i.value.map { j -> Tree.Item.Row<Tree.Content.Default> in
					let type = context.invType(j.typeID)
					let title = type?.typeName ?? NSLocalizedString("Unknown Type", comment: "")
					let subtitle: String?
					switch (j.dropped, j.destroyed) {
					case let (dropped, destroyed) where dropped > 0 && destroyed > 0:
						subtitle = String.localizedStringWithFormat(NSLocalizedString("Dropped: %@   Destroyed: %@", comment: ""), UnitFormatter.localizedString(from: Double(dropped), unit: .none, style: .long), UnitFormatter.localizedString(from: Double(destroyed), unit: .none, style: .long))
					case let (dropped, destroyed) where dropped > 0 && destroyed == 0:
						subtitle = String.localizedStringWithFormat(NSLocalizedString("Dropped: %@", comment: ""), UnitFormatter.localizedString(from: Double(dropped), unit: .none, style: .long))
					case let (dropped, destroyed) where dropped == 0 && destroyed > 0:
						subtitle = String.localizedStringWithFormat(NSLocalizedString("Destroyed: %@", comment: ""), UnitFormatter.localizedString(from: Double(destroyed), unit: .none, style: .long))
					default:
						subtitle = nil
					}
					
					let image = Image(type?.icon ?? context.eveIcon(.defaultType))
					
					return Tree.Item.RoutableRow(Tree.Content.Default(title: title, subtitle: subtitle, image: image, accessoryType: .disclosureIndicator), diffIdentifier: Pair(i.key, j.typeID), route: type.map{Router.SDE.invTypeInfo(.type($0))})
				}.sorted{$0.content.title! < $1.content.title!}
				return Tree.Item.Header(Tree.Content.Header(title: i.key.title.uppercased(), image: Image(i.key.image)), diffIdentifier: i.key, children: rows)
			}
		}
		
		let ship = context.invType(killmail.victim.shipTypeID)
		
		let shipRow = Tree.Item.RoutableCollection(Tree.Content.Default(title: ship?.typeName ?? NSLocalizedString("Unknown Type", comment: ""),
																		subtitle: String.localizedStringWithFormat(NSLocalizedString("Damage taken: %@", comment: ""), UnitFormatter.localizedString(from: killmail.victim.damageTaken, unit: .none, style: .long)),
																		image: Image(ship?.icon ?? context.eveIcon(.defaultType)), accessoryType: .disclosureIndicator),
												   diffIdentifier: "VictimShip",
												   route: ship.map{Router.SDE.invTypeInfo(.type($0))},
												   children: items)
		let cost = content.prices.flatMap { prices -> Double? in
			assets?.values.joined().reduce(0, {$0 + Double($1.destroyed + $1.dropped) * (prices[$1.typeID] ?? 0)})
		} ?? 0
		
		let victimRow = Tree.Item.KillmailVictimRow(killmail.victim, contacts: content.contacts, api: api)
		
		let attackers = killmail.attackers.sorted {$0.finalBlow == $1.finalBlow ? $0.damageDone > $1.damageDone : $0.finalBlow}.map {Tree.Item.KillmailAttackerRow($0, contacts: content.contacts, api: api)}
		

		var sections = [AnyTreeItem]()
		
		if cost > 0 {
			sections.append(Tree.Item.Section(Tree.Content.Section(attributedTitle: NSAttributedString(string: NSLocalizedString("Victim", comment: "").uppercased()) + " (\((UnitFormatter.localizedString(from: cost, unit: .isk, style: .long))))" * [NSAttributedString.Key.foregroundColor: UIColor.white]),
											  diffIdentifier: "Victim",
											  treeController: treeController,
											  children: [victimRow.asAnyItem, locationRow.asAnyItem, shipRow.asAnyItem]).asAnyItem)
		}
		else {
			sections.append(Tree.Item.Section(Tree.Content.Section(title: NSLocalizedString("Victim", comment: "").uppercased()),
											  diffIdentifier: "Victim",
											  treeController: treeController,
											  children: [victimRow.asAnyItem, locationRow.asAnyItem, shipRow.asAnyItem]).asAnyItem)
		}
		if !attackers.isEmpty {
			sections.append(Tree.Item.Section(Tree.Content.Section(title: NSLocalizedString("Attackers", comment: "").uppercased()),
											  diffIdentifier: "Attackers",
											  treeController: treeController,
											  children: attackers).asAnyItem)
		}
		
		return .init(sections)
	}
}

extension Tree.Item {
	
	class KillmailVictimRow: Row<ESI.Killmails.Killmail.Victim> {
		let character: Contact?
		let corporation: Contact?
		let alliance: Contact?

		var image: UIImage?
		let api: API
		
		override var prototype: Prototype? {
			return character != nil ? Prototype.TreeDefaultCell.contact : Prototype.TreeDefaultCell.default
		}
		
		init(_ content: ESI.Killmails.Killmail.Victim, contacts: [Int64: Contact]?, api: API) {
			character = content.characterID.flatMap{contacts?[Int64($0)]}
			corporation = content.corporationID.flatMap{contacts?[Int64($0)]}
			alliance = content.allianceID.flatMap{contacts?[Int64($0)]}
			self.api = api
			super.init(content)
		}
		
		override func configure(cell: UITableViewCell, treeController: TreeController?) {
			super .configure(cell: cell, treeController: treeController)
			guard let cell = cell as? TreeDefaultCell else {return}
			cell.titleLabel?.text = character?.name ?? corporation?.name ?? alliance?.name ?? NSLocalizedString("Unknown", comment: "")
			
			switch (corporation?.name, alliance?.name) {
			case let (a?, b?):
				cell.subtitleLabel?.text = "\(a) / \(b)"
			case let (a?, nil):
				cell.subtitleLabel?.text = a
			case let (nil, b):
				cell.subtitleLabel?.text = b
			}
			cell.accessoryType = .disclosureIndicator

			if image == nil, let size = cell.iconView?.bounds.size, let contact = character ?? corporation ?? alliance {
				api.image(contact: contact, dimension: Int(size.width), cachePolicy: .useProtocolCachePolicy).then(on: .main) { [weak self, weak treeController] result in
					guard let strongSelf = self else {return}
					strongSelf.image = result.value
					treeController?.reloadRow(for: strongSelf, with: .none)
				}.catch(on: .main) { [weak self] _ in
					self?.image = UIImage()
				}
			}
			
			cell.iconView?.image = image ?? UIImage()
		}
	}
	
}

extension ESI.Killmails.Killmail.Victim {
	var allItems: [AssetSlot: [(typeID: Int, dropped: Int64, destroyed: Int64)]]? {
		guard let items = items else {return nil}
		let groups = Dictionary(grouping: items, by: {ESI.Assets.Asset.Flag(rawValue: $0.flag)?.slot ?? .cargo})
		
		return groups.mapValues { i -> [(typeID: Int, dropped: Int64, destroyed: Int64)]in
			let items = i.flatMap { j -> [(Int, Int64, Int64)] in
				let a = [(j.itemTypeID, j.quantityDropped ?? 0, j.quantityDestroyed ?? 0)]
				let b = j.items?.map {($0.itemTypeID, $0.quantityDropped ?? 0, $0.quantityDestroyed ?? 0)} ?? []
				return a + b
			}
			return Dictionary(grouping: items, by: {$0.0}).map { i in
				let sum = i.value.reduce((0,0), {($0.0 + $1.1, $0.1 + $1.2)})
				return (typeID: i.key, dropped: sum.0, destroyed: sum.1)
			}
		}
	}
}
