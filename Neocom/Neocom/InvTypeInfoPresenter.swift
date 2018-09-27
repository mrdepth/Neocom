//
//  InvTypeInfoPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 21.09.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import TreeController
import Expressible
import CoreData
import Dgmpp

class InvTypeInfoPresenter: TreePresenter {
	typealias View = InvTypeInfoViewController
	typealias Interactor = InvTypeInfoInteractor
	typealias Presentation = [AnyTreeItem]
	
	weak var view: View?
	lazy var interactor: Interactor! = Interactor(presenter: self)
	
	var content: Interactor.Content?
	var presentation: Presentation?
	var loading: Future<Presentation>?
	
	required init(view: View) {
		self.view = view
	}
	
	private var invType: SDEInvType?
	
	func configure() {
		view?.tableView.register([Prototype.TreeHeaderCell.default,
								 Prototype.DgmAttributeCell.default,
								 Prototype.DamageTypeCell.compact,
								 Prototype.TreeDefaultCell.default,
								 Prototype.InvTypeInfoDescriptionCell.default,
								 Prototype.InvTypeInfoDescriptionCell.compact,
								 Prototype.MarketHistoryCell.default])
		
		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
		
		switch view?.input {
		case let .objectID(objectID)?:
			invType = (try? Services.sde.viewContext.existingObject(with: objectID)) ?? nil
		case let .type(type)?:
			invType = type
		case let .typeID(typeID)?:
			invType = Services.sde.viewContext.invType(typeID)
		default:
			break
		}
		view?.title = invType?.typeName ?? NSLocalizedString("Type Info", comment: "")
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		guard let objectID = invType?.objectID else { return .init(.failure(NCError.invalidInput(type: type(of: self))))}
		
		let progress = Progress(totalUnitCount: 2)
		
		return Services.sde.performBackgroundTask { (context) -> Presentation in
			let type: SDEInvType = try context.existingObject(with: objectID)!
			
			var presentation = progress.performAsCurrent(withPendingUnitCount: 1) {self.typeInfoPresentation(for: type, character: content.value, context: context, attributeValues: nil)}
			
			if type.marketGroup != nil {
				let marketSection = Tree.Item.Section<AnyTreeItem>(Tree.Content.Section(title: NSLocalizedString("Market", comment: "").uppercased()), diffIdentifier: "MarketSection", expandIdentifier: "MarketSection", treeController: self.view?.treeController, children: [])
				
				presentation.insert(marketSection.asAnyItem, at: 0)
				
				let marketRoute = Router.SDE.invTypeMarketOrders(.typeID(Int(type.typeID)))
				
				self.interactor.price(typeID: Int(type.typeID)).then(on: .main) { result in
					let subtitle = UnitFormatter.localizedString(from: result, unit: .isk, style: .long)
					let price = Tree.Item.RoutableRow(Tree.Content.Default(prototype: Prototype.DgmAttributeCell.default,
																		   title: NSLocalizedString("PRICE", comment: ""),
																		   subtitle: subtitle,
																		   image: #imageLiteral(resourceName: "wallet"),
																		   accessoryType: .disclosureIndicator),
													  diffIdentifier: "Price",
													  route: marketRoute )
					marketSection.children?.insert(price.asAnyItem, at: 0)
					self.view?.treeController.update(contentsOf: marketSection)
				}
				
				self.interactor.marketHistory(typeID: Int(type.typeID)).then(on: .global(qos: .utility)) { result in
					return Tree.Item.RoutableRow(Tree.Content.MarketHistory(history: result), diffIdentifier: "MarketHistory", route: marketRoute)
				}.then(on: .main) { history in
					marketSection.children?.append(history.asAnyItem)
					self.view?.treeController.update(contentsOf: marketSection)
				}
			}
			
			let image = type.icon?.image?.image ?? context.eveIcon(.defaultType)?.image?.image
			
			let subtitle = type.marketGroup.map { sequence(first: $0, next: {$0.parentGroup})}?.compactMap { $0.marketGroupName }.joined(separator: " / ")
			
			var description = Tree.Content.InvTypeInfoDescription(prototype: Prototype.InvTypeInfoDescriptionCell.compact, title: type.typeName ?? "", subtitle: subtitle, image: image, typeDescription: type.typeDescription?.text)
			let descriptionRow = Tree.Item.Row<Tree.Content.InvTypeInfoDescription>(description, diffIdentifier: "Description")
			
			presentation.insert(descriptionRow.asAnyItem, at: 0)
			
			self.interactor.fullSizeImage(typeID: Int(type.typeID), dimension: 512).then(on: .main) { result in
				description.image = result
				description.prototype = Prototype.InvTypeInfoDescriptionCell.default
				presentation[0] = Tree.Item.Row<Tree.Content.InvTypeInfoDescription>(description, diffIdentifier: "Description").asAnyItem
				self.view?.treeController.reloadRow(for: presentation[0], with: .fade)
			}
			
			return presentation
		}
	}
}

