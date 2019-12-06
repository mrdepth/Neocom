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
    @Environment(\.managedObjectContext) var managedObjectContext
    var skill: TypeInfoData.Row.Skill
    var body: some View {
        NavigationLink(destination: TypeInfo(type: managedObjectContext.object(with: skill.id) as! SDEInvType)) {
            HStack {
                skill.image.font(.caption).foregroundColor(Color(skill.color))
                VStack(alignment: .leading) {
                    SkillName(name: skill.name.uppercased(), level: skill.level).font(.footnote)
                    skill.trainingTime.map{Text($0).font(.footnote).foregroundColor(.secondary)}
                }
            }
        }
    }
}

struct TypeInfoSkillCell_Previews: PreviewProvider {
    static var previews: some View {
        let skill = TypeInfoData.Row((try? AppDelegate.sharedDelegate.persistentContainer.viewContext.fetch(SDEInvType.dominix()).first?.requiredSkills?.firstObject as? SDEInvTypeRequiredSkill)!.skillType!,
                                     level: 5, pilot: nil)!.skill!
        return NavigationView {
            List {
                TypeInfoSkillCell(skill: skill)
            }.listStyle(GroupedListStyle())
                .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        }
    }
}

 
