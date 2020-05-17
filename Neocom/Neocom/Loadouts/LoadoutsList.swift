//
//  LoadoutsList.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/26/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp
import Combine
import CoreData

struct LoadoutsList: View {
    enum Result {
        case type(SDEInvType)
        case loadout(NSManagedObjectID)
    }
    @ObservedObject var loadouts: LoadoutsLoader
    var category: SDEDgmppItemCategoryID
    var onSelect: (Result, OpenMode) -> Void
    
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.backgroundManagedObjectContext) private var backgroundManagedObjectContext
    @Environment(\.self) private var environment
    @Environment(\.typePicker) private var typePicker
    @Environment(\.editMode) private var editMode
    @State private var isTypePickerPresented = false
    @EnvironmentObject private var sharedState: SharedState
    
    private func typePicker(_ group: SDEDgmppItemGroup) -> some View {
        typePicker.get(group, environment: environment, sharedState: sharedState) {
            defer {self.isTypePickerPresented = false}
            guard let type = $0 else {return}
            self.onSelect(.type(type), .default)
        }
    }
    
    @State private var selectedLoadouts: Set<NSManagedObjectID> = Set()
    @State private var isActivityPresented = false
    
    private func onDelete() {
        for objectID in selectedLoadouts {
            managedObjectContext.delete(managedObjectContext.object(with: objectID))
        }
        if managedObjectContext.hasChanges {
            try? managedObjectContext.save()
        }
        withAnimation {
            selectedLoadouts.removeAll()
        }
    }

    var group: SDEDgmppItemGroup? {
        try? self.managedObjectContext.fetch(SDEDgmppItemGroup.rootGroup(categoryID: self.category, subcategory: nil, race: nil)).first
    }

    var body: some View {
        VStack(spacing: 0) {
            List(selection: $selectedLoadouts.animation()) {
                Section {
                    Button(action: {self.isTypePickerPresented = true}) {
                        HStack {
                            Icon(Image("fitting"))
                            Text("New Loadout")
                            Spacer()
                        }.contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .adaptivePopover(isPresented: $isTypePickerPresented, arrowEdge: .leading) {
                        self.group.map{self.typePicker($0)}
                    }

                }
                LoadoutsSection(loadouts: loadouts, selection: $selectedLoadouts) { self.onSelect(.loadout($0), $1) }
            }.listStyle(GroupedListStyle())
            if !selectedLoadouts.isEmpty && editMode?.wrappedValue == .active {
                Divider()
                HStack {
                    Button(NSLocalizedString("Deselect All", comment: "")) { withAnimation {self.selectedLoadouts.removeAll()}}.frame(maxWidth: .infinity, alignment: .leading)
                    Button(NSLocalizedString("Share", comment: "")) { self.isActivityPresented = true }.frame(maxWidth: .infinity)
                    .activityView(isPresented: $isActivityPresented,
                                  activityItems: [LoadoutActivityItem(ships: selectedLoadouts.compactMap{managedObjectContext.object(with: $0) as? Loadout}.compactMap{$0.ship}, managedObjectContext: managedObjectContext)],
                                  applicationActivities: [InGameActivity(environment: environment, sharedState: sharedState)])

                    Button("Delete", action: onDelete).accentColor(Color.red).frame(maxWidth: .infinity, alignment: .trailing)
                }.padding().transition(.offset(x: 0, y: 100))
                    .background(Color(.systemBackground).edgesIgnoringSafeArea(.all))
            }
        }
        .navigationBarItems(trailing: EditButton())

    }
}

#if DEBUG
struct LoadoutsList_Previews: PreviewProvider {
    static var previews: some View {
        _ = Loadout.testLoadouts()
        return NavigationView {
            LoadoutsList(loadouts: LoadoutsLoader(.ship, managedObjectContext: Storage.sharedStorage.persistentContainer.viewContext), category: .ship) { _, _ in}
        }
        .environment(\.managedObjectContext, Storage.sharedStorage.persistentContainer.viewContext)
        .environment(\.backgroundManagedObjectContext, Storage.sharedStorage.persistentContainer.newBackgroundContext())
        .environmentObject(SharedState.testState())
    }
}
#endif
