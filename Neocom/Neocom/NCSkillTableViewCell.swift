//
//  NCSkillTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 15.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit

class NCSkillTableViewCell: NCTableViewCell {
	@IBOutlet weak var iconView: UIImageView?
	@IBOutlet weak var titleLabel: UILabel?
	@IBOutlet weak var levelLabel: UILabel?
	@IBOutlet weak var spLabel: UILabel?
	@IBOutlet weak var trainingTimeLabel: UILabel?
	@IBOutlet weak var progressView: UIProgressView?

	@IBOutlet weak var skillLevelView: NCSkillLevelView?
}

extension Prototype {
    enum NCSkillTableViewCell {
        static let `default` = Prototype(nib: UINib(nibName: "NCSkillTableViewCell", bundle: nil), reuseIdentifier: "NCSkillTableViewCell")
		static let compact = Prototype(nib: UINib(nibName: "NCSkillCompactTableViewCell", bundle: nil), reuseIdentifier: "NCSkillCompactTableViewCell")
    }
}

class NCSkillRow: TreeRow {
    let skill: NCSkill
	let character: NCCharacter
	
	init(prototype: Prototype = Prototype.NCSkillTableViewCell.default, skill: NCSkill, character: NCCharacter) {
        self.skill = skill
		self.character = character
		super.init(prototype: prototype, route: Router.Database.TypeInfo(skill.typeID))
    }
    
    lazy var image: UIImage? = {
        let typeID = Int32(self.skill.typeID)
        return NCAccount.current?.activeSkillPlan?.skills?.first(where: { ($0 as? NCSkillPlanSkill)?.typeID == typeID }) != nil ? #imageLiteral(resourceName: "skillRequirementQueued") : nil
    }()
	
	var trainingTime: String?
    
    override func configure(cell: UITableViewCell) {
        guard let cell = cell as? NCSkillTableViewCell else {return}
		cell.object = skill
        cell.titleLabel?.text = "\(skill.typeName) (x\(Int(skill.rank)))"
        if var level = skill.level {
			if skill.isActive {
				level = min(level + 1, 5)
			}
//            cell.levelLabel?.text = NSLocalizedString("LEVEL", comment: "") + " " + String(romanNumber:level)
			cell.levelLabel?.text = NSLocalizedString("LEVEL", comment: "") + " " + String(romanNumber:level)
			cell.skillLevelView?.level = level
			cell.skillLevelView?.isActive = skill.isActive
        }
        else {
            cell.levelLabel?.text = NSLocalizedString("N/A", comment: "")
			cell.skillLevelView?.level = 0
			cell.skillLevelView?.isActive = false
        }
		
		if let trainingTime = trainingTime {
			cell.trainingTimeLabel?.text = trainingTime
		}
		else {
			let level = (skill.level ?? 0)
			if level < 5 {
				cell.trainingTimeLabel?.text = " "
				NCDatabase.sharedDatabase?.performBackgroundTask { managedObjectContext in
					let trainingQueue = NCTrainingQueue(character: self.character)
					if let type = NCDBInvType.invTypes(managedObjectContext: managedObjectContext)[self.skill.typeID] {
						trainingQueue.add(skill: type, level: level + 1)
					}
					let t = trainingQueue.trainingTime(characterAttributes: self.character.attributes)
					let s = String(format: NSLocalizedString("%@ ", comment: ""),
					               NCTimeIntervalFormatter.localizedString(from: t, precision: .seconds))
					DispatchQueue.main.async {
						self.trainingTime = s
						if cell.object as? NCSkill === self.skill {
							cell.trainingTimeLabel?.text = s
						}
					}
				}
			}
			else {
				trainingTime = NSLocalizedString("COMPLETED", comment: "")
				cell.trainingTimeLabel?.text = trainingTime
			}
		}
        
		
        cell.iconView?.image = image
    }
    
    override var hashValue: Int {
        return skill.hashValue
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        return (object as? NCSkillRow)?.hashValue == hashValue
    }
}
