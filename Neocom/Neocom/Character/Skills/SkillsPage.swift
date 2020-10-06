//
//  SkillsPage.swift
//  Neocom
//
//  Created by Artem Shimanski on 1/27/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible

struct SkillsPage: View {
    var skills: FetchedResultsController<SDEInvType>.Section
    @Binding var filter: SkillsFilter.Filter
    var pilot: Pilot?
    var editMode: Bool
    
    func cell(for type: SDEInvType) -> some View {
        let trainedSkill = pilot?.trainedSkills[Int(type.typeID)]
        return Group {
            if filter == .my && trainedSkill != nil {
                SkillCell(type: type, pilot: self.pilot, editMode: editMode)
            }
            else if filter == .canTrain && (trainedSkill?.trainedSkillLevel ?? 0) < 5 {
                SkillCell(type: type, pilot: self.pilot, editMode: editMode)
            }
            else if filter == .notKnown && trainedSkill == nil{
                SkillCell(type: type, pilot: self.pilot, editMode: editMode)
            }
            else if filter == .all {
                SkillCell(type: type, pilot: self.pilot, editMode: editMode)
            }
        }
    }
    
    var body: some View {
        List {
            Section(header: SkillsFilter(filter: $filter)) {
                ForEach(skills.objects, id: \.objectID) { type in
                    self.cell(for: type)
                }
            }
        }.listStyle(GroupedListStyle())
            .navigationBarTitle(skills.name)
        
    }
}

struct SkillsPage_Previews: PreviewProvider {
    static var previews: some View {
        let controller = Storage.testStorage.persistentContainer.viewContext
            .from(SDEInvType.self)
            .filter(/\SDEInvType.published == true && /\SDEInvType.group?.category?.categoryID == SDECategoryID.skill.rawValue)
            .sort(by: \SDEInvType.group?.groupName, ascending: true)
            .sort(by: \SDEInvType.typeName, ascending: true)
            .fetchedResultsController(sectionName: /\SDEInvType.group?.groupName, cacheName: nil)

        let frc = FetchedResultsController(controller)
        
        return NavigationView {
            SkillsPage(skills: frc.sections[0], filter: .constant(.my), editMode: false)
        }
    }
}
