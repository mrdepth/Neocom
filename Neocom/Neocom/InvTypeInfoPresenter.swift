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
	
	weak var view: View!
	lazy var interactor: Interactor! = Interactor(presenter: self)
	
	var content: Interactor.Content?
	var presentation: Presentation?
	var loading: Future<Presentation>?
	
	required init(view: View) {
		self.view = view
	}
	
	func configure() {
		view.tableView.register([Prototype.TreeHeaderCell.default])
		
		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		guard let input = view.input else { return .init(.failure(NCError.invalidInput(type: type(of: self))))}
		
		return Services.sde.performBackgroundTask { (context) -> Presentation in
			let type: SDEInvType
			switch input {
			case let .objectID(objectID):
				guard let invType: SDEInvType = try context.existingObject(with: objectID) else {throw NCError.invalidInput(type: Swift.type(of: self))}
				type = invType
			case let .type(invType):
				guard let invType: SDEInvType = try context.existingObject(with: invType.objectID) else {throw NCError.invalidInput(type: Swift.type(of: self))}
				type = invType
			case let .typeID(typeID):
				guard let invType = context.invType(typeID) else {throw NCError.invalidInput(type: Swift.type(of: self))}
				type = invType
			}
			
			return []
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
			
			let content = Tree.Content.Default(prototype: Prototype.DgmAttributeCell.default, title: title, subtitle: subtitle, image: image ?? attribute.attributeType?.icon?.image?.image)
			
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
				attributedTitle = title + TimeIntervalFormatter.localizedString(from: trainingTime, precision: .seconds) * [NSAttributedString.Key.foregroundColor: UIColor.white]
			}
			else {
				attributedTitle = NSAttributedString(string: title)
			}
			
			let prototype = character == nil ? Prototype.TreeHeaderCell.default : Prototype.TreeHeaderCell.editingAction
			let content = Tree.Content.Section(prototype: prototype, attributedTitle: attributedTitle, isExpanded: true)

			super.init(content, diffIdentifier: identifier, expandIdentifier: identifier, treeController: treeController, children: children)
		}
		
	}
}

extension InvTypeInfoPresenter {
	func typeInfoPresentation(for type: SDEInvType, character: Character?, context: SDEContext) -> [AnyTreeItem] {
		var sections = [AnyTreeItem]()
		
		if let section = skillPlanPresentation(for: type, character: character, context: context) {
			sections.append(section.asAnyItem)
		}

		if let section = masteriesPresentation(for: type, character: character, context: context) {
			sections.append(section.asAnyItem)
		}

		return sections
	}
	
	func skillPlanPresentation(for type: SDEInvType, character: Character?, context: SDEContext) -> Tree.Item.Section<Tree.Item.InvTypeRequiredSkillRow>? {
		guard (type.group?.category?.categoryID).flatMap({SDECategoryID(rawValue: $0)}) == .skill else {return nil}

		let rows = (1...5).compactMap {Tree.Item.InvTypeRequiredSkillRow(type: type, level: $0, character: character)}.filter {$0.trainingTime > 0}
		guard !rows.isEmpty else {return nil}

		return Tree.Item.Section(Tree.Content.Section(title: NSLocalizedString("Skill Plan", comment: "").uppercased(), isExpanded: true), diffIdentifier: "SkillPlan", expandIdentifier: "SkillPlan", treeController: view.treeController, children: rows)
	}
	
	func masteriesPresentation(for type: SDEInvType, character: Character?, context: SDEContext) -> Tree.Item.Section<Tree.Item.Row<Tree.Content.Default>>? {
		var masteries = [Int: [SDECertMastery]]()
		
		(type.certificates?.allObjects as? [SDECertCertificate])?.forEach { certificate in
			(certificate.masteries?.array as? [SDECertMastery])?.forEach { mastery in
				masteries[Int(mastery.level?.level ?? 0), default: []].append(mastery)
			}
		}
		
		let unclaimedIcon = context.eveIcon(.mastery(nil))
		
		let character = character ?? Character.empty
		
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
		return Tree.Item.Section(Tree.Content.Section(title: NSLocalizedString("Mastery", comment: "").uppercased(), isExpanded: true), diffIdentifier: "Mastery", expandIdentifier: "Mastery", treeController: view.treeController, children: rows)
	}
}
