//
//  Assets.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/5/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import Expressible

struct Assets: View {
    @Environment(\.backgroundManagedObjectContext) private var backgroundManagedObjectContext
    @Environment(\.esi) private var esi
    @Environment(\.account) private var account
    @ObservedObject var assets = Lazy<AssetsData>()
    
    var body: some View {
        let assets = account.map{self.assets.get(initial: AssetsData(esi: esi, characterID: $0.characterID, managedObjectContext: backgroundManagedObjectContext))}
        return List {
            if assets?.locations?.value != nil {
                ForEach(assets!.locations!.value!, id: \.location.id) { i in
                    NavigationLink(destination: AssetsList(assets: i.assets)) {
                        VStack(alignment: .leading) {
                            Text(i.location)
                            Text("\(UnitFormatter.localizedString(from: i.count, unit: .none, style: .long)) assets").modifier(SecondaryLabelModifier())
                        }
                    }
                }
            }
        }.listStyle(GroupedListStyle())
    }
}



struct Assets_Previews: PreviewProvider {
    static var previews: some View {
        let account = AppDelegate.sharedDelegate.testingAccount
        let esi = account.map{ESI(token: $0.oAuth2Token!)} ?? ESI()
        return NavigationView {
            Assets()
        }
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.newBackgroundContext())
        .environment(\.account, account)
        .environment(\.esi, esi)

    }
}
