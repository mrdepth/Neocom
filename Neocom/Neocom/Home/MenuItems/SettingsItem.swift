//
//  SettingsItem.swift
//  Neocom
//
//  Created by Artem Shimanski on 5/8/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct SettingsItem: View {
    var body: some View {
        NavigationLink(destination: Settings()) {
            Icon(Image("settings"))
            Text("Settings")
        }
    }
}

struct SettingsItem_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                SettingsItem()
            }.listStyle(GroupedListStyle())
        }
    }
}
