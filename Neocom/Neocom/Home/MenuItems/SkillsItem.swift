//
//  SkillsItem.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/26/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import Alamofire

struct SkillsItem: View {
    @EnvironmentObject private var sharedState: SharedState
    @ObservedObject private var skills = Lazy<DataLoader<[ESI.SkillQueueItem], AFError>, Account>()
    
    let require: [ESI.Scope] = [.esiSkillsReadSkillqueueV1,
                                .esiSkillsReadSkillsV1,
                                .esiClonesReadImplantsV1]
    
    var body: some View {
        let result = sharedState.account.map{self.skills.get($0, initial: DataLoader(sharedState.esi.characters.characterID(Int($0.characterID)).skillqueue().get().map{$0.value}.receive(on: RunLoop.main)))}?.result
        let skillQueue = result?.value
        let error = result?.error
        
        
        let trainingTime = skillQueue.map { result -> Text in
            let date = Date()
            let queue = result.compactMap{$0.finishDate}.filter{$0 > date}
            if let finishDate = queue.max() {
                return Text("\(queue.count) skills in queue (\(TimeIntervalFormatter.localizedString(from: finishDate.timeIntervalSinceNow, precision: .minutes)))")
            }
            else {
                return Text("No skills in training")
            }
        }
        
        return Group {
            if sharedState.account?.verifyCredentials(require) == true {
                NavigationLink(destination: SkillQueue()) {
                    Icon(Image("skills"))
                    VStack(alignment: .leading) {
                        Text("Skills")
                        if trainingTime != nil {
                            trainingTime!.modifier(SecondaryLabelModifier())
                        }
                        else if error != nil {
                            Text(error!).modifier(SecondaryLabelModifier())
                        }
                    }
                }
            }
        }
    }
}

struct SkillsItem_Previews: PreviewProvider {
        static var previews: some View {
            NavigationView {
                List {
                    SkillsItem()
                }.listStyle(GroupedListStyle())
            }
            .environmentObject(SharedState.testState())
            .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
            .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.newBackgroundContext())

        }
    }
