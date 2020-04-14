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
    @Environment(\.account) private var account
    @Environment(\.esi) private var esi
    @ObservedObject private var skills = Lazy<DataLoader<[ESI.SkillQueueItem], AFError>>()
    
    let require: [ESI.Scope] = [.esiSkillsReadSkillqueueV1,
                                .esiSkillsReadSkillsV1,
                                .esiClonesReadImplantsV1]
    
    var body: some View {
        let result = account.map{self.skills.get(initial: DataLoader(esi.characters.characterID(Int($0.characterID)).skillqueue().get().map{$0.value}.receive(on: RunLoop.main)))}?.result
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
            if account?.verifyCredentials(require) == true {
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
            let account = AppDelegate.sharedDelegate.testingAccount
            let esi = account.map{ESI(token: $0.oAuth2Token!)} ?? ESI()

            return NavigationView {
                List {
                    SkillsItem()
                }.listStyle(GroupedListStyle())
            }
            .environment(\.account, account)
            .environment(\.esi, esi)
            .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
            .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.newBackgroundContext())

        }
    }
