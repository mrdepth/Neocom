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
    @Environment(\.account) private var account
    @Environment(\.esi) private var esi
    @ObservedObject private var skills = Lazy<DataLoader<Double, AFError>>()
    
    let require: [ESI.Scope] = [.esiClonesReadClonesV1,
                                .esiClonesReadImplantsV1]
    
    var body: some View {
        let result = account.map{self.skills.get(initial: DataLoader(esi.characters.characterID(Int($0.characterID)).wallet().get().map{$0.value}.receive(on: RunLoop.main)))}?.result
        let balance = result?.value
        let error = result?.error
        
        return Group {
            if account?.verifyCredentials(require) == true {
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

struct WealthMenuItem_Previews: PreviewProvider {
    static var previews: some View {
        let account = AppDelegate.sharedDelegate.testingAccount
        let esi = account.map{ESI(token: $0.oAuth2Token!)} ?? ESI()
        
        return NavigationView {
            List {
                WealthMenuItem()
            }.listStyle(GroupedListStyle())
        }
        .environment(\.account, account)
        .environment(\.esi, esi)
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
