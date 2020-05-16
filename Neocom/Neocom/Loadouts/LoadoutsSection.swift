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
    @Binding var selection: Set<NSManagedObjectID>
    var onSelect: (NSManagedObjectID, OpenMode) -> Void
    @Environment(\.editMode) var editMode
    
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    private func copy(_ loadoutID: NSManagedObjectID) {
        guard let loadout = try? managedObjectContext.existingObject(with: loadoutID) as? Loadout else {return}
        guard let ship = loadout.ship else {return}
        let encoder = LoadoutPlainTextEncoder(managedObjectContext: managedObjectContext)
        guard let data = try? encoder.encode(ship), let string = String(data: data, encoding: .utf8) else {return}
        UIPasteboard.general.string = string
    }

    private func delete(_ loadoutIDs: [NSManagedObjectID]) {
        loadoutIDs.map{managedObjectContext.object(with: $0)}.forEach {
            managedObjectContext.delete($0)
        }
        if self.managedObjectContext.hasChanges {
            try? self.managedObjectContext.save()
        }
    }
    
    func sectionHeader(_ section: LoadoutsLoader.Section) -> some View {
        let title = section.title.map{Text($0.uppercased())} ?? Text("UNKNOWN")
        return HStack {
            title
            if editMode?.wrappedValue == .active {
                Spacer()
                Button("SELECT ALL") {
                    withAnimation {
                        self.selection.formUnion(section.loadouts.map{$0.objectID})
                    }
                }
            }
        }
    }
    
    var body: some View {
        let sections = loadouts.loadouts ?? []
        
        return ForEach(sections) { section in
            
            Section(header: self.sectionHeader(section)) {
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
                            Button(action: {self.copy(loadout.objectID)}) {
                                Text("Copy")
                                Image(uiImage: UIImage(systemName: "doc.on.doc")!)
                            }
                            
                            Button(action: {self.delete([loadout.objectID])}) {
                                Text("Delete")
                                Image(uiImage: UIImage(systemName: "trash")!)
                            }

                    }

                }.onDelete { (indices) in
                    self.delete(indices.map{section.loadouts[$0].objectID})
                }
            }
        }
    }
}

struct LoadoutsSection_Previews: PreviewProvider {
    static var previews: some View {
        List {
            LoadoutsSection(loadouts: LoadoutsLoader(.ship, managedObjectContext: Storage.sharedStorage.persistentContainer.viewContext), selection: .constant(Set())) { _, _ in}
        }.listStyle(GroupedListStyle())
            .environment(\.managedObjectContext, Storage.sharedStorage.persistentContainer.viewContext)
    }
}