extension Tree.Item {
	
	class DgmAttributeRow: RoutableRow<Tree.Content.Default> {
		
		init(attribute: SDEDgmTypeAttribute, value: Double?, context: SDEContext) {
			func toString(_ value: Double) -> String {
				var s = UnitFormatter.localizedString(from: value, unit: .none, style: .long)
				if let unit = attribute.attributeType?.unit?.displayName {
					s += " " + unit
				}
				return s
			}
			
			let unitID = (attribute.attributeType?.unit?.unitID).flatMap {SDEUnitID(rawValue: $0)} ?? .none
			let value = value ?? attribute.value
			
			var route: Routing?
			var image: UIImage?
			var subtitle: String?
			
			switch unitID {
			case .attributeID:
				let attributeType = context.dgmAttributeType(Int(value))
				subtitle = attributeType?.displayName ?? attributeType?.attributeName
			case .groupID:
				let group = context.invGroup(Int(value))
				subtitle = group?.groupName
				image = attribute.attributeType?.icon?.image?.image ?? group?.icon?.image?.image
				route = group.map{Router.SDE.invTypes(.group($0))}
			case .typeID:
				let type = context.invType(Int(value))
				subtitle = type?.typeName
				image = type?.icon?.image?.image ?? attribute.attributeType?.icon?.image?.image
				route = Router.SDE.invTypeInfo(.typeID(Int(value)))
			case .sizeClass:
				subtitle = SDERigSize(rawValue: Int(value))?.description ?? String(describing: Int(value))
			case .bonus:
				subtitle = "+" + UnitFormatter.localizedString(from: value, unit: .none, style: .long)
				image = attribute.attributeType?.icon?.image?.image
			case .boolean:
				subtitle = Int(value) == 0 ? NSLocalizedString("No", comment: "") : NSLocalizedString("Yes", comment: "")
			case .inverseAbsolutePercent, .inversedModifierPercent:
				subtitle = toString((1.0 - value) * 100.0)
			case .modifierPercent:
				subtitle = toString((value - 1.0) * 100.0)
			case .absolutePercent:
				subtitle = toString(value * 100.0)
			case .milliseconds:
				subtitle = toString(value / 1000.0)
			default:
				subtitle = toString(value)
			}
			
			let title: String
			if let displayName = attribute.attributeType?.displayName, !displayName.isEmpty {
				title = displayName
			}
			else if let attributeName = attribute.attributeType?.attributeName, !attributeName.isEmpty {
				title = attributeName
			}
			else {
				title = "\(attribute.attributeType?.attributeID ?? 0)"
			}
			
			let content = Tree.Content.Default(prototype: Prototype.DgmAttributeCell.default, title: title.uppercased(), subtitle: subtitle, image: image ?? attribute.attributeType?.icon?.image?.image, accessoryType: route == nil ? .none : .disclosureIndicator)
			
			super.init(content, diffIdentifier: attribute.objectID, route: route)
		}
	}
	
	class InvTypeRequiredSkillRow: TreeItem, CellConfiguring {
		var prototype: Prototype? { return Prototype.TreeDefaultCell.default}
		let skill: TrainingQueue.Item
		let level: Int
		let image: UIImage?
		let title: NSAttributedString
		let subtitle: String?
		let tintColor: UIColor
		let trainingTime: TimeInterval
		
