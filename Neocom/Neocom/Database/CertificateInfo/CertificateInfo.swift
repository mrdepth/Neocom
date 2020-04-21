//
//  CertificateInfo.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/24/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible

struct CertificateInfo: View {
    var certificate: SDECertCertificate
    var masteryLevel: Int?
    var pilot: Pilot?
    
    @State private var mode: Mode = .info
    
    @Environment(\.managedObjectContext) var managedObjectContext

    private func types() -> FetchedResultsController<SDEInvType> {
        let controller = managedObjectContext.from(SDEInvType.self)
            .filter(/\SDEInvType.published == true && (/\SDEInvType.certificates).contains(certificate))
            .sort(by: \SDEInvType.group?.groupName, ascending: true)
            .fetchedResultsController(sectionName: (/\SDEInvType.group?.groupName), cacheName: nil)
        return FetchedResultsController(controller)
    }
    
    @State private var requirements = Lazy<FetchedResultsController<SDEInvType>, Never>()

    enum Mode {
        case info
        case requirements
    }
    
    var body: some View {
        List {
            Section(header:
                Picker("Filter", selection: $mode) {
                    Text("Info").tag(Mode.info)
                    Text("Requirements").tag(Mode.requirements)
                }.pickerStyle(SegmentedPickerStyle())) {EmptyView()}
            if mode == .info {
                CertificateMasteryInfo(certificate: certificate, masteryLevel: masteryLevel, pilot: nil)
            }
            else {
                CertificateRequirementsInfo(types: requirements.get(initial: types()))
            }
        }.listStyle(GroupedListStyle())
    }
}



struct CertificateInfo_Previews: PreviewProvider {
    static var previews: some View {
        let certificate = try! AppDelegate.sharedDelegate.persistentContainer.viewContext
        .from(SDECertCertificate.self)
        .filter((/\SDECertCertificate.certificateName).contains("Armor"))
        .first()!

        
        return NavigationView {
            CertificateInfo(certificate: certificate)
        }.environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
