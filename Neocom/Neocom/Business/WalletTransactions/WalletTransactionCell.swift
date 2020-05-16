//
//  WalletTransactionCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/12/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import Expressible
import CoreData

struct WalletTransactionCell: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    var item: ESI.WalletTransactions.Element
    var contacts: [Int64: Contact]
    var locations: [Int64: EVELocation]

    
    private func content(_ type: SDEInvType?) -> some View {
        
//        if item.isBuy
        
        var amount = Text(UnitFormatter.localizedString(from: item.unitPrice * Double(item.quantity), unit: .isk, style: .long))
        if item.isBuy {
            amount = (Text("-") + amount).foregroundColor(.red)
        }
        else {
            amount = amount.foregroundColor(.green)
        }
        
        if let client = contacts[Int64(item.clientID)]?.name {
            amount = amount + (item.isBuy ? Text(" to ", comment: "E.g.: 100 ISK to [PlayerName]") : Text("E.g.: 100 ISK from [PlayerName]")) + Text(client)
        }
        
        return VStack(alignment: .leading) {
            HStack {
                type.map{Icon($0.image).cornerRadius(4)}
                VStack(alignment: .leading) {
                    (type?.typeName).map {Text($0)} ?? Text("Unknown Type")
                    Text(locations[item.locationID] ?? .unknown(item.locationID)).modifier(SecondaryLabelModifier())
                }
            }
            Group {
                amount
                HStack {
                    Text("Price: ").fontWeight(.semibold).foregroundColor(.primary)
                        + Text(UnitFormatter.localizedString(from: item.unitPrice, unit: .isk, style: .long))
                    Text("Qty: ").fontWeight(.semibold).foregroundColor(.primary)
                        + Text(UnitFormatter.localizedString(from: item.quantity, unit: .none, style: .long))
                }
                Text(DateFormatter.localizedString(from: item.date, dateStyle: .none, timeStyle: .medium))
            }.modifier(SecondaryLabelModifier())
        }
    }

    var body: some View {
        let type = try? managedObjectContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == Int32(item.typeID)).first()
        return Group {
            if type != nil {
                NavigationLink(destination: TypeInfo(type: type!)) {
                    content(type)
                }
            }
            else {
                content(nil)
            }
        }
    }
}

struct WalletTransactionCell_Previews: PreviewProvider {
    static var previews: some View {
        let contact = Contact(entity: NSEntityDescription.entity(forEntityName: "Contact", in: Storage.sharedStorage.persistentContainer.viewContext)!, insertInto: nil)
        contact.name = "Artem Valiant"
        contact.contactID = 1554561480
        
        let solarSystem = try! Storage.sharedStorage.persistentContainer.viewContext.from(SDEMapSolarSystem.self).first()!
        let location = EVELocation(solarSystem: solarSystem, id: Int64(solarSystem.solarSystemID))

        
        let item = ESI.WalletTransactions.Element(clientID: Int(contact.contactID),
                                                  date: Date(timeIntervalSinceNow: -3600),
                                                  isBuy: true,
                                                  isPersonal: true,
                                                  journalRefID: 1,
                                                  locationID: location.id,
                                                  quantity: 2,
                                                  transactionID: 1,
                                                  typeID: 645,
                                                  unitPrice: 1000000)
        
        return NavigationView {
            List {
                WalletTransactionCell(item: item, contacts: [1554561480: contact], locations: [location.id: location])
            }.listStyle(GroupedListStyle())
                .environment(\.managedObjectContext, Storage.sharedStorage.persistentContainer.viewContext)
        }
    }
}
