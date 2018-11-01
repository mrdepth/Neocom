//
//  SkillCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 10/23/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI
import TreeController

class SkillCell: RowCell {
	@IBOutlet weak var iconView: UIImageView?
	@IBOutlet weak var titleLabel: UILabel?
	@IBOutlet weak var levelLabel: UILabel?
	@IBOutlet weak var spLabel: UILabel?
	@IBOutlet weak var trainingTimeLabel: UILabel?
	@IBOutlet weak var progressView: UIProgressView?
	
	@IBOutlet weak var skillLevelView: SkillLevelView?
}

extension Prototype {
	enum SkillCell {
		static let `default` = Prototype(nib: UINib(nibName: "SkillCell", bundle: nil), reuseIdentifier: "SkillCell")
	}
}

class SkillLevelView: UIView {
	
	var layers: [CALayer] = []
	var level: Int = 0 {
		didSet {
			layers.enumerated().forEach {
				$0.element.backgroundColor = $0.offset < level ? UIColor.gray.cgColor : UIColor.clear.cgColor
			}
			NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(updateAnimation), object: nil)
			perform(#selector(updateAnimation), with: nil, afterDelay: 0)
		}
	}
	
	private var animation: (CALayer, CABasicAnimation)? {
		didSet {
			if let old = oldValue {
				old.0.removeAnimation(forKey: "backgroundColor")
			}
		}
	}
	
	var isActive: Bool = false {
		didSet {
			NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(updateAnimation), object: nil)
			perform(#selector(updateAnimation), with: nil, afterDelay: 0)
		}
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		layers = (0..<5).map { i in
			let layer = CALayer()
			layer.backgroundColor = tintColor.cgColor
			self.layer.addSublayer(layer)
			return layer
		}
		layer.borderColor = tintColor.cgColor
		layer.borderWidth = ThinnestLineWidth
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		layers = (0..<5).map { i in
			let layer = CALayer()
			layer.backgroundColor = tintColor.cgColor
			self.layer.addSublayer(layer)
			return layer
		}
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
	}
	
	
	override func layoutSubviews() {
		super.layoutSubviews()
		var rect = CGRect.zero
		rect.size.width = (bounds.width - CGFloat(layers.count) - 1) / CGFloat(layers.count)
		rect.size.height = min(bounds.height, 5)
		rect.origin.y = (bounds.height - rect.height) / 2
		rect.origin.x = 1
		rect = rect.integral
		
		for layer in layers {
			layer.frame = rect
			rect.origin.x += rect.size.width + 1
		}
	}
	
	override var intrinsicContentSize: CGSize {
		return CGSize(width: 8 * 5 + 6, height: 7)
	}
	
	override func didMoveToWindow() {
		super.didMoveToWindow()
		if window == nil {
			animation = nil
		}
		else if animation == nil {
			NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(updateAnimation), object: nil)
			perform(#selector(updateAnimation), with: nil, afterDelay: 0)
		}
	}
	
	@objc private func updateAnimation() {
		self.animation = nil
		if self.isActive && (1...5).contains(self.level) {
			let layer = self.layers[self.level - 1]
			let animation = CABasicAnimation(keyPath: "backgroundColor")
			animation.fromValue = self.tintColor.cgColor
			animation.toValue = UIColor.white.cgColor
			animation.duration = 0.5
			animation.repeatCount = .greatestFiniteMagnitude
			animation.autoreverses = true
			layer.add(animation, forKey: "backgroundColor")
			self.animation = (layer, animation)
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
			case .skill:
				return 0
			case let .skillQueueItem(item):
				return item.skillPoints
			case let .trainedSkill(_, skill):
				return Int(skill.skillpointsInSkill)
			}
		}
	}
}


