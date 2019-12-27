//
//  TypeInfoSkillCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/4/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI

extension TypeInfoData.Row {
    var skill: (Skill)? {
        switch self {
        case let .skill(skill):
            return skill
        default:
            return nil
        }
    }
}

struct TypeInfoSkillCell: View {
    var skillType: SDEInvType
    var level: Int
    var pilot: Pilot?
    @Environment(\.managedObjectContext) private var managedObjectContext

    private func content(image: Image?, trainingTime: TimeInterval?, color: Color) -> some View {
        NavigationLink(destination: TypeInfo(type: skillType)) {
            HStack {
                image?.font(.caption).foregroundColor(color)
                VStack(alignment: .leading) {
                    SkillName(name: skillType.typeName?.uppercased() ?? "", level: level).font(.footnote)
                    trainingTime.map{Text(TimeIntervalFormatter.localizedString(from: $0, precision: .seconds)).font(.footnote).foregroundColor(.secondary)}
                }
            }
        }
    }
    
    var body: some View {
        let skill = Pilot.Skill(type: skillType)
        let trainedSkill = pilot?.trainedSkills[Int(skillType.typeID)]
        let item = skill.map{TrainingQueue.Item(skill: $0, targetLevel: level, startSP: Int(trainedSkill?.skillpointsInSkill ?? 0))}
        let trainingTime = item?.trainingTime(with: pilot?.attributes ?? .default)
        
        return Group {
            if item != nil {
                if pilot != nil {
                    if trainedSkill.map({$0.trainedSkillLevel >= level}) == true {
                        content(image: Image(systemName: "checkmark.circle"), trainingTime: nil, color: .primary)
                    }
                    else if trainedSkill == nil {
                        content(image: Image(systemName: "xmark.circle"), trainingTime: trainingTime, color: .secondary)
                    }
                    else {
                        content(image: Image(systemName: "circle"), trainingTime: trainingTime, color: .secondary)
                    }
                }
                else {
                    content(image: nil,
                            trainingTime: trainingTime,
                            color: .secondary)
                }
            }
        }
    }
}

struct TypeInfoSkillCell_Previews: PreviewProvider {
    static var previews: some View {
        let skill = try! AppDelegate.sharedDelegate.persistentContainer.viewContext.fetch(SDEInvType.dominix()).first?.requiredSkills?.firstObject as? SDEInvTypeRequiredSkill
        return NavigationView {
            List {
                TypeInfoSkillCell(skillType: skill!.skillType!, level: 5, pilot: nil)
                TypeInfoSkillCell(skillType: skill!.skillType!, level: 5, pilot: .empty)
            }.listStyle(GroupedListStyle())
                .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        }
    }
}