		init?(type: SDEInvType, level: Int, character: Character?) {
			guard let skill = Character.Skill(type: type) else {return nil}
			title = NSAttributedString(skillName: type.typeName ?? "", level: level)
			self.level = level

			let trainedSkill = character?.trainedSkills[Int(type.typeID)]
			let item = TrainingQueue.Item(skill: skill, targetLevel: level, startSP: Int(trainedSkill?.skillpointsInSkill ?? 0))
			self.skill = item
			
			if let character = character {
				if let trainedSkill = trainedSkill, trainedSkill.trainedSkillLevel >= level {
					image = #imageLiteral(resourceName: "skillRequirementMe")
					subtitle = nil
					tintColor = .white
					trainingTime = 0
				}
				else {
					image = #imageLiteral(resourceName: "skillRequirementNotMe")
					let trainingTime = item.trainingTime(with: character.attributes)
					subtitle = trainingTime > 0 ? TimeIntervalFormatter.localizedString(from: trainingTime, precision: .seconds) : nil
					tintColor = trainingTime > 0 ? .lightText : .white
					self.trainingTime = trainingTime
				}
			}
			else {
				image = #imageLiteral(resourceName: "skillRequirementNotInjected")
				subtitle = nil
				tintColor = .white
				trainingTime = 0
			}
		}
		
		convenience init?(_ skill: SDEInvTypeRequiredSkill, character: Character?) {
			guard let type = skill.skillType else {return nil}
			self.init(type: type, level: Int(skill.skillLevel), character: character)
		}
		
		convenience init?(_ skill: SDEIndRequiredSkill, character: Character?) {
			guard let type = skill.skillType else {return nil}
			self.init(type: type, level: Int(skill.skillLevel), character: character)
		}
		
		convenience init?(_ skill: SDECertSkill, character: Character?) {
			guard let type = skill.type else {return nil}
			self.init(type: type, level: Int(skill.skillLevel), character: character)
		}

		static func == (lhs: Tree.Item.InvTypeRequiredSkillRow, rhs: Tree.Item.InvTypeRequiredSkillRow) -> Bool {
			return lhs === rhs
		}

		func configure(cell: UITableViewCell) {
			guard let cell = cell as? TreeDefaultCell else {return}
			cell.titleLabel?.attributedText = title
			cell.subtitleLabel?.text = subtitle
			cell.iconView?.image = image
			cell.iconView?.tintColor = tintColor
			
			let typeID = skill.skill.typeID
			let item = Services.storage.viewContext.currentAccount?.activeSkillPlan?.skills?.first(where: { (skill) -> Bool in
				let skill = skill as! SkillPlanSkill
				return Int(skill.typeID) == typeID && Int(skill.level) >= level
			})
			if item != nil {
				cell.iconView?.image = #imageLiteral(resourceName: "skillRequirementQueued")
			}
		}
		
		var hashValue: Int {
			return skill.hashValue
		}
		
		var children: [InvTypeRequiredSkillRow]?
	}
	
	class InvTypeSkillsSection: Section<Tree.Item.InvTypeRequiredSkillRow> {
		init<T: Hashable & CustomStringConvertible>(title: String, trainingQueue: TrainingQueue, character: Character?, identifier: T, treeController: TreeController?, children: [Tree.Item.InvTypeRequiredSkillRow]?) {
			let trainingTime = trainingQueue.trainingTime(with: character?.attributes ?? .default)
			
			let attributedTitle: NSAttributedString
			if trainingTime > 0 {
				attributedTitle = title + " " + TimeIntervalFormatter.localizedString(from: trainingTime, precision: .seconds) * [NSAttributedString.Key.foregroundColor: UIColor.white]
			}
			else {
				attributedTitle = NSAttributedString(string: title)
			}
			
//			let actions: Tree.Content.Section.Actions = character == nil || trainingTime == 0 ? [] : [.normal]
			let content = Tree.Content.Section(attributedTitle: attributedTitle, isExpanded: true)
			//TODO: Add SkillQueue handler
			
			super.init(content, diffIdentifier: identifier, expandIdentifier: identifier, treeController: treeController, children: children)
		}
		
	}
}

