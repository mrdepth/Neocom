//
//  Loadouts.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/6/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct Loadouts: View {
    enum Page {
        case ships
        case structures
        case fleets
        case ingame
    }
    
    @State private var page = Page.ships
    @EnvironmentObject private var sharedState: SharedState
    
    var picker: some View {
        Picker("Filter", selection: $page) {
            Text("Ships").tag(Page.ships)
            Text("Structures").tag(Page.structures)
            Text("Fleets").tag(Page.fleets)
            if self.sharedState.account != nil {
                Text("In-Game").tag(Page.ingame)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }
    
    var body: some View {
        VStack(spacing: 0) {
            picker.padding(.horizontal)
                .padding(.vertical, 8)
            if page == .ships {
                ShipLoadouts()
            }
            else if page == .structures {
                StructureLoadouts()
            }
            else if page == .fleets {
                Fleets()
            }
            else if page == .ingame {
                IngameLoadouts()
            }
        }
        .navigationBarTitle("Loadouts", displayMode: .inline)
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }
}

#if DEBUG
struct Loadouts_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            Loadouts()
        }
        .environment(\.managedObjectContext, Storage.sharedStorage.persistentContainer.viewContext)
        .environment(\.backgroundManagedObjectContext, Storage.sharedStorage.persistentContainer.newBackgroundContext())
        .environmentObject(SharedState.testState())
    }
}
#endif
