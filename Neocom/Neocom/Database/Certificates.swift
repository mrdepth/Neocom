//
//  Certificates.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/24/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible
import Combine
import Alamofire
import CoreData

struct Certificates: View {
    var group: SDEInvGroup
    
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.backgroundManagedObjectContext) var backgroundManagedObjectContext
    @Environment(\.esi) var esi
    @Environment(\.account) var account
    
    private func pilot() -> DataLoader<Pilot?, AFError> {
        if let characterID = account?.characterID {
            return DataLoader(Pilot.load(esi.characters.characterID(Int(characterID)), in: backgroundManagedObjectContext).map{$0 as Optional}.receive(on: RunLoop.main))
        }
        else {
            return DataLoader(Just(nil).setFailureType(to: AFError.self).receive(on: RunLoop.main))
        }
    }
    
    @FetchRequest var certificates: FetchedResults<SDECertCertificate>
    
    init(group: SDEInvGroup) {
        self.group = group
        let request = NSFetchRequest<SDECertCertificate>()
        request.entity = SDECertCertificate.entity()
        request.predicate = (/\SDECertCertificate.group == group).predicate()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SDECertCertificate.certificateName, ascending: true)]
        _certificates = FetchRequest(fetchRequest: request)
    }
    
    var body: some View {
        ObservedObjectView(pilot()) { pilot in
            List(self.certificates, id: \.objectID) { certificate in
                CertificateCell(certificate: certificate, pilot: pilot.result?.value ?? nil)
            }.listStyle(GroupedListStyle())
        }.navigationBarTitle(group.groupName ?? "\(group.groupID)")
    }
}

struct Certificates_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            Certificates(group: try! AppDelegate.sharedDelegate.persistentContainer.viewContext
                .from(SDEInvGroup.self)
                .filter((/\SDEInvGroup.certificates).count > 0)
                .first()!
            )}
            .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
            .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext.newBackgroundContext())
    }
}
