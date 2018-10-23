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
		
		let controller = Services.storage.viewContext.managedObjectContext
			.from(SkillPlan.self)
			.filter(\SkillPlan.account == account)
			.sort(by: \SkillPlan.active, ascending: false)
			.sort(by: \SkillPlan.name, ascending: true)
			.fetchedResultsController()
		
		let skillPlans = Tree.Item.NamedFetchedResultsController<Tree.Item.FetchedResultsSection<Tree.Item.SkillPlanRow>>(Tree.Content.Section(title: NSLocalizedString("Skill Plans", comment: "").uppercased()), fetchedResultsController: controller, treeController: view?.treeController)
		
		sections.append(skillPlans.asAnyItem)

		return .init(sections)
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
	
	class SkillPlanRow: FetchedResultsRow<SkillPlan> {
		override var prototype: Prototype? {
			return Prototype.TreeHeaderCell.default
		}
		
		override func configure(cell: UITableViewCell) {
			guard let cell = cell as? TreeHeaderCell else {return}
			cell.titleLabel?.text = result.name
		}
	}
}


