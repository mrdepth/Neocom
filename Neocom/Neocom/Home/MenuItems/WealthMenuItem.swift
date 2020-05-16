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

struct WealthMenuItem: View {
    @EnvironmentObject private var sharedState: SharedState
    @ObservedObject private var skills = Lazy<DataLoader<Double, AFError>, Account>()
    
    let require: [ESI.Scope] = [.esiClonesReadClonesV1,
                                .esiClonesReadImplantsV1]
    
    var body: some View {
        let result = sharedState.account.map{self.skills.get($0, initial: DataLoader(sharedState.esi.characters.characterID(Int($0.characterID)).wallet().get().map{$0.value}.receive(on: RunLoop.main)))}?.result
        let balance = result?.value
        let error = result?.error
        
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
