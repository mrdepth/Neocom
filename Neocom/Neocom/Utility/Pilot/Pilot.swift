//
//  Pilot.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/2/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI
import CoreData
import Expressible
import Combine
import Alamofire

struct Pilot: Codable {
    struct Skill: Hashable, Codable {
        let typeID: Int
        let primaryAttributeID: SDEAttributeID
        let secondaryAttributeID: SDEAttributeID
        let rank: Double
    }
    
    struct Attributes: Hashable, Codable {
        var intelligence: Int
        var memory: Int
        var perception: Int
        var willpower: Int
        var charisma: Int
    }
    
    struct SkillQueueItem: Hashable, Codable {
        var skill: Skill
        var queuedSkill: ESI.SkillQueueItem
    }
    
    var attributes: Attributes
    var augmentations: Attributes
    var trainedSkills: [Int: ESI.Skill]
    var skillQueue: [SkillQueueItem]
    
    static let empty = Pilot(attributes: .default, augmentations: .none, trainedSkills: [:], skillQueue: [])
}

extension Pilot {

    init(attributes: ESI.CharacterAttributes, skills: ESI.CharacterSkills, skillQueue: [ESI.SkillQueueItem], implants: [Int], context: NSManagedObjectContext) {
        let characterAttributes = Pilot.Attributes(intelligence: attributes.intelligence,
                                                       memory: attributes.memory,
                                                       perception: attributes.perception,
                                                       willpower: attributes.willpower,
                                                       charisma: attributes.charisma)
        
        var augmentations = Pilot.Attributes.none
        
        for implant in implants {
            guard let type = try? context.from(SDEInvType.self).filter(Expressions.keyPath(\SDEInvType.typeID) == Int32(implant)).first() else {continue}
            let attributes = [SDEAttributeID.intelligenceBonus, SDEAttributeID.memoryBonus, SDEAttributeID.perceptionBonus, SDEAttributeID.willpowerBonus, SDEAttributeID.charismaBonus].lazy.map({($0, Int(type[$0]?.value ?? 0))})
            guard let value = attributes.first(where: {$0.1 > 0}) else {continue}
            augmentations[value.0] += value.1
        }
        
        var trainedSkills = Dictionary(skills.skills.map { ($0.skillID, $0)}, uniquingKeysWith: {
            $0.trainedSkillLevel > $1.trainedSkillLevel ? $0 : $1
        })
        
        let currentDate = Date()
        var validSkillQueue = skillQueue.filter{$0.finishDate != nil}
        let i = validSkillQueue.partition(by: {$0.finishDate! > currentDate})
        for skill in validSkillQueue[..<i] {
            guard let endSP = try? skill.levelEndSP ?? context.from(SDEInvType.self).filter(Expressions.keyPath(\SDEInvType.typeID) == Int32(skill.skillID)).first().flatMap({Pilot.Skill(type: $0)})?.skillPoints(at: skill.finishedLevel) else {continue}
            
            let skill = ESI.Skill(activeSkillLevel: skill.finishedLevel, skillID: skill.skillID, skillpointsInSkill: Int64(endSP), trainedSkillLevel: skill.finishedLevel)
            trainedSkills[skill.skillID] = trainedSkills[skill.skillID].map {$0.trainedSkillLevel > skill.trainedSkillLevel ? $0 : skill} ?? skill
        }
        
        let sq = validSkillQueue[i...].sorted{$0.queuePosition < $1.queuePosition}.compactMap { i -> Pilot.SkillQueueItem? in
            guard let type = try? context.from(SDEInvType.self).filter(Expressions.keyPath(\SDEInvType.typeID) == Int32(i.skillID)).first(), let skill = Pilot.Skill(type: type) else {return nil}
            let item = Pilot.SkillQueueItem(skill: skill, queuedSkill: i)
            trainedSkills[i.skillID]?.skillpointsInSkill = Int64(item.skillPoints)
            return item
        }
        
        self.attributes = characterAttributes
        self.augmentations = augmentations
        self.trainedSkills = trainedSkills
        self.skillQueue = sq
    }
}


extension Pilot.Skill {
    init?(type: SDEInvType) {
        guard let primaryAttributeID = type[.primaryAttribute].flatMap({SDEAttributeID(rawValue: Int32($0.value))}),
            let secondaryAttributeID = type[.secondaryAttribute].flatMap({SDEAttributeID(rawValue: Int32($0.value))}),
            let rank = type[.skillTimeConstant]?.value else { return nil }
        typeID = Int(type.typeID)
        self.primaryAttributeID = primaryAttributeID
        self.secondaryAttributeID = secondaryAttributeID
        self.rank = rank
    }
    
    func skillPoints(at level: Int) -> Int {
        if (Bool(level == 0) || Bool(rank == 0)) {
            return 0
        }
        let sp = pow(2, 2.5 * Double(level) - 2.5) * 250.0 * Double(rank)
        return Int(sp.rounded(.up))
    }
    
    func level(with skillPoints: Int) -> Int {
        if (Bool(skillPoints == 0) || Bool(rank == 0)) {
            return 0
        }
        let level = (log(Double(skillPoints)/(250.0 * Double(rank))) / log(2.0) + 2.5) / 2.5;
        return Int(level.rounded(.down))
    }
    