extension InvTypeInfoPresenter {
	func typeInfoPresentation(for type: SDEInvType, character: Character?, context: SDEContext, attributeValues: [Int: Double]?) -> [AnyTreeItem] {
		var sections = [AnyTreeItem]()
		
		if let section = skillPlanPresentation(for: type, character: character, context: context) {
			sections.append(section.asAnyItem)
		}

		if let section = masteriesPresentation(for: type, character: character, context: context) {
			sections.append(section.asAnyItem)
		}
		
		if let section = variationsPresentation(for: type, context: context) {
			sections.append(section.asAnyItem)
		}

		if let section = requiredForPresentation(for: type, context: context) {
			sections.append(section.asAnyItem)
		}

		let results = context.managedObjectContext.from(SDEDgmTypeAttribute.self)
			.filter(\SDEDgmTypeAttribute.type == type && \SDEDgmTypeAttribute.attributeType?.published == true)
			.sort(by: \SDEDgmTypeAttribute.attributeType?.attributeCategory?.categoryID, ascending: true)
			.sort(by: \SDEDgmTypeAttribute.attributeType?.attributeID, ascending: true)
			.fetchedResultsController(sectionName: \SDEDgmTypeAttribute.attributeType?.attributeCategory?.categoryID, cacheName: nil)
		
		do {
			try results.performFetch()
			sections.append(contentsOf:
				results.sections?.compactMap { section -> AnyTreeItem? in
					guard let attributeCategory = (section.objects?.first as? SDEDgmTypeAttribute)?.attributeType?.attributeCategory else {return nil}
					
					if SDEAttributeCategoryID(rawValue: attributeCategory.categoryID) == .requiredSkills {
						guard let section = requiredSkillsPresentation(for: type, character: character, context: context) else {return nil}
						return section.asAnyItem
					}
					else {
						let sectionTitle: String = SDEAttributeCategoryID(rawValue: attributeCategory.categoryID) == .null ? NSLocalizedString("Other", comment: "") : attributeCategory.categoryName ?? NSLocalizedString("Other", comment: "")
						
						var rows = [AnyTreeItem]()
						
						var damageRow: Tree.Item.DamageTypeRow?
						func damage() -> Tree.Item.DamageTypeRow? {
							if damageRow == nil {
								damageRow = Tree.Item.DamageTypeRow(Tree.Content.DamageType(prototype: Prototype.DamageTypeCell.compact, unit: .none, em: 0, thermal: 0, kinetic: 0, explosive: 0))
							}
							return damageRow
						}
						
						var resistanceRow: Tree.Item.DamageTypeRow?
						func resistance() -> Tree.Item.DamageTypeRow? {
							if resistanceRow == nil {
								resistanceRow = Tree.Item.DamageTypeRow(Tree.Content.DamageType(prototype: Prototype.DamageTypeCell.compact, unit: .percent, em: 0, thermal: 0, kinetic: 0, explosive: 0))
							}
							return resistanceRow
						}
						
						(section.objects as? [SDEDgmTypeAttribute])?.forEach { attribute in
							let value = attributeValues?[Int(attribute.attributeType!.attributeID)] ?? attribute.value
							
							switch SDEAttributeID(rawValue: attribute.attributeType!.attributeID) {
							case .emDamageResonance?, .armorEmDamageResonance?, .shieldEmDamageResonance?,
								 .hullEmDamageResonance?, .passiveArmorEmDamageResonance?, .passiveShieldEmDamageResonance?:
								guard let row = resistance() else {return}
								row.content.em = max(row.content.em, 1 - value)
							case .thermalDamageResonance?, .armorThermalDamageResonance?, .shieldThermalDamageResonance?,
								 .hullThermalDamageResonance?, .passiveArmorThermalDamageResonance?, .passiveShieldThermalDamageResonance?:
								guard let row = resistance() else {return}
								row.content.thermal = max(row.content.thermal, 1 - value)
							case .kineticDamageResonance?, .armorKineticDamageResonance?, .shieldKineticDamageResonance?,
								 .hullKineticDamageResonance?, .passiveArmorKineticDamageResonance?, .passiveShieldKineticDamageResonance?:
								guard let row = resistance() else {return}
								row.content.kinetic = max(row.content.kinetic, 1 - value)
							case .explosiveDamageResonance?, .armorExplosiveDamageResonance?, .shieldExplosiveDamageResonance?,
								 .hullExplosiveDamageResonance?, .passiveArmorExplosiveDamageResonance?, .passiveShieldExplosiveDamageResonance?:
								guard let row = resistance() else {return}
								row.content.explosive = max(row.content.explosive, 1 - value)
							case .emDamage?:
								damage()?.content.em = value
							case .thermalDamage?:
								damage()?.content.thermal = value
							case .kineticDamage?:
								damage()?.content.kinetic = value
							case .explosiveDamage?:
								damage()?.content.explosive = value
								
							case .warpSpeedMultiplier?:
								guard let attributeType = attribute.attributeType else {return}
								
								
								let baseWarpSpeed =  attributeValues?[Int(SDEAttributeID.baseWarpSpeed.rawValue)] ??
									(try? context.managedObjectContext.from(SDEDgmTypeAttribute.self).filter(\SDEDgmTypeAttribute.type == type && \SDEDgmTypeAttribute.attributeType?.attributeID == SDEAttributeID.baseWarpSpeed.rawValue).first())??.value
									?? 1.0
								var s = UnitFormatter.localizedString(from: Double(value * baseWarpSpeed), unit: .none, style: .long)
								s += " " + NSLocalizedString("AU/sec", comment: "")
								let row = Tree.Item.Row<Tree.Content.Default>(Tree.Content.Default(prototype: Prototype.DgmAttributeCell.default, title: NSLocalizedString("Warp Speed", comment: "").uppercased(), subtitle: s, image: attributeType.icon?.image?.image), diffIdentifier: "WarpSpeed")
								rows.append(row.asAnyItem)
							default:
								let row = Tree.Item.DgmAttributeRow(attribute: attribute, value: value, context: context)
								rows.append(row.asAnyItem)
							}
						}
						
						if let resistanceRow = resistanceRow {
							rows.append(resistanceRow.asAnyItem)
							
						}
						if let damageRow = damageRow {
							rows.append(damageRow.asAnyItem)
						}
						guard !rows.isEmpty else {return nil}
						
						return Tree.Item.Section(Tree.Content.Section(title: sectionTitle.uppercased()),
												 diffIdentifier: attributeCategory.objectID,
												 expandIdentifier: attributeCategory.objectID,
												 treeController: view?.treeController,
												 children: rows).asAnyItem
						
					}
				} ?? [])
		}
		catch {
		}
		
		
		return sections
	}
	
