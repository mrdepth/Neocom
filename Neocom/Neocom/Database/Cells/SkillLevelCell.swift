//
//  SkillLevelCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/22/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct SkillLevelCell: View {
    var type: SDEInvType
    var skill: Pilot.Skill
    var level: Int
    var pilot: Pilot?
    @EnvironmentObject private var sharedState: SharedState
    @State private var sheetIsPresented = false
    
    private var actionSheet: ActionSheet {
        let trainingQueue = TrainingQueue(pilot: pilot ?? .empty)
        trainingQueue.add(self.type, level: level)
        
        return ActionSheet(title: Text(TimeIntervalFormatter.localizedString(from: trainingQueue.trainingTime(), precision: .seconds)), message: nil, buttons: [
            .default(Text("Add to Skill Plan")) {
                let skillPlan = self.sharedState.account?.activeSkillPlan
                skillPlan?.add(trainingQueue)
                NotificationCenter.default.post(name: .didUpdateSkillPlan, object: skillPlan)
            },
            .cancel()])
    }
    
    var body: some View {
        let t = TrainingQueue.Item(skill: skill, targetLevel: level, startSP: nil).trainingTime(with: pilot?.attributes ?? .default)
//        let queued = (sharedState.account?.activeSkillPlan?.skills?.allObjects as? [SkillPlanSkill])?.contains{$0.typeID == type.typeID && $0.level == Int16(level)}
        
        return Button(action: {self.sheetIsPresented = true}) {
            HStack {
                sharedState.account?.activeSkillPlan.map {
                    SkillLevelQueueIndicator(skillPlan: $0, type: type, level: level)
                }
                VStack(alignment: .leading) {
                    Text("Train to Level") + Text(" \(String(roman: level))").fontWeight(.semibold)
                    Text(TimeIntervalFormatter.localizedString(from: t, precision: .seconds)).modifier(SecondaryLabelModifier())
                }
                Spacer()
            }.contentShape(Rectangle())
        }.buttonStyle(PlainButtonStyle())
        .actionSheet(isPresented: $sheetIsPresented) {self.actionSheet}
    }
}

fileprivate struct SkillLevelQueueIndicator: View {
    @ObservedObject var skillPlan: SkillPlan
    var type: SDEInvType
    var level: Int
    
    var body: some View {
        let queued = (skillPlan.skills?.allObjects as? [SkillPlanSkill])?.contains{$0.typeID == type.typeID && $0.level == Int16(level)}
        return Group {
            if queued == true {
                Image(systemName: "clock").foregroundColor(.secondary)
            }
        }
    }
}

struct SkillLevelCell_Previews: PreviewProvider {
    static var previews: some View {
        let type = SDEInvType.gallenteCarrier
        return List {
            SkillLevelCell(type: type, skill: Pilot.Skill(type: type)!, level: 1, pilot: nil)
        }.listStyle(GroupedListStyle())
            .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
            .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext.newBackgroundContext())
            .environmentObject(SharedState.testState())
    }
}
