//
//  JumpClones.swift
//  Neocom
//
//  Created by Artem Shimanski on 1/21/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import Alamofire

struct JumpClones: View {
    @ObservedObject private var info = Lazy<DataLoader<JumpClonesInfo, AFError>>()
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.esi) var esi
    @Environment(\.account) var account
    
    private struct JumpClonesInfo {
        var clones: ESI.Clones
        var locations: [Int64: EVELocation]
    }
    
    private func info(characterID: Int64) -> DataLoader<JumpClonesInfo, AFError> {
        let clones = esi.characters.characterID(Int(characterID)).clones().get()
            .flatMap { clones in
                EVELocation.locations(with: Set(clones.jumpClones.map{$0.locationID}), esi: self.esi, managedObjectContext: self.managedObjectContext).setFailureType(to: AFError.self).map {
                    JumpClonesInfo(clones: clones, locations: $0)
                }
        }.receive(on: RunLoop.main)
        return DataLoader(clones)
    }

    private func nextCloneJump(_ clones: ESI.Clones) -> some View {
        let t = 3600 * 24 +  (clones.lastCloneJumpDate ?? .distantPast).timeIntervalSinceNow
        let subtitle = t > 0 ? Text(TimeIntervalFormatter.localizedString(from: t, precision: .minutes)) : Text("Now")
        
        return VStack(alignment: .leading) {
            Text("Next Clone Jump Availability")
            (Text("Clone jump availability: ") + subtitle).modifier(SecondaryLabelModifier())
        }
    }
    
    var body: some View {
        
        let info = account.map { account in
            self.info.get(initial: self.info(characterID: account.characterID))
        }
        
        return Group {
            if info != nil {
                List {
                    (info?.result?.value).map { info in
                        Group {
                            Section {
                                self.nextCloneJump(info.clones)
                            }
                            ForEach(info.clones.jumpClones, id: \.jumpCloneID) { clone in
                                Section(header: info.locations[clone.locationID].map{Text($0)} ?? Text("UNKNOWN LOCATION")) {
                                    ImplantsRows(implants: clone.implants)
                                }
                            }
                        }
                    }
                }
                .listStyle(GroupedListStyle())
                .overlay((info?.result?.error).map{Text($0)})
            }
            else {
                Text(RuntimeError.noAccount).padding()
            }
        }.navigationBarTitle("Jump Clones")
    }
}

struct JumpClones_Previews: PreviewProvider {
    static var previews: some View {
        let account = AppDelegate.sharedDelegate.testingAccount
        let esi = account.map{ESI(token: $0.oAuth2Token!)} ?? ESI()

        return NavigationView {
            JumpClones()
        }
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environment(\.account, account)
        .environment(\.esi, esi)
    }
}