	func variationsPresentation(for type: SDEInvType, context: SDEContext) -> Tree.Item.Section<Tree.Item.Row<Tree.Content.Default>>? {
		guard type.parentType != nil || (type.variations?.count ?? 0) > 0 else {return nil}
		let n = max(type.variations?.count ?? 0, type.parentType?.variations?.count ?? 0) + 1
		let row = Tree.Item.Row<Tree.Content.Default>(Tree.Content.Default(prototype: Prototype.DgmAttributeCell.default,
																		   title: String.localizedStringWithFormat("%d types", n).uppercased()), diffIdentifier: "Variations")
		let section = Tree.Item.Section(Tree.Content.Section(title: NSLocalizedString("Variations", comment: "").uppercased(), isExpanded: true), diffIdentifier: "VariationsSection", expandIdentifier: "VariationsSection", treeController: view?.treeController, children: [row])
		return section
	}
	
	func requiredForPresentation(for type: SDEInvType, context: SDEContext) -> Tree.Item.Section<Tree.Item.Row<Tree.Content.Default>>? {
		guard let n = type.requiredForSkill?.count, n > 0 else { return nil }
		let row = Tree.Item.Row<Tree.Content.Default>(Tree.Content.Default(prototype: Prototype.DgmAttributeCell.default,
																		   title: String.localizedStringWithFormat("%d types", n).uppercased()), diffIdentifier: "RequiredFor")
		let section = Tree.Item.Section(Tree.Content.Section(title: NSLocalizedString("Required for", comment: "").uppercased(), isExpanded: true), diffIdentifier: "RequiredForSection", expandIdentifier: "RequiredForSection", treeController: view?.treeController, children: [row])
		return section
	}
	