    func skillPointsPerSecond(with attributes: Pilot.Attributes) -> Double {
        let primary = attributes[primaryAttributeID]
        let secondary = attributes[secondaryAttributeID]
        return (Double(primary) + Double(secondary) / 2.0) / 60.0;
    }
}

extension Pilot.Attributes {
    static let `default` = Pilot.Attributes(intelligence: 20, memory: 20, perception: 20, willpower: 20, charisma: 19)
    static let none = Pilot.Attributes(intelligence: 0, memory: 0, perception: 0, willpower: 0, charisma: 0)
    
    subscript(key: SDEAttributeID) -> Int {
        get {
            switch key {
            case .intelligence, .intelligenceBonus:
                return intelligence
            case .memory, .memoryBonus:
                return memory
            case .perception, .perceptionBonus:
                return perception
            case .willpower, .willpowerBonus:
                return willpower
            case .charisma, .charismaBonus:
                return charisma
            default:
                return 0
            }
        }
        set {
            switch key {
            case .intelligence, .intelligenceBonus:
                intelligence = newValue
            case .memory, .memoryBonus:
                memory = newValue
            case .perception, .perceptionBonus:
                perception = newValue
            case .willpower, .willpowerBonus:
                willpower = newValue
            case .charisma, .charismaBonus:
                charisma = newValue
            default:
                break
            }
        }
    }
    
    static func + (lhs: Pilot.Attributes, rhs: Pilot.Attributes) -> Pilot.Attributes {
        var lhs = lhs
        lhs.charisma += rhs.charisma
        lhs.intelligence += rhs.intelligence
        lhs.perception += rhs.perception
        lhs.willpower += rhs.willpower
        lhs.charisma += rhs.charisma
        return lhs
    }
    
    static func - (lhs: Pilot.Attributes, rhs: Pilot.Attributes) -> Pilot.Attributes {
        var lhs = lhs
        lhs.charisma -= rhs.charisma
        lhs.intelligence -= rhs.intelligence
        lhs.perception -= rhs.perception
        lhs.willpower -= rhs.willpower
        lhs.charisma -= rhs.charisma
        return lhs
    }
    
    static func += (lhs: inout Pilot.Attributes, rhs: Pilot.Attributes) {
        lhs.charisma += rhs.charisma
        lhs.intelligence += rhs.intelligence
        lhs.perception += rhs.perception
        lhs.willpower += rhs.willpower
        lhs.charisma += rhs.charisma
    }
    
    static func -= (lhs: inout Pilot.Attributes, rhs: Pilot.Attributes) {
        lhs.charisma -= rhs.charisma
        lhs.intelligence -= rhs.intelligence
        lhs.perception -= rhs.perception
        lhs.willpower -= rhs.willpower
        lhs.charisma -= rhs.charisma
    }
}

extension Pilot.SkillQueueItem {
    var skillPoints: Int {
        
        if let startDate = queuedSkill.startDate,
            let finishDate = queuedSkill.finishDate,
            let trainingStartSP = queuedSkill.trainingStartSP,
            let levelEndSP = queuedSkill.levelEndSP,
            finishDate > Date() {
            let t = finishDate.timeIntervalSince(startDate)
            if t > 0 {
                let spps = Double(levelEndSP - trainingStartSP) / t
                let t = finishDate.timeIntervalSinceNow
                let sp = Int(t > 0 ? Double(levelEndSP) - t * spps : Double(levelEndSP))
                return max(sp, trainingStartSP);
            }
            else {
                return levelEndSP
            }
        }
        return skill.skillPoints(at: max(queuedSkill.finishedLevel - 1, 0))
    }
    
    func trainingTimeToLevelUp(with attributes: Pilot.Attributes) -> TimeInterval {
        return Double(skillPointsToLevelUp) / skill.skillPointsPerSecond(with: attributes)
    }
    
    var skillPointsToLevelUp: Int {
        return skill.skillPoints(at: queuedSkill.finishedLevel) - skillPoints
    }

    var isActive: Bool {
        let date = Date()
        if let startDate = queuedSkill.startDate,
            let finishDate = queuedSkill.finishDate,
            finishDate > date && startDate < date {
            return true
        }
        else {
            return false
        }
    }
    
    var trainingProgress: Float {
        let level = queuedSkill.finishedLevel
        guard level > 0 else {return 0}
        
        let start = Double(skill.skillPoints(at: level - 1))
        let end = Double(skill.skillPoints(at: level))
        let left = Double(skillPointsToLevelUp)
        let progress = (1.0 - left / (end - start)).clamped(to: 0...1);
        return Float(progress)
    }
}

extension Pilot {
    static func load(_ characterID: ESI.Characters.CharacterID, in context: NSManagedObjectContext) -> AnyPublisher<Pilot, AFError> {
        return Publishers.Zip4(characterID.attributes().get(),
                               characterID.implants().get(),
                               characterID.skills().get(),
                               characterID.skillqueue().get()).flatMap { (attributes, implants, skills, skillQueue) in
                                Future { promise in
                                    context.perform {
                                        promise(.success(Pilot(attributes: attributes.value,
                                                               skills: skills.value,
                                                               skillQueue: skillQueue.value,
                                                               implants: implants.value,
                                                               context: context)))
                                    }
                                }
        }.eraseToAnyPublisher()
    }
}
