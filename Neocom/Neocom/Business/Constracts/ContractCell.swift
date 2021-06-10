//
//  ContractCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/13/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import CoreData
import Expressible

struct ContractCell: View {
    var contract: ESI.PersonalContracts.Element
    var contacts: [Int64: Contact]
    var locations: [Int64: EVELocation]
    
    var body: some View {
        let endDate: Date = contract.dateCompleted ?? {
            guard let date = contract.dateAccepted, let duration = contract.daysToComplete else {return nil}
            return date.addingTimeInterval(TimeInterval(duration) * 24 * 3600)
            }() ?? contract.dateExpired
        let currentStatus = contract.currentStatus

        let isActive = currentStatus == .outstanding || currentStatus == .inProgress
        let t = contract.dateExpired.timeIntervalSinceNow
        
        let status: Text
        if isActive {
            status = Text("\(currentStatus.title):").fontWeight(.semibold).foregroundColor(.primary) + Text(" \(TimeIntervalFormatter.localizedString(from: max(t, 0), precision: .minutes))")
        }
        else {
            status = Text("\(currentStatus.title):").fontWeight(.semibold) + Text(" \(DateFormatter.localizedString(from: endDate, dateStyle: .medium, timeStyle: .medium))")
        }
        
        return VStack(alignment: .leading) {
            HStack {
                Text(contract.type.title).foregroundColor(.accentColor)
                Text("[\(contract.availability.title)]").modifier(SecondaryLabelModifier())
            }
            Group {
                contract.title.map{Text($0)}
                status
                contract.startLocationID.map { locationID in
                    Text(locations[locationID] ?? .unknown(locationID)).modifier(SecondaryLabelModifier())
                }
                
//                contacts[Int64(contract.issuerID)].map { issuer in
//                    Text("Issued: ").fontWeight(.semibold).foregroundColor(.primary) +
//                        Text(issuer.name ?? "")
//                }
            }.modifier(SecondaryLabelModifier())
        }.accentColor(isActive ? .primary : .secondary)
        
    }
}

struct ContractCell_Previews: PreviewProvider {
    static var previews: some View {
        let contact = Contact(entity: NSEntityDescription.entity(forEntityName: "Contact", in: Storage.testStorage.persistentContainer.viewContext)!, insertInto: nil)
        contact.name = "Artem Valiant"
        contact.contactID = 1554561480
        
        let solarSystem = try! Storage.testStorage.persistentContainer.viewContext.from(SDEMapSolarSystem.self).first()!
        let location = EVELocation(solarSystem: solarSystem, id: Int64(solarSystem.solarSystemID))

        
        let contract = ESI.PersonalContracts.Element(acceptorID: Int(contact.contactID),
                                                     assigneeID: Int(contact.contactID),
                                                     availability: .corporation,
                                                     buyout: 1e6,
                                                     collateral: 1e7,
                                                     contractID: 1,
                                                     dateAccepted: nil,
                                                     dateCompleted: nil,
                                                     dateExpired: Date(timeIntervalSinceNow: 3600 * 10),
                                                     dateIssued: Date(timeIntervalSinceNow: -3600 * 10),
                                                     daysToComplete: 16,
                                                     endLocationID: nil,
                                                     forCorporation: false,
                                                     issuerCorporationID: 0,
                                                     issuerID: Int(contact.contactID),
                                                     price: 1e4,
                                                     reward: 1e3,
                                                     startLocationID: location.id,
                                                     status: .outstanding,
                                                     title: "Contract Title",
                                                     type: .auction,
                                                     volume: 1e10)
        
        return NavigationView {
            List {
                ContractCell(contract: contract, contacts: [1554561480: contact], locations: [location.id: location])
            }.listStyle(GroupedListStyle())
        }
        
    }
}
