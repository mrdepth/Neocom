//
//  Types.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/27/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible
import CoreData

struct Types: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    
    enum Source {
        case predicate(PredicateProtocol, String)
        case group(SDEInvGroup)
        case marketGroup(SDEInvMarketGroup)
		case npc(SDENpcGroup)
    }
    
    private let predicate: PredicateProtocol
    private let title: String
    
    init(_ source: Source) {
        switch source {
        case let .predicate(predicate, title):
            self.predicate = predicate
            self.title = title
        case let .group(group):
            predicate = /\SDEInvType.group == group
            title = group.groupName ?? "\(group.groupID)"
        case let .marketGroup(group):
            predicate = /\SDEInvType.marketGroup == group
            title = group.marketGroupName ?? "\(group.marketGroupID)"
		case let .npc(group):
			predicate = /\SDEInvType.group == group.group
			title = group.npcGroupName ?? ""
        }
    }
    
    static func fetchResults(with predicate: PredicateProtocol, managedObjectContext: NSManagedObjectContext) -> FetchedResultsController<SDEInvType> {
        let controller = managedObjectContext.from(SDEInvType.self)
            .filter(predicate)
            .sort(by: \SDEInvType.metaGroup?.metaGroupID, ascending: true)
            .sort(by: \SDEInvType.metaLevel, ascending: true)
            .sort(by: \SDEInvType.typeName, ascending: true)
            .fetchedResultsController(sectionName: /\SDEInvType.metaGroup?.metaGroupID)
        return FetchedResultsController(controller)
    }
    
    private func getTypes() -> FetchedResultsController<SDEInvType> {
        Types.fetchResults(with: predicate, managedObjectContext: managedObjectContext)
    }
    
    @StateObject private var types = Lazy<FetchedResultsController<SDEInvType>, Never>()
    
    private func cell(for type: SDEInvType) -> some View {
        NavigationLink(destination: TypeInfo(type: type)) {
            TypeCell(type: type)
        }
    }

    var body: some View {
        let types = self.types.get(initial: getTypes())
        
        return List {
            TypesContent(types: types.sections) { type in
                cell(for: type)
            }
        }
        .listStyle(GroupedListStyle())
        .search { publisher in
            TypesSearchResults(publisher: publisher, predicate: predicate) { type in
                cell(for: type)
            }
        }
        .navigationBarTitle(title)
    }
}

struct TypesContent<Cell: View>: View {
    var types: [FetchedResultsController<SDEInvType>.Section]
    var cell: (SDEInvType) -> Cell
    
    var body: some View {
        ForEach(types, id: \.name) { section in
            Section(header: Text(section.objects.first?.metaGroup?.metaGroupName?.uppercased() ?? "")) {
                ForEach(section.objects, id: \.objectID) { type in
                    self.cell(type)
                }
            }
        }
    }
}

struct Types_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            Types(.group((try? Storage.testStorage.persistentContainer.viewContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == 645).first()?.group)!))
        }.modifier(ServicesViewModifier.testModifier())
    }
}
