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

}

extension Prototype {
    enum NCSkillTableViewCell {
        static let `default` = Prototype(nib: UINib(nibName: "NCSkillTableViewCell", bundle: nil), reuseIdentifier: "NCSkillTableViewCell")
    }
}

class NCSkillRow: TreeRow {
    let skill: NCSkill
    init(skill: NCSkill) {
        self.skill = skill
		super.init(prototype: Prototype.NCSkillTableViewCell.default, route: Router.Database.TypeInfo(skill.typeID))
    }
    
    lazy var image: UIImage? = {
        let typeID = Int32(self.skill.typeID)
        return NCAccount.current?.activeSkillPlan?.skills?.first(where: { ($0 as? NCSkillPlanSkill)?.typeID == typeID }) != nil ? #imageLiteral(resourceName: "skillRequirementQueued") : nil
    }()
    
    override func configure(cell: UITableViewCell) {
        guard let cell = cell as? NCSkillTableViewCell else {return}
        cell.titleLabel?.text = "\(skill.typeName) (x\(skill.rank))"
        if let level = skill.level {
            cell.levelLabel?.text = NSLocalizedString("LEVEL", comment: "") + " " + String(romanNumber:level)
            
        }
        else {
            cell.levelLabel?.text = nil
        }
        
        let level = (skill.level ?? 0)
        if level < 5 {
            cell.trainingTimeLabel?.text = String(format: NSLocalizedString("%@ ", comment: ""),
                                                  //String(romanNumber:level + 1),
                NCTimeIntervalFormatter.localizedString(from: skill.trainingTimeToLevelUp(characterAttributes: NCCharacterAttributes()), precision: .seconds))
            
        }
        else {
            cell.trainingTimeLabel?.text = NSLocalizedString("COMPLETED", comment: "")
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
