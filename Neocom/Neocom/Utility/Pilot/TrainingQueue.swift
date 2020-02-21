//
//  TrainingQueue.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/2/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation
import CoreData
import Expressible

class TrainingQueue {
    struct Item: Hashable {
        let skill: Pilot.Skill
        let targetLevel: Int
        let startSP: Int
        let finishSP: Int
    }
    let pilot: Pilot
    var queue: [Item] = []
    
    init(pilot: Pilot) {
        self.pilot = pilot
    }

    init(pilot: Pilot, skillPlan: SkillPlan) {
        self.pilot = pilot
        add(skillPlan)
    }

    func add(_ skillType: SDEInvType, level: Int) {
        guard let skill = Pilot.Skill(type: skillType) else {return}
        addRequiredSkills(for: skillType)
        
        let typeID = Int(skillType.typeID)
        let trainedLevel = pilot.trainedSkills[typeID]?.trainedSkillLevel ?? 0
        
        guard trainedLevel < level else {return}
        
        let queuedLevels = IndexSet(queue.filter({$0.skill.typeID == typeID}).map{$0.targetLevel})
        
        for i in (trainedLevel + 1)...level {
            if !queuedLevels.contains(i) {
                let sp = pilot.skillQueue.first(where: {$0.skill.typeID == skill.typeID && $0.queuedSkill.finishedLevel == i})?.skillPoints
                queue.append(Item(skill: skill, targetLevel: i, startSP: sp))
            }
        }
    }

    func add(_ mastery: SDECertMastery) {
        mastery.skills?.forEach {
            guard let skill = $0 as? SDECertSkill else {return}
            guard let type = skill.type else {return}
            add(type, level: max(Int(skill.skillLevel), 1))
        }
    }

    func addRequiredSkills(for type: SDEInvType) {
        type.requiredSkills?.forEach {
            guard let requiredSkill = ($0 as? SDEInvTypeRequiredSkill) else {return}
            guard let type = requiredSkill.skillType else {return}
            add(type, level: Int(requiredSkill.skillLevel))
        }
    }

    func addRequiredSkills(for activity: SDEIndActivity) {
        activity.requiredSkills?.forEach {
            guard let requiredSkill = ($0 as? SDEIndRequiredSkill) else {return}
            guard let type = requiredSkill.skillType else {return}
            add(type, level: Int(requiredSkill.skillLevel))
        }
    }
    
    func add(_ skillPlan: SkillPlan) {
        skillPlan.skills?.compactMap { skill in
            (skill as? SkillPlanSkill).flatMap{ skill in
                (try? skill.managedObjectContext?.from(SDEInvType.self).filter(/\SDEInvType.typeID == Int32(skill.typeID)).first()).map{($0, skill.level)}
            }
        }.forEach { (type, level) in
            add(type, level: Int(level))
        }
    }
    
    func add(_ skillQueue: [Pilot.SkillQueueItem], managedObjectContext: NSManagedObjectContext) {
        let skills = Dictionary(skillQueue.map{($0.queuedSkill.skillID, $0.queuedSkill.finishedLevel)}, uniquingKeysWith: {a, b in max(a, b)})
        for (typeID, level) in skills {
            guard let type = try? managedObjectContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == Int32(typeID)).first() else {continue}
            add(type, level: level)
        }
    }
    
    func remove(_ item: TrainingQueue.Item) {
        let indexes = IndexSet(queue.enumerated().filter {$0.element.skill.typeID == item.skill.typeID && $0.element.targetLevel >= item.targetLevel}.map{$0.offset})
        indexes.reversed().forEach {queue.remove(at: $0)}
        indexes.rangeView.reversed().forEach { queue.removeSubrange($0) }
    }

    func trainingTime() -> TimeInterval {
        return trainingTime(with: pilot.attributes)
    }

    func trainingTime(with attributes: Pilot.Attributes) -> TimeInterval {
        return queue.map {$0.trainingTime(with: attributes)}.reduce(0, +)
    }

}

extension TrainingQueue.Item {
    
    init(skill: Pilot.Skill, targetLevel: Int, startSP: Int?) {
        self.skill = skill
        self.targetLevel = targetLevel
        let finishSP = skill.skillPoints(at: targetLevel)
        self.startSP = min(startSP ?? skill.skillPoints(at: targetLevel - 1), finishSP)
        self.finishSP = finishSP
    }
    
    func trainingTime(with attributes: Pilot.Attributes) -> TimeInterval {
        return Double(finishSP - startSP) / skill.skillPointsPerSecond(with: attributes)
    }
}

extension Pilot.Attributes {
    struct Key: Hashable {
        let primary: SDEAttributeID
        let secondary: SDEAttributeID
    }
    
    init(optimalFor trainingQueue: TrainingQueue) {
        var skillPoints: [Key: Int] = [:]
        for item in trainingQueue.queue {
            let sp = item.finishSP - item.startSP
            let key = Key(primary: item.skill.primaryAttributeID, secondary: item.skill.secondaryAttributeID)
            skillPoints[key, default: 0] += sp
        }
        
        let basePoints = 17
        let bonusPoints = 14
        let maxPoints = 27
        let totalMaxPoints = basePoints * 5 + bonusPoints
        var minTrainingTime = TimeInterval.greatestFiniteMagnitude
        
        var optimal = Pilot.Attributes.default
        
        for intelligence in basePoints...maxPoints {
            for memory in basePoints...maxPoints {
                for perception in basePoints...maxPoints {
                    guard intelligence + memory + perception < totalMaxPoints - basePoints * 2 else {break}
                    for willpower in basePoints...maxPoints {
                        guard intelligence + memory + perception + willpower < totalMaxPoints - basePoints else {break}
                        let charisma = totalMaxPoints - (intelligence + memory + perception + willpower)
                        guard charisma <= maxPoints else {continue}
                        
                        let attributes = Pilot.Attributes(intelligence: intelligence, memory: memory, perception: perception, willpower: willpower, charisma: charisma)
                        
                        let trainingTime = skillPoints.reduce(0) { (t, i) -> TimeInterval in
                            let primary = attributes[i.key.primary]
                            let secondary = attributes[i.key.secondary]
                            return t + TimeInterval(i.value) / (TimeInterval(primary) + TimeInterval(secondary) / 2)
                        }
                        
                        if trainingTime < minTrainingTime {
                            minTrainingTime = trainingTime
                            optimal = attributes
                        }
                    }
                }
            }
        }
        self = optimal
    }
}
