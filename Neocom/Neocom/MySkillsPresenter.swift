//
//  MySkillsPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 10/30/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import TreeController
import Expressible
import EVEAPI

class MySkillsPresenter: ContentProviderPresenter {
	typealias View = MySkillsViewController
	typealias Interactor = MySkillsInteractor
//	typealias Presentation = [AnyTreeItem]
	
	struct Presentation {
		struct Section {
			var rows: [Tree.Item.SkillRow]
			var groupName: String
			var skillPoints: Int64
		}
		var all: [Section] = []
		var my: [Section] = []
		var canTrain: [Section] = []
		var notKnown: [Section] = []
	}
	
	weak var view: View?
	lazy var interactor: Interactor! = Interactor(presenter: self)
	
	var content: Interactor.Content?
	var presentation: Presentation?
	var loading: Future<Presentation>?
	
	required init(view: View) {
		self.view = view
	}
	
	func configure() {
		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		let progress = Progress(totalUnitCount: 1)
		
		return Services.sde.performBackgroundTask { context -> Presentation in
			let frc = context.managedObjectContext
				.from(SDEInvType.self)
				.filter(\SDEInvType.published == true && \SDEInvType.group?.category?.categoryID == SDECategoryID.skill.rawValue)
				.sort(by: \SDEInvType.group?.groupName, ascending: true)
				.sort(by: \SDEInvType.typeName, ascending: true)
				.fetchedResultsController(sectionName: \SDEInvType.group?.groupName, cacheName: nil)
			
			try frc.performFetch()
			
			let partialProgress = progress.performAsCurrent(withPendingUnitCount: 1) { Progress(totalUnitCount: Int64(frc.sections!.count)) }
			
			var presentation = Presentation()
			
			for section in frc.sections! {
				guard let group = (section.objects?.first as? SDEInvType)?.group else {continue}
				var allRows = [Tree.Item.SkillRow]()
				var myRows = [Tree.Item.SkillRow]()
				var canTrainRows = [Tree.Item.SkillRow]()
				var notKnownRows = [Tree.Item.SkillRow]()

				
				(section.objects as? [SDEInvType])?.forEach { type in
					guard let skill = Character.Skill(type: type) else {return}
					let typeID = skill.typeID
					
					let trainedSkill = content.value.trainedSkills[Int(type.typeID)]
					let queuedSkill = content.value.skillQueue.filter{$0.queuedSkill.skillID == typeID}.min{$0.queuedSkill.finishedLevel < $1.queuedSkill.finishedLevel}
					
					let row: Tree.Item.SkillRow
					
					if let queuedSkill = queuedSkill {
						row = Tree.Item.SkillRow(.skillQueueItem(queuedSkill), character: content.value)
						myRows.append(row)
						canTrainRows.append(row)
					}
					else if let trainedSkill = trainedSkill {
						row = Tree.Item.SkillRow(.trainedSkill(skill, trainedSkill), character: content.value)
						myRows.append(row)
						if trainedSkill.trainedSkillLevel < 5 {
							canTrainRows.append(row)
						}
					}
					else {
						row = Tree.Item.SkillRow(.skill(skill), character: content.value)
						canTrainRows.append(row)
						notKnownRows.append(row)
					}
					
					allRows.append(row)
				}
				partialProgress.completedUnitCount += 1
				
				let totalSP = allRows.map { i -> Int64 in
					let skill = i.content.skill
					return (1...5).map{Int64(skill.skillPoints(at: $0))}.reduce(0, +)
				}.reduce(0, +)
				let mySP = myRows.map{Int64($0.content.skillPoints)}.reduce(0, +)
				let canTrainSP = totalSP - mySP
				let notKnownSP = notKnownRows.map { i -> Int64 in
					let skill = i.content.skill
					return (1...5).map{Int64(skill.skillPoints(at: $0))}.reduce(0, +)
				}.reduce(0, +)
				
				let groupName = group.groupName?.uppercased() ?? ""
				
				if !allRows.isEmpty {
					presentation.all.append(MySkillsPresenter.Presentation.Section(rows: allRows, groupName: groupName, skillPoints: totalSP))
				}
				
				if !myRows.isEmpty {
					presentation.my.append(MySkillsPresenter.Presentation.Section(rows: myRows, groupName: groupName, skillPoints: mySP))
				}
				
				if !canTrainRows.isEmpty {
					presentation.canTrain.append(MySkillsPresenter.Presentation.Section(rows: canTrainRows, groupName: groupName, skillPoints: canTrainSP))
				}
				
				if !notKnownRows.isEmpty {
					presentation.notKnown.append(MySkillsPresenter.Presentation.Section(rows: notKnownRows, groupName: groupName, skillPoints: notKnownSP))
				}
			}
			
			return presentation
		}
		
	}
}

