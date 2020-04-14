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
    var onSelect: (Result) -> Void
    
    @Environment(\.account) private var account
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.backgroundManagedObjectContext) private var backgroundManagedObjectContext
    @Environment(\.self) private var environment
    @Environment(\.typePicker) private var typePicker
    @State private var selectedGroup: SDEDgmppItemGroup?
    
    private func typePicker(_ group: SDEDgmppItemGroup) -> some View {
        typePicker.get(group, environment: environment) {
            defer {self.selectedGroup = nil}
            guard let type = $0 else {return}
            self.onSelect(.type(type))
        }
    }
    
    @State private var selectedLoadouts: Set<NSManagedObjectID> = Set()
    
    private func onShare() {
        
    }
    
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

    var body: some View {
        VStack(spacing: 0) {
            List(selection: $selectedLoadouts.animation()) {
                Section {
                    Button(action: {self.selectedGroup = try? self.managedObjectContext.fetch(SDEDgmppItemGroup.rootGroup(categoryID: self.category, subcategory: nil, race: nil)).first}) {
                        HStack {
                            Icon(Image("fitting"))
                            Text("New Loadout")
                            Spacer()
                        }.contentShape(Rectangle())
                    }.buttonStyle(PlainButtonStyle())
                }
                LoadoutsSection(loadouts: loadouts) { self.onSelect(.loadout($0)) }
            }.listStyle(GroupedListStyle())
            if !selectedLoadouts.isEmpty {
                Divider()
                HStack {
                    Button("Share") {}
                    Spacer()
                    Button("Delete", action: onDelete).accentColor(Color.red)
                }.padding().transition(.offset(x: 0, y: 100))
                    .background(Color(.systemBackground).edgesIgnoringSafeArea(.all))
            }
        }
        .sheet(item: $selectedGroup) { group in
            self.typePicker(group)
        }
        .navigationBarItems(trailing: EditButton())

    }
}

struct LoadoutsList_Previews: PreviewProvider {
    static var previews: some View {
        _ = Loadout.testLoadouts()
        return NavigationView {
            LoadoutsList(loadouts: LoadoutsLoader(.ship, managedObjectContext: AppDelegate.sharedDelegate.persistentContainer.viewContext), category: .ship) { _ in}
        }
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.newBackgroundContext())
    }
}
