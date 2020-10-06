//
//  CertificateGroups.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/24/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible

struct CertificateGroups: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    
    private func groups() -> FetchedResultsController<SDEInvGroup> {
        let controller = managedObjectContext
            .from(SDEInvGroup.self)
            .filter((/\SDEInvGroup.certificates).count > 0)
            .sort(by: \SDEInvGroup.groupName, ascending: true)
            .fetchedResultsController()
        return FetchedResultsController(controller)
    }
    
    var body: some View {
        ObservedObjectView(self.groups()) { groups in
            List {
                ForEach(groups.fetchedObjects, id: \.objectID) { group in
                    NavigationLink(destination: Certificates(group: group)) {
                        GroupCell(group: group)
                    }
                }

            }.listStyle(GroupedListStyle())
        }.navigationBarTitle(NSLocalizedString("Certificates", comment: ""))
    }}

struct CertificateGroups_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CertificateGroups()
        }.modifier(ServicesViewModifier.testModifier())
    }
}