extension Tree.Item {
	class SkillRow: RoutableRow<Tree.Content.Skill> {
		override var prototype: Prototype? {
			return Prototype.SkillCell.default
		}
		
		lazy var type: SDEInvType? = {
			return Services.sde.viewContext.invType(content.skill.typeID)
		}()
		
		let character: Character
		
		init(_ content: Tree.Content.Skill, character: Character) {
			self.character = character
			super.init(content, route: Router.SDE.invTypeInfo(.typeID(content.skill.typeID)))
		}
		
		override func configure(cell: UITableViewCell, treeController: TreeController?) {
			super.configure(cell: cell, treeController: treeController)
			guard let cell = cell as? SkillCell else {return}
			
			let skill: Character.Skill
			let trainingTime: TimeInterval
			let level: Int?
			let skillPoints: String
			let isActive: Bool
			let trainingProgress: Float
			
			switch content {
			case let .skill(item):
				skill = item
				trainingTime = TrainingQueue.Item(skill: skill, targetLevel: 1, startSP: nil).trainingTime(with: character.attributes)
				level = nil
				skillPoints = UnitFormatter.localizedString(from: 0, unit: .skillPoints, style: .long)
				isActive = false
				trainingProgress = 0
			case let .skillQueueItem(item):
				skill = item.skill
				isActive = item.isActive
				trainingProgress = item.trainingProgress
				trainingTime = item.trainingTimeToLevelUp(with: character.attributes)
				level = item.queuedSkill.finishedLevel
				
				let a = UnitFormatter.localizedString(from: item.skillPoints, unit: .none, style: .long)
				let b = UnitFormatter.localizedString(from: item.skill.skillPoints(at: level!), unit: .skillPoints, style: .long)
				skillPoints = "\(a) / \(b)"
			case let .trainedSkill(item, trainedSkill):
				skill = item
				trainingTime = trainedSkill.trainedSkillLevel < 5 ? TrainingQueue.Item(skill: skill, targetLevel: trainedSkill.trainedSkillLevel + 1, startSP: nil).trainingTime(with: character.attributes) : 0
				level = trainedSkill.trainedSkillLevel
				skillPoints = UnitFormatter.localizedString(from: trainedSkill.skillpointsInSkill, unit: .skillPoints, style: .long)
				isActive = false
				trainingProgress = 0
			}
			
			cell.titleLabel?.text = "\(type?.typeName ?? "") (x\(Int(skill.rank)))"
			cell.skillLevelView?.level = level ?? 0
			cell.skillLevelView?.isActive = isActive
			cell.progressView?.progress = trainingProgress

			if let level = level {
				cell.levelLabel?.text = NSLocalizedString("LEVEL", comment: "") + " " + String(romanNumber:level)
			}
			else {
				cell.levelLabel?.text = NSLocalizedString("N/A", comment: "")
			}
			
			let sph = Int((skill.skillPointsPerSecond(with: character.attributes) * 3600).rounded())
			cell.spLabel?.text = "\(skillPoints) (\(UnitFormatter.localizedString(from: sph, unit: .skillPointsPerSecond, style: .long)))"
			
			if trainingTime > 0 {
				cell.trainingTimeLabel?.text = TimeIntervalFormatter.localizedString(from: trainingTime, precision: .minutes)
			}
			else {
				cell.trainingTimeLabel?.text = NSLocalizedString("Completed", comment: "").uppercased()
			}
			
			let typeID = skill.typeID
			let item = Services.storage.viewContext.currentAccount?.activeSkillPlan?.skills?.first { (skill) -> Bool in
				let skill = skill as! SkillPlanSkill
				return Int(skill.typeID) == typeID && Int(skill.level) >= level ?? 0
			}
			if item != nil {
				cell.iconView?.image = #imageLiteral(resourceName: "skillRequirementQueued")
				cell.iconView?.isHidden = false
			}
			else {
				cell.iconView?.image = nil
				cell.iconView?.isHidden = true
			}
		}
	}
}

extension Tree.Content {
	enum Skill: Hashable {
		case skill(Character.Skill)
		case skillQueueItem(Character.SkillQueueItem)
		case trainedSkill(Character.Skill, ESI.Skills.CharacterSkills.Skill)
		
		var skill: Character.Skill {
			switch self {
			case let .skill(skill):
				return skill
			case let .skillQueueItem(item):
				return item.skill
			case let .trainedSkill(skill, _):
				return skill
			}
		}
		
		var skillPoints: Int {
			switch self {
			case let .skill(skill):
				return 0
			case let .skillQueueItem(item):
				return item.skillPoints
			case let .trainedSkill(_, skill):
				return Int(skill.skillpointsInSkill)
			}
		}
	}
}


