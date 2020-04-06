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

struct JumpClonesItem: View {
    @Environment(\.account) private var account
    @Environment(\.esi) private var esi
    @ObservedObject private var skills = Lazy<DataLoader<ESI.Clones, AFError>>()
    
    let require: [ESI.Scope] = [.esiClonesReadClonesV1,
                                .esiClonesReadImplantsV1]
    
    var body: some View {
        let result = account.map{self.skills.get(initial: DataLoader(esi.characters.characterID(Int($0.characterID)).clones().get().map{$0.value}.receive(on: RunLoop.main)))}?.result
        let clones = result?.value
        let error = result?.error
        
        let cloneJump = clones.map { result -> Text in
            let t = 3600 * 24 + (result.lastCloneJumpDate ?? .distantPast).timeIntervalSinceNow
            let subtitle = t > 0 ? Text(TimeIntervalFormatter.localizedString(from: t, precision: .minutes)) : Text("Now")
            return Text("Clone jump availability: ") + subtitle
        }
        
        return Group {
            if account?.verifyCredentials(require) == true {
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
    }
}

struct JumpClonesItem_Previews: PreviewProvider {
    static var previews: some View {
        let account = AppDelegate.sharedDelegate.testingAccount
        let esi = account.map{ESI(token: $0.oAuth2Token!)} ?? ESI()

        return NavigationView {
            List {
                JumpClonesItem()
            }.listStyle(GroupedListStyle())
        }
        .environment(\.account, account)
        .environment(\.esi, esi)
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
