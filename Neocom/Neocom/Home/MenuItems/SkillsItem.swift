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
import Combine

struct SkillsItem: View {
    @EnvironmentObject private var sharedState: SharedState
    @ObservedObject private var skills = Lazy<DataLoader<[ESI.SkillQueueItem], AFError>, Account>()
    @State private var lastUpdateDate = Date()
    
    let require: [ESI.Scope] = [.esiSkillsReadSkillqueueV1,
                                .esiSkillsReadSkillsV1,
                                .esiClonesReadImplantsV1]
    
    private func getPublisher(_ account: Account) -> AnyPublisher<[ESI.SkillQueueItem], AFError> {
        sharedState.esi.characters.characterID(Int(account.characterID)).skillqueue().get().map{$0.value}.receive(on: RunLoop.main).eraseToAnyPublisher()
    }
    
    private func reload() {
        guard let account = self.sharedState.account else {return}
        guard lastUpdateDate.timeIntervalSinceNow < -30 else {return}
        let result = sharedState.account.map{self.skills.get($0, initial: DataLoader(getPublisher($0)))}
        result?.update(self.getPublisher(account))
        self.lastUpdateDate = Date()
    }
    
    var body: some View {
        let result = sharedState.account.map{self.skills.get($0, initial: DataLoader(getPublisher($0)))}
        let skillQueue = result?.result?.value
        let error = result?.result?.error
        
        
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
        .onReceive(Timer.publish(every: 60 * 30, on: .main, in: .default).autoconnect()) { _ in
            self.reload()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIScene.didActivateNotification)) { _ in
            self.reload()
        }
    }
}

#if DEBUG
struct SkillsItem_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                SkillsItem()
            }.listStyle(GroupedListStyle())
        }
        .environmentObject(SharedState.testState())
        .environment(\.managedObjectContext, Storage.sharedStorage.persistentContainer.viewContext)
        .environment(\.backgroundManagedObjectContext, Storage.sharedStorage.persistentContainer.newBackgroundContext())
        
    }
}
#endif
