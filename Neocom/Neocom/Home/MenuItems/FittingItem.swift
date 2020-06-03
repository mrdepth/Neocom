//
//  FittingItem.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/11/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct FittingItem: View {
    @ObservedObject private var storage = Storage.sharedStorage
    
    var body: some View {
        NavigationLink(destination: Loadouts()) {
            Icon(Image("fitting"))
            Text("Fitting Editor")
        }.id(storage.currentLanguagID)
    }
}

struct FittingItem_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                FittingItem()
            }.listStyle(GroupedListStyle())
        }
    }
}
