//
//  WealthMenuItem.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/27/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import Alamofire
import Combine

struct WealthMenuItem: View {
    @EnvironmentObject private var sharedState: SharedState
    @ObservedObject private var balance = Lazy<DataLoader<Double, AFError>, Account>()
    @State private var lastUpdateDate = Date()
    
    let require: [ESI.Scope] = [.esiClonesReadClonesV1,
                                .esiClonesReadImplantsV1]
    
    private func getPublisher(_ account: Account) -> AnyPublisher<Double, AFError> {
        sharedState.esi.characters.characterID(Int(account.characterID)).wallet().get().map{$0.value}.receive(on: RunLoop.main).eraseToAnyPublisher()
    }
    
    private func reload() {
        guard let account = self.sharedState.account else {return}
        guard lastUpdateDate.timeIntervalSinceNow < -30 else {return}
        let result = sharedState.account.map{self.balance.get($0, initial: DataLoader(getPublisher($0)))}
        result?.update(self.getPublisher(account))
        self.lastUpdateDate = Date()
    }

    
    var body: some View {
        let result = sharedState.account.map{self.balance.get($0, initial: DataLoader(getPublisher($0)))}
        let balance = result?.result?.value
        let error = result?.result?.error
        
        return Group {
            if sharedState.account?.verifyCredentials(require) == true {
                NavigationLink(destination: Wealth()) {
                    Icon(Image("folder"))
                    VStack(alignment: .leading) {
                        Text("Wealth")
                        if balance != nil {
                            Text(UnitFormatter.localizedString(from: balance!, unit: .isk, style: .long)).modifier(SecondaryLabelModifier())
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
struct WealthMenuItem_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                WealthMenuItem()
            }.listStyle(GroupedListStyle())
        }
        .environmentObject(SharedState.testState())
        .environment(\.managedObjectContext, Storage.sharedStorage.persistentContainer.viewContext)
    }
}
#endif
