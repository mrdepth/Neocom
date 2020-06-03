//
//  JumpClonesItem.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/26/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import Alamofire
import Combine

struct JumpClonesItem: View {
    @EnvironmentObject private var sharedState: SharedState
    @ObservedObject private var clones = Lazy<DataLoader<ESI.Clones, AFError>, Account>()
    @State private var lastUpdateDate = Date()
    
    let require: [ESI.Scope] = [.esiClonesReadClonesV1,
                                .esiClonesReadImplantsV1]
    
    private func getPublisher(_ account: Account) -> AnyPublisher<ESI.Clones, AFError> {
        sharedState.esi.characters.characterID(Int(account.characterID)).clones().get().map{$0.value}.receive(on: RunLoop.main).eraseToAnyPublisher()
    }

    private func reload() {
        guard let account = self.sharedState.account else {return}
        guard lastUpdateDate.timeIntervalSinceNow < -30 else {return}
        let result = sharedState.account.map{self.clones.get($0, initial: DataLoader(getPublisher($0)))}
        result?.update(self.getPublisher(account))
        self.lastUpdateDate = Date()
    }

    var body: some View {
        let result = sharedState.account.map{self.clones.get($0, initial: DataLoader(getPublisher($0)))}
        let clones = result?.result?.value
        let error = result?.result?.error
        
        let cloneJump = clones.map { result -> Text in
            let t = 3600 * 24 + (result.lastCloneJumpDate ?? .distantPast).timeIntervalSinceNow
            let subtitle = t > 0 ? Text(TimeIntervalFormatter.localizedString(from: t, precision: .minutes)) : Text("Now")
            return Text("Clone jump availability: ") + subtitle
        }
        
        return Group {
            if sharedState.account?.verifyCredentials(require) == true {
                NavigationLink(destination: JumpClones()) {
                    Icon(Image("jumpclones"))
                    VStack(alignment: .leading) {
                        Text("Jump Clones")
                        if cloneJump != nil {
                            cloneJump?.modifier(SecondaryLabelModifier())
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
struct JumpClonesItem_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                JumpClonesItem()
            }.listStyle(GroupedListStyle())
        }
        .environmentObject(SharedState.testState())
        .environment(\.managedObjectContext, Storage.sharedStorage.persistentContainer.viewContext)
    }
}
#endif
