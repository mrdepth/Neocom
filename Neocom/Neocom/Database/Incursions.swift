//
//  Incursions.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/30/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import Alamofire

struct Incursions: View {
    @EnvironmentObject private var sharedState: SharedState
    @ObservedObject private var incursions = Lazy<DataLoader<[ESI.Incursion], AFError>, Never>()

    var body: some View {
        let result = self.incursions.get(initial: DataLoader(sharedState.esi.incursions.get().map{$0.value}.receive(on: RunLoop.main)))
        
        let incursions = result.result?.value

        return List {
            if incursions != nil {
                ForEach(incursions!, id: \.stagingSolarSystemID) { incursion in
                    NavigationLink(destination: IncursionSolarSystems(incursion: incursion)) {
                        IncursionCell(incursion: incursion)
                    }
                }
            }
        }.listStyle(GroupedListStyle())
            .overlay((result.result?.error).map{Text($0)})
            .overlay(incursions?.isEmpty == true ? Text(RuntimeError.noResult).padding() : nil)
            .navigationBarTitle(Text("Incursions"))
    }
}

#if DEBUG
struct Incursions_Previews: PreviewProvider {
    static var previews: some View {
        let account = AppDelegate.sharedDelegate.testingAccount
        let esi = account.map{ESI(token: $0.oAuth2Token!)} ?? ESI()
        
        return NavigationView {
            Incursions()
        }
        .environment(\.managedObjectContext, Storage.sharedStorage.persistentContainer.viewContext)
        .environmentObject(SharedState.testState())
    }
}
#endif
