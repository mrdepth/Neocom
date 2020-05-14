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
    @EnvironmentObject private var sharedState: SharedState
    @ObservedObject private var pilot = Lazy<DataLoader<Pilot, AFError>, Account>()
    
    private func getPilot(_ characterID: Int64) -> DataLoader<Pilot, AFError> {
        DataLoader(Pilot.load(sharedState.esi.characters.characterID(Int(characterID)), in: backgroundManagedObjectContext).receive(on: RunLoop.main))
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
        let pilot = sharedState.account.map{self.pilot.get($0, initial: getPilot($0.characterID))}?.result?.value
        
        return List(self.certificates, id: \.objectID) { certificate in
            CertificateCell(certificate: certificate, pilot: pilot)
        }.listStyle(GroupedListStyle())
            .navigationBarTitle(group.groupName ?? "\(group.groupID)")
    }
}

#if DEBUG
struct Certificates_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            Certificates(group: try! AppDelegate.sharedDelegate.persistentContainer.viewContext
                .from(SDEInvGroup.self)
                .filter((/\SDEInvGroup.certificates).count > 0)
                .first()!
            )}
        .environmentObject(SharedState.testState())
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext.newBackgroundContext())
    }
}
#endif
