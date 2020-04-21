//
//  AddToSkillPlanButton.swift
//  Neocom
//
//  Created by Artem Shimanski on 1/9/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct AddToSkillPlanButton: View {
    var trainingQueue: TrainingQueue
    
    @EnvironmentObject private var sharedState: SharedState
    @State private var sheetIsPresented = false
    
    private var actionSheet: ActionSheet {
        ActionSheet(title: Text(TimeIntervalFormatter.localizedString(from: trainingQueue.trainingTime(), precision: .seconds)), message: nil, buttons: [
            .default(Text("Add to Skill Plan")) {
                let skillPlan = self.sharedState.account?.activeSkillPlan
                skillPlan?.add(self.trainingQueue)
                NotificationCenter.default.post(name: .didUpdateSkillPlan, object: skillPlan)
            },
            .cancel()])
    }

    var body: some View {
//        (!trainingQueue.queue.isEmpty ? account?.activeSkillPlan : nil).map { _ in
            Button(action: {
                self.sheetIsPresented.toggle()
            }) {
                Image(systemName: "ellipsis")
            }.actionSheet(isPresented: $sheetIsPresented) {self.actionSheet}
//        }
    }
}

struct AddToSkillPlanButton_Previews: PreviewProvider {
    static var previews: some View {
        AddToSkillPlanButton(trainingQueue: TrainingQueue(pilot: .empty))
            .environmentObject(SharedState.testState())
    }
}
