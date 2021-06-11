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
import Combine

struct JumpClones: View {
    @ObservedObject private var info = Lazy<DataLoader<JumpClonesInfo, AFError>, Account>()
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject private var sharedState: SharedState

    private struct JumpClonesInfo {
        var clones: ESI.Clones
        var locations: [Int64: EVELocation]
    }
    
    private func getInfo(characterID: Int64, cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy) -> AnyPublisher<JumpClonesInfo, AFError> {
        let clones = sharedState.esi.characters.characterID(Int(characterID)).clones().get(cachePolicy: cachePolicy)
            .flatMap { clones in
                EVELocation.locations(with: Set(clones.value.jumpClones.map{$0.locationID}), esi: self.sharedState.esi, managedObjectContext: self.managedObjectContext).setFailureType(to: AFError.self).map {
                    JumpClonesInfo(clones: clones.value, locations: $0)
                }
        }.receive(on: RunLoop.main)
        return clones.eraseToAnyPublisher()
    }

    private func nextCloneJump(_ clones: ESI.Clones) -> some View {
        let t = 3600 * 24 +  (clones.lastCloneJumpDate ?? .distantPast).timeIntervalSinceNow
        let subtitle = t > 0 ? Text(TimeIntervalFormatter.localizedString(from: t, precision: .minutes)) : Text("Now")
        
        return VStack(alignment: .leading) {
            Text("Clone jump availability: ") + subtitle
        }
    }
    
    var body: some View {
        
        let info = sharedState.account.map { account in
            self.info.get(account, initial: DataLoader(self.getInfo(characterID: account.characterID)))
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
                .onRefresh(isRefreshing: Binding(info!, keyPath: \.isLoading), onRefresh: {
                    guard let account = self.sharedState.account, let info = info else {return}
                    info.update(self.getInfo(characterID: account.characterID, cachePolicy: .reloadIgnoringLocalCacheData))
                })
                .listStyle(GroupedListStyle())
                .overlay((info?.result?.error).map{Text($0)})
            }
            else {
                Text(RuntimeError.noAccount).padding()
            }
        }.navigationBarTitle(Text("Jump Clones"))
    }
}

#if DEBUG
struct JumpClones_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            JumpClones()
        }
        .modifier(ServicesViewModifier.testModifier())
    }
}
#endif
