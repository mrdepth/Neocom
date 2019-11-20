//
//  CharacterInfoPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/1/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import TreeController
import CoreData

class CharacterInfoPresenter: TreePresenter {
	typealias View = CharacterInfoViewController
	typealias Interactor = CharacterInfoInteractor
	typealias Presentation = [Tree.Item.Section<Tree.Content.Section, Tree.Item.Row<Tree.Content.Default>>]
	
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
								  Prototype.TreeDefaultCell.attribute,
								  Prototype.TreeDefaultCell.placeholder,
								  Prototype.TreeDefaultCell.portrait])
		
		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
		
		if let characterName = Services.storage.viewContext.currentAccount?.characterName {
			view?.title = characterName
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		
		var sections = Presentation()
		
		var rows = [Tree.Item.Row<Tree.Content.Default>]()
		
		if let image = content.value.characterImage {
			rows.append(Tree.Item.Row(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.portrait, image: Image(image)), diffIdentifier: "CharacterImage"))
		}
		
		if let corporation = content.value.corporation {
			rows.append(Tree.Item.Row(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute,
														   title: NSLocalizedString("Corporation", comment: "").uppercased(),
														   subtitle: corporation.name,
														   image: content.value.corporationImage.map {Image($0)}),
									  diffIdentifier: "Corporation"))
		}

		if let alliance = content.value.alliance {
			rows.append(Tree.Item.Row(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute,
														   title: NSLocalizedString("Alliance", comment: "").uppercased(),
														   subtitle: alliance.name,
														   image: content.value.allianceImage.map {Image($0)}),
									  diffIdentifier: "Alliance"))
		}
		
		if let character = content.value.character {
			view?.title = character.name
			
			rows.append(Tree.Item.Row(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute,
														   title: NSLocalizedString("Date of Birth", comment: "").uppercased(),
														   subtitle: DateFormatter.localizedString(from: character.birthday, dateStyle: .short, timeStyle: .none)),
									  diffIdentifier: "DoB"))
			
			if let race = Services.sde.viewContext.chrRace(character.raceID)?.raceName,
				let bloodline = Services.sde.viewContext.chrBloodline(character.bloodlineID)?.bloodlineName,
				let ancestry = character.ancestryID.flatMap({Services.sde.viewContext.chrAncestry($0)?.ancestryName}) {
				let subtitle = "\(race) / \(bloodline) / \(ancestry)"
				rows.append(Tree.Item.Row(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute,
															   title: NSLocalizedString("Bloodline", comment: "").uppercased(),
															   subtitle: subtitle),
										  diffIdentifier: "Bloodline"))
			}
			if let ss = character.securityStatus {
				let subtitle = String(format: "%.1f", ss) * [NSAttributedString.Key.foregroundColor: UIColor(security: ss)]
				rows.append(Tree.Item.Row(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute,
															   title: NSLocalizedString("Security Status", comment: "").uppercased(),
															   attributedSubtitle: subtitle),
										  diffIdentifier: "SS"))
			}
		}
		
		if let ship = content.value.ship,
			let location = content.value.location,
			let type = Services.sde.viewContext.invType(ship.shipTypeID),
			let solarSystem = Services.sde.viewContext.mapSolarSystem(location.solarSystemID) {
			
			rows.append(Tree.Item.RoutableRow(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute,
														   title: type.typeName?.uppercased(),
														   attributedSubtitle: EVELocation(solarSystem).displayName,
														   image: Image(type.icon),
														   accessoryType: .disclosureIndicator),
									  diffIdentifier: "Ship",
									  route: Router.SDE.invTypeInfo(.type(type))))
		}
		
		if !rows.isEmpty {
			sections.append(Tree.Item.SimpleSection(title: NSLocalizedString("Bio", comment: "").uppercased(),
													treeController: view?.treeController,
													children: rows))
		}
		
		if let walletBalance = content.value.walletBalance {
			let subtitle = UnitFormatter.localizedString(from: walletBalance, unit: .isk, style: .long)
			let row = Tree.Item.Row(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute,
														 title: NSLocalizedString("Balance", comment: "").uppercased(),
														 subtitle: subtitle),
									diffIdentifier: "Balance")
			sections.append(Tree.Item.SimpleSection(title: NSLocalizedString("Account", comment: "").uppercased(),
													treeController: view?.treeController,
													children: [row]))
		}
		
		rows.removeAll()
		
		if let attributes = content.value.attributes,
			let implants = content.value.implants,
			let skills = content.value.skills,
			let skillQueue = content.value.skillQueue {
			let character = Character(attributes: attributes, skills: skills, skillQueue: skillQueue, implants: implants, context: Services.sde.viewContext)
			let sp = character.trainedSkills.values.lazy.map{$0.skillpointsInSkill}.reduce(0, +)
			let subtitle = UnitFormatter.localizedString(from: sp, unit: .skillPoints, style: .long)
			let row = Tree.Item.Row(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute,
														 title: NSLocalizedString("skills", comment: "").uppercased(),
														 subtitle: subtitle),
									diffIdentifier: "SP")
			rows.append(row)
		}
		
		if let attributes = content.value.attributes {
			rows.append(Tree.Item.Row(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute,
														   title: NSLocalizedString("Bonus Remaps Available", comment: "").uppercased(),
														   subtitle: "\(attributes.bonusRemaps ?? 0)"),
									  diffIdentifier: "Respecs"))
			if let lastRemapDate = attributes.lastRemapDate {
				let calendar = Calendar(identifier: .gregorian)
				var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second, .timeZone], from: lastRemapDate)
				components.year? += 1
				if let date = calendar.date(from: components) {
					let t = date.timeIntervalSinceNow
					let s: String
					
					if t <= 0 {
						s = NSLocalizedString("Now", comment: "")
					}
					else if t < 3600 * 24 * 7 {
						s = TimeIntervalFormatter.localizedString(from: t, precision: .minutes)
					}
					else {
						s = DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .none)
					}
					
					rows.append(Tree.Item.Row(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute,
																   title: NSLocalizedString("Neural Remap Available", comment: "").uppercased(),
																   subtitle: s),
											  diffIdentifier: "RespecDate"))
				}
			}
		}

		if !rows.isEmpty {
			sections.append(Tree.Item.SimpleSection(title: NSLocalizedString("Skills", comment: "").uppercased(),
													treeController: view?.treeController,
													children: rows))
		}

		if let attributes = content.value.attributes {
			
			rows = [("AttributeIntelligence", NSLocalizedString("Intelligence", comment: ""), #imageLiteral(resourceName: "intelligence"), attributes.intelligence),
					("AttributeMemory", NSLocalizedString("Memory", comment: ""), #imageLiteral(resourceName: "memory"), attributes.memory),
					("AttributePerception", NSLocalizedString("Perception", comment: ""), #imageLiteral(resourceName: "perception"), attributes.perception),
					("AttributeWillpower", NSLocalizedString("Willpower", comment: ""), #imageLiteral(resourceName: "willpower"), attributes.willpower),
					("AttributeCharisma", NSLocalizedString("Charisma", comment: ""), #imageLiteral(resourceName: "charisma"), attributes.charisma)].map { i in
						
						Tree.Item.Row(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute,
														   title: i.1,
														   subtitle: String.localizedStringWithFormat(NSLocalizedString("%d points", comment: ""), i.3),
														   image: Image(i.2)),
									  diffIdentifier: i.0)
			}
			sections.append(Tree.Item.SimpleSection(title: NSLocalizedString("Attributes", comment: "").uppercased(),
													treeController: view?.treeController,
													children: rows))
		}
		
		if let implants = content.value.implants {
			sections.append(Tree.Item.ImplantsSection(implants, title: NSLocalizedString("Implants", comment: "").uppercased(), diffIdentifier: "Implants", treeController: view?.treeController))
		}
		
		return .init(sections)
	}
}

extension Tree.Item {
	class ImplantsSection: Section<Tree.Content.Section, Tree.Item.Row<Tree.Content.Default>> {
		
		convenience init<T: Hashable>(_ implants: [Int], title: String?, diffIdentifier: T, treeController: TreeController?) {
			self.init(implants, attributedTitle: title.map{ NSAttributedString(string: $0) }, diffIdentifier: diffIdentifier, treeController: treeController)
		}

		init<T: Hashable>(_ implants: [Int], attributedTitle: NSAttributedString?, diffIdentifier: T, treeController: TreeController?) {
			
			let attributes = [SDEAttributeID.intelligenceBonus: NSLocalizedString("Intelligence", comment: ""),
							  SDEAttributeID.memoryBonus: NSLocalizedString("Memory", comment: ""),
							  SDEAttributeID.perceptionBonus: NSLocalizedString("Perception", comment: ""),
							  SDEAttributeID.willpowerBonus: NSLocalizedString("Willpower", comment: ""),
							  SDEAttributeID.charismaBonus: NSLocalizedString("Charisma", comment: "")]
			
			var rows = implants.compactMap { i -> (SDEInvType, Int)? in
				guard let type = Services.sde.viewContext.invType(i) else {return nil}

				let slot = Int(type[SDEAttributeID.implantness]?.value ?? 100)
				return (type, slot)
			}.sorted {$0.1 < $1.1}.map { (type, _) -> Tree.Item.Row<Tree.Content.Default> in
				

				if let enhancer = attributes.first(where: { (type[$0.key]?.value ?? 0) > 0 }) {
						return Tree.Item.RoutableRow(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute,
																		  title: type.typeName?.uppercased(),
																		  subtitle: "\(enhancer.value) +\(Int(type[enhancer.key]?.value ?? 0))",
																		  image: Image(type.icon),
																		  accessoryType: .disclosureIndicator),
													 diffIdentifier: Pair(diffIdentifier, type.objectID),
													 route: Router.SDE.invTypeInfo(.type(type)))
					}
					else {
						return Tree.Item.RoutableRow(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute,
																		  title: type.typeName?.uppercased(),
																		  image: Image(type.icon),
																		  accessoryType: .disclosureIndicator),
													 diffIdentifier: Pair(diffIdentifier, type.objectID),
													 route: Router.SDE.invTypeInfo(.type(type)))
					}
			}
			if rows.isEmpty {
				rows.append(Tree.Item.Row(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.placeholder,
															   title: NSLocalizedString("No Implants Installed", comment: "").uppercased()),
										  diffIdentifier: Pair(diffIdentifier, "NoImplants")))
			}
			super.init(Tree.Content.Section(attributedTitle: attributedTitle), diffIdentifier: diffIdentifier, treeController: treeController, children: rows)
		}
	}
}
