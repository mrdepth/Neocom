//
//  Settings.swift
//  Neocom
//
//  Created by Artem Shimanski on 5/8/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct Settings: View {
    var body: some View {
        List {
            Section(footer: Text("Data will be restored from iCloud.")) {
                NavigationLink("Migrate legacy data", destination: Migration())
            }
        }.listStyle(GroupedListStyle())
        .navigationBarTitle("Settings")
    }
}

struct Settings_Previews: PreviewProvider {
    static var previews: some View {
        Settings()
    }
}
