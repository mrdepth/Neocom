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
		return .init([])
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
			
			let content = Tree.Content.Default(prototype: Prototype.TreeDefaultCell.default, title: title, subtitle: subtitle, image: image ?? attribute.attributeType?.icon?.image?.image)
			
			super.init(content, diffIdentifier: attribute.objectID, route: route)
		}
	}
	
	class RequiredSkillRow: TreeItem, CellConfiguring {
		var prototype: Prototype? { return Prototype.TreeDefaultCell.default}
		
		init(type: SDEInvType, level: Int, character: Character?) {
			let image: UIImage?
			
			if let trained = character?.trainedSkills[Int(type.typeID)] {
				if trained >= level {
					image = #imageLiteral(resourceName: "skillRequirementMe")
				}
				else {
					image = #imageLiteral(resourceName: "skillRequirementNotMe")
					let skill = Character.Skill(type: type)!
					TrainingQueue.Item(skill: skill, targetLevel: level, startSP: nil)
				}
			}
			else {
				image = #imageLiteral(resourceName: "skillRequirementNotInjected")
			}
		}
		
		convenience init(_ skill: SDEInvTypeRequiredSkill) {
		}
		
		convenience init(_ skill: SDEIndRequiredSkill) {
			
		}
		
		convenience init(_ skill: SDECertSkill) {
			
		}

		static func == (lhs: Tree.Item.RequiredSkillRow, rhs: Tree.Item.RequiredSkillRow) -> Bool {
			return lhs === rhs
		}

		func configure(cell: UITableViewCell) {
		}
		
		var hashValue: Int {
			return diffIdentifier.hashValue
		}
		
		var children: [RequiredSkillRow]?
	}
}
