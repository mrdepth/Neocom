//
//  CertificateRequirementsInfo.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/24/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible

struct CertificateRequirementsInfo: View {
    var types: FetchedResultsController<SDEInvType>
    @Environment(\.managedObjectContext) var managedObjectContext

    
    var body: some View {
        ForEach(types.sections, id: \.name) { section in
            Section(header: Text(section.name.uppercased())) {
                ForEach(section.objects, id: \.objectID) { type in
                    NavigationLink(destination: TypeInfo(type: type)) {
                        TypeCell(type: type)
                    }
                }
            }
        }
    }
}

struct CertificateRequirementsInfo_Previews: PreviewProvider {
    static var previews: some View {
        let certificate = try! AppDelegate.sharedDelegate.persistentContainer.viewContext
            .from(SDECertCertificate.self)
            .filter(Expressions.keyPath(\SDECertCertificate.certificateName).contains("Armor"))
            .first()!

        func types() -> FetchedResultsController<SDEInvType> {
            let controller = AppDelegate.sharedDelegate.persistentContainer.viewContext.from(SDEInvType.self)
                .filter(Expressions.keyPath(\SDEInvType.published) == true && Expressions.keyPath(\SDEInvType.certificates).contains(certificate))
                .sort(by: \SDEInvType.group?.groupName, ascending: true)
                .fetchedResultsController(sectionName: Expressions.keyPath(\SDEInvType.group?.groupName), cacheName: nil)
            return FetchedResultsController(controller)
        }
        
        return List {
            CertificateRequirementsInfo(types: types())
            .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        }.listStyle(GroupedListStyle())
    }
}
