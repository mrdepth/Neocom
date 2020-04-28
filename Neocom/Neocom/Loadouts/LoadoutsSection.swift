//
//  LoadoutsSection.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/26/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp
import Combine
import CoreData

struct LoadoutsSection: View {
    @ObservedObject var loadouts: LoadoutsLoader
    var onSelect: (NSManagedObjectID, OpenMode) -> Void
    
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    var body: some View {
        let sections = loadouts.loadouts ?? []
        
        return ForEach(sections) { section in
            Section(header: section.title.map{Text($0.uppercased())} ?? Text("UNKNOWN")) {
                ForEach(section.loadouts) { loadout in
                    Button(action: {self.onSelect(loadout.objectID, .default)}) {
                        HStack {
                            LoadoutCell(typeID: Int(loadout.typeID), name: loadout.name)
                            Spacer()
                        }.contentShape(Rectangle())
                    }.buttonStyle(PlainButtonStyle())//.id(loadout.objectID)
                        .contextMenu {
                            if UIApplication.shared.supportsMultipleScenes {
                                Button("Open in New Window") {
                                    self.onSelect(loadout.objectID, .newWindow)
                                }
                                Button("Open in Current Window") {
                                    self.onSelect(loadout.objectID, .currentWindow)
                                }
                            }
                    }

                }.onDelete { (indices) in
                    indices.map{self.managedObjectContext.object(with: section.loadouts[$0].objectID)}.forEach {self.managedObjectContext.delete($0)}
                    if self.managedObjectContext.hasChanges {
                        try? self.managedObjectContext.save()
                    }
                }
            }
        }
    }
}

struct LoadoutsSection_Previews: PreviewProvider {
    static var previews: some View {
        List {
            LoadoutsSection(loadouts: LoadoutsLoader(.ship, managedObjectContext: AppDelegate.sharedDelegate.persistentContainer.viewContext)) { _, _ in}
        }.listStyle(GroupedListStyle())
            .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
