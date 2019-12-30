//
//  SkillsList.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/30/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation

struct SkillsList {
    struct Skill {
        var type: SDEInvType
        var level: Int16
    }
    
    var skills: [Skill] = []
    
    init() {
    }
    
    init(requiredSkillsFor type: SDEInvType) {
        self = (type.requiredSkills?.array as? [SDEInvTypeRequiredSkill])?.map{SkillsList(skill: $0.skillType!, level: $0.skillLevel)}.reduce(SkillsList(), +) ?? SkillsList()
    }
    
    init(requiredSkillsFor activity: SDEIndActivity) {
        self = (activity.requiredSkills?.allObjects as? [SDEIndRequiredSkill])?
            .sorted{$0.skillType!.typeName! < $1.skillType!.typeName!}
            .map{SkillsList(skill: $0.skillType!, level: $0.skillLevel)}.reduce(SkillsList(), +) ?? SkillsList()
    }
    
    init(skill: SDEInvType, level: Int16) {
        var skills = [skill: (level: level, order: 0)]
        var order = 1
        func enumerate(_ type: SDEInvType) {
            (type.requiredSkills?.array as? [SDEInvTypeRequiredSkill])?.sorted{$0.skillType!.typeName! < $1.skillType!.typeName!}.forEach { i in
                guard let skillType = i.skillType else {return}
                if var value = skills[skillType] {
                    value.level = max(value.level, i.skillLevel)
                    skills[skillType] = value
                }
                else {
                    skills[skillType] = (i.skillLevel, order)
                    order += 1
                }
                enumerate(skillType)
            }
        }
        enumerate(skill)
        self.skills = skills.sorted{$0.value.order < $1.value.order}.map{Skill(type: $0.key, level: $0.value.level)}
    }
    
    fileprivate init(skills: [Skill]) {
        self.skills = skills
    }
}

func + (lhs: SkillsList, rhs: SkillsList) -> SkillsList {
    let skills = Dictionary(lhs.skills.enumerated().map{($0.element.type, $0.offset)}) {a, _ in a}
    var output = lhs.skills
    for i in rhs.skills {
        if let j = skills[i.type] {
            output[j].level = max(output[j].level, i.level)
        }
        else {
            output.append(i)
        }
    }
    return SkillsList(skills: output)
}
