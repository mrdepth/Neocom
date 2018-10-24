//
//  SkillQueuePresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 19/10/2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import TreeController
import Expressible

class SkillQueuePresenter: TreePresenter {
	typealias View = SkillQueueViewController
	typealias Interactor = SkillQueueInteractor
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
		view?.tableView.register([Prototype.TreeHeaderCell.default,
								  Prototype.SkillCell.default])
		
		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		guard let account = Services.storage.viewContext.currentAccount else {return .init(.failure(NCError.authenticationRequired))}
		
		var sections = Presentation()
		
		let rows = content.value.skillQueue.map { Tree.Item.SkillQueueItem(character: content.value, skill: $0) }
		let finishDate = content.value.skillQueue.compactMap {$0.queuedSkill.finishDate}.max()
		
		let title: String
		if let finishDate = finishDate, !rows.isEmpty {
			title = String(format: NSLocalizedString("SKILL QUEUE: %@ (%d skills)", comment: ""),
						  TimeIntervalFormatter.localizedString(from: max(0, finishDate.timeIntervalSinceNow), precision: .minutes), rows.count)
		}
		else {
			title = NSLocalizedString("No skills in training", comment: "").uppercased()
		}
		
		let skillQueueSection = Tree.Item.Section(Tree.Content.Section(title: title), diffIdentifier: "SkillQueue", expandIdentifier: "SkillQueue", treeController: view?.treeController, children: rows)
		
		sections.append(skillQueueSection.asAnyItem)
		sections.append(Tree.Item.SkillPlansResultsController(account: account, treeController: view?.treeController, presenter: self).asAnyItem)
		

		return .init(sections)
	}
	
	func onSkillPlansAction(sender: UIControl) {
		guard let account = Services.storage.viewContext.currentAccount else {return}
		
		let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		controller.addAction(UIAlertAction(title: NSLocalizedString("Add Skill Plan", comment: ""), style: .default, handler: { _ in
			
			account.skillPlans?.forEach {
				($0 as? SkillPlan)?.active = false
			}
			
			let skillPlan = SkillPlan(context: account.managedObjectContext!)
			skillPlan.name = NSLocalizedString("Unnamed", comment: "")
			skillPlan.account = account
			skillPlan.active = true
			try? Services.storage.viewContext.save()
		}))
		
		controller.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
		view?.present(controller, animated: true, completion: nil)
	}
	
	func onSkillPlanAction(_ skillPlan: SkillPlan, sender: UIControl) {
		let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

		if (skillPlan.skills?.count ?? 0) > 0 {
			controller.addAction(UIAlertAction(title: NSLocalizedString("Clear", comment: ""), style: .default, handler: { _ in
				(skillPlan.skills?.allObjects as? [SkillPlanSkill])?.forEach { skill in
					skill.managedObjectContext?.delete(skill)
					skill.skillPlan = nil
				}
				
				try? Services.storage.viewContext.save()
			}))
		}
		
		if !skillPlan.active {
			controller.addAction(UIAlertAction(title: NSLocalizedString("Make Active", comment: ""), style: .default, handler: { _ in
				skillPlan.account?.skillPlans?.forEach {
					($0 as? SkillPlan)?.active = false
				}
				skillPlan.active = true
				try? Services.storage.viewContext.save()
			}))
		}
		
		controller.addAction(UIAlertAction(title: NSLocalizedString("Rename", comment: ""), style: .default, handler: { [weak self] (action) in
			let controller = UIAlertController(title: NSLocalizedString("Rename", comment: ""), message: nil, preferredStyle: .alert)
			
			var textField: UITextField?
			
			controller.addTextField(configurationHandler: {
				textField = $0
				textField?.text = skillPlan.name
				textField?.clearButtonMode = .always
			})
			
			controller.addAction(UIAlertAction(title: NSLocalizedString("Rename", comment: ""), style: .default, handler: { (action) in
				if textField?.text?.count ?? 0 > 0 && skillPlan.name != textField?.text {
					skillPlan.name = textField?.text
					try? Services.storage.viewContext.save()
				}
			}))
			
			controller.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
			
			self?.view?.present(controller, animated: true, completion: nil)
		}))
		
		if (skillPlan.account?.skillPlans?.count ?? 0) > 1 {
			controller.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: ""), style: .destructive, handler: { _ in
				
				if skillPlan.active {
					if let item = (skillPlan.account?.skillPlans?.sortedArray(using: [NSSortDescriptor(key: "name", ascending: true)]) as? [SkillPlan])?.first(where: { $0 !== skillPlan }) {
						item.active = true
					}
				}
				skillPlan.managedObjectContext?.delete(skillPlan)
				try? Services.storage.viewContext.save()
			}))
		}
		
		controller.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
		view?.present(controller, animated: true, completion: nil)

	}
}

extension Tree.Item {
	
	class SkillQueueItem: RoutableRow<Character.SkillQueueItem> {
		override var prototype: Prototype? {
			return Prototype.SkillCell.default
		}
		
		lazy var type: SDEInvType? = Services.sde.viewContext.invType(content.skill.typeID)
		let character: Character
		
		init(character: Character, skill: Character.SkillQueueItem) {
			self.character = character
			super.init(skill, route: Router.SDE.invTypeInfo(.typeID(skill.skill.typeID)))
		}
		