	func skillPlanPresentation(for type: SDEInvType, character: Character?, context: SDEContext) -> Tree.Item.Section<Tree.Item.InvTypeRequiredSkillRow>? {
		guard (type.group?.category?.categoryID).flatMap({SDECategoryID(rawValue: $0)}) == .skill else {return nil}

		let rows = (1...5).compactMap {Tree.Item.InvTypeRequiredSkillRow(type: type, level: $0, character: character)}.filter {$0.trainingTime > 0}
		guard !rows.isEmpty else {return nil}
		
		return Tree.Item.Section(Tree.Content.Section(title: NSLocalizedString("Skill Plan", comment: "").uppercased(), isExpanded: true), diffIdentifier: "SkillPlan", expandIdentifier: "SkillPlan", treeController: view?.treeController, children: rows)
	}
	
	func masteriesPresentation(for type: SDEInvType, character: Character?, context: SDEContext) -> Tree.Item.Section<Tree.Item.Row<Tree.Content.Default>>? {
		var masteries = [Int: [SDECertMastery]]()
		
		(type.certificates?.allObjects as? [SDECertCertificate])?.forEach { certificate in
			(certificate.masteries?.array as? [SDECertMastery])?.forEach { mastery in
				masteries[Int(mastery.level?.level ?? 0), default: []].append(mastery)
			}
		}
		
		let unclaimedIcon = context.eveIcon(.mastery(nil))
		
		let character = character ?? .empty
		
		let rows = masteries.sorted {$0.key < $1.key}.compactMap { (key, array) -> Tree.Item.Row<Tree.Content.Default>? in
			guard let mastery = array.first else {return nil}
			guard let level = mastery.level else {return nil}
			
			let trainingQueue = TrainingQueue(character: character)
			array.forEach {trainingQueue.add($0)}
			let trainingTime = trainingQueue.trainingTime(with: character.attributes)
			
			let title = NSLocalizedString("Level", comment: "").uppercased() + " \(String(romanNumber: key + 1))"
			let subtitle = trainingTime > 0 ? TimeIntervalFormatter.localizedString(from: trainingTime, precision: .seconds) : nil
			let icon = trainingTime > 0 ? unclaimedIcon : level.icon
			
			return Tree.Item.Row<Tree.Content.Default>(Tree.Content.Default(prototype: Prototype.DgmAttributeCell.default, title: title, subtitle: subtitle, image: icon?.image?.image), diffIdentifier: mastery.objectID)

			//TODO: AddRoute
		}
		
		guard !rows.isEmpty else {return nil}
		return Tree.Item.Section(Tree.Content.Section(title: NSLocalizedString("Mastery", comment: "").uppercased(), isExpanded: true), diffIdentifier: "Mastery", expandIdentifier: "Mastery", treeController: view?.treeController, children: rows)
	}
	
	func requiredSkillsPresentation(for type: SDEInvType, character: Character?, context: SDEContext) -> Tree.Item.InvTypeSkillsSection? {
		guard let rows = requiredSkills(for: type, character: character, context: context), !rows.isEmpty else {return nil}
		let trainingQueue = TrainingQueue(character: character ?? .empty)
		trainingQueue.addRequiredSkills(for: type)
		return Tree.Item.InvTypeSkillsSection(title: NSLocalizedString("Required Skills", comment: "").uppercased(),
									   trainingQueue: trainingQueue,
									   character: character,
									   identifier: "RequiredSkills",
									   treeController: view?.treeController,
									   children: rows)
	}
	
	private func requiredSkills(for type: SDEInvType, character: Character?, context: SDEContext) -> [Tree.Item.InvTypeRequiredSkillRow]? {
		return (type.requiredSkills?.array as? [SDEInvTypeRequiredSkill])?.compactMap { requiredSkill -> Tree.Item.InvTypeRequiredSkillRow? in
			guard let type = requiredSkill.skillType else {return nil}
			guard let row = Tree.Item.InvTypeRequiredSkillRow(requiredSkill, character: character) else {return nil}
			row.children = requiredSkills(for: type, character: character, context: context)
			return row
		}
	}
}
