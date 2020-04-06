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
    @Environment(\.esi) private var esi
    @ObservedObject private var incursions = Lazy<DataLoader<[ESI.Incursion], AFError>>()

    var body: some View {
        let result = self.incursions.get(initial: DataLoader(esi.incursions.get().map{$0.value}.receive(on: RunLoop.main)))
        
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

struct Incursions_Previews: PreviewProvider {
    static var previews: some View {
        let account = AppDelegate.sharedDelegate.testingAccount
        let esi = account.map{ESI(token: $0.oAuth2Token!)} ?? ESI()
        
        return NavigationView {
            Incursions()
        }
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environment(\.account, account)
        .environment(\.esi, esi)
    }
}