		override func configure(cell: UITableViewCell) {
			guard let cell = cell as? SkillCell else {return}
			let level = min(1 + content.queuedSkill.finishedLevel, 5)

			cell.iconView?.isHidden = true
			cell.titleLabel?.text = "\(type?.typeName ?? "") (x\(Int(content.skill.rank)))"
			cell.skillLevelView?.level = level
			cell.skillLevelView?.isActive = content.isActive
			cell.progressView?.progress = content.trainingProgress
			cell.levelLabel?.text = NSLocalizedString("LEVEL", comment: "") + " " + String(romanNumber:level)

			let a = UnitFormatter.localizedString(from: content.skillPoints, unit: .none, style: .long)
			let b = UnitFormatter.localizedString(from: content.skill.skillPoints(at: level), unit: .skillPoints, style: .long)
			
			
			
			let sph = Int((content.skill.skillpointsPerSecond(with: character.attributes) * 3600).rounded())
			cell.spLabel?.text = "\(a) / \(b) (\(UnitFormatter.localizedString(from: sph, unit: .skillPointsPerSecond, style: .long)))"
			
			if let from = content.queuedSkill.startDate, let to = content.queuedSkill.finishDate {
				cell.trainingTimeLabel?.text = TimeIntervalFormatter.localizedString(from: max(to.timeIntervalSince(max(from, Date())), 0), precision: .minutes)
			}
			else {
				cell.trainingTimeLabel?.text = nil
			}

		}
	}
	
	class SkillPlansResultsController: NamedFetchedResultsController<FetchedResultsSection<SkillPlanRow>> {
		weak var presenter: SkillQueuePresenter?
		private var section: Tree.Item.Section<Child>
		
		init(account: Account, treeController: TreeController?, presenter: SkillQueuePresenter?) {
			self.presenter = presenter

			let frc = Services.storage.viewContext.managedObjectContext
				.from(SkillPlan.self)
				.filter(\SkillPlan.account == account)
				.sort(by: \SkillPlan.active, ascending: false)
				.sort(by: \SkillPlan.name, ascending: true)
				.fetchedResultsController()

			section = Tree.Item.Section(Tree.Content.Section(title: NSLocalizedString("Skill Plans", comment: "").uppercased()),
										diffIdentifier: frc.fetchRequest,
										treeController: treeController,
										action: { [weak presenter] (control) in
											presenter?.onSkillPlansAction(sender: control)
											
			})
			
			super.init(Tree.Content.Section(title: NSLocalizedString("Skill Plans", comment: "").uppercased()), fetchedResultsController: frc, diffIdentifier: frc.fetchRequest, expandIdentifier: "SkillPlans", treeController: treeController)
		}
		
		override func configure(cell: UITableViewCell) {
			section.configure(cell: cell)
		}
	}
	
	class SkillPlanSkillsResultsController: FetchedResultsController<FetchedResultsSection<SkillPlanSkillRow>> {
		weak var presenter: SkillQueuePresenter?
		
		init(skillPlan: SkillPlan, treeController: TreeController?, presenter: SkillQueuePresenter?) {
			self.presenter = presenter
			
			let frc = skillPlan.managedObjectContext!.from(SkillPlanSkill.self)
				.filter(\SkillPlanSkill.skillPlan == skillPlan)
				.sort(by: \SkillPlanSkill.position, ascending: true)
				.fetchedResultsController()

			super.init(frc, diffIdentifier: frc.fetchRequest, treeController: treeController)
		}
	}
	
	class SkillPlanRow: Section<SkillPlanSkillsResultsController>, FetchedResultsTreeItem {
		typealias Result = SkillPlan
		
		private lazy var _children: [Child]? = {
			return [SkillPlanSkillsResultsController(skillPlan: result, treeController: section?.controller?.treeController, presenter: (section?.controller as? SkillPlansResultsController)?.presenter)]
		}()

		
		override var children: [Child]? {
			get {
				return _children
			}
			set {
				_children = newValue
			}
		}
		
		var result: Result
		weak var section: FetchedResultsSectionProtocol?
		
		required init(_ result: Result, section: FetchedResultsSectionProtocol) {
			self.result = result
			self.section = section
			let presenter = (section.controller as? SkillPlansResultsController)?.presenter
			super.init(Tree.Content.Section(title: result.name?.uppercased(), isExpanded: result.active), diffIdentifier: result, treeController: section.controller?.treeController)
			action = { [weak presenter] (control) in
				presenter?.onSkillPlanAction(result, sender: control)
			}
		}
		
//		override var hashValue: Int {
//			return result.hash
//		}
		
//		override func isEqual(_ other: Tree.Item.Base<Tree.Content.Section, Child>) -> Bool {
//			return type(of: self) == type(of: other) && result == (other as? SkillPlanRow)?.result
//		}
//
//		static func == (lhs: SkillPlanRow, rhs: SkillPlanRow) -> Bool {
//			return lhs.isEqual(rhs)
//		}
		
		override func configure(cell: UITableViewCell) {
			super.configure(cell: cell)
			guard let cell = cell as? TreeHeaderCell else {return}
			cell.titleLabel?.text = result.name?.uppercased()
		}

	}
	
	class SkillPlanSkillRow: FetchedResultsRow<SkillPlanSkill> {
		
	}
}



