//
//  ContractBidCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/14/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import Alamofire
import CoreData

struct ContractBidCell: View {
    var bid: ESI.ContractBids.Element
    var contact: Contact?
    
    var body: some View {
        HStack {
            Avatar(characterID: Int64(bid.bidderID), size: .size128).frame(width: 40, height: 40)
            VStack(alignment: .leading) {
                (contact?.name).map{Text($0)}
                HStack {
                    Text(UnitFormatter.localizedString(from: bid.amount, unit: .isk, style: .long))
                    Spacer()
                    Text(DateFormatter.localizedString(from: bid.dateBid, dateStyle: .medium, timeStyle: .medium))
                }.modifier(SecondaryLabelModifier())
            }
        }
    }
}

#if DEBUG
struct ContractBidCell_Previews: PreviewProvider {
    static var previews: some View {
        let contact = Contact(entity: NSEntityDescription.entity(forEntityName: "Contact", in: Storage.testStorage.persistentContainer.viewContext)!, insertInto: nil)
        contact.name = "Artem Valiant"
        contact.contactID = 1554561480

        let bid = ESI.ContractBids.Element(amount: 1000, bidID: 1, bidderID: Int(contact.contactID), dateBid: Date(timeIntervalSinceNow: -3600 * 10))

        
        return List {
            ContractBidCell(bid: bid, contact: contact)
        }.listStyle(GroupedListStyle())
        .modifier(ServicesViewModifier.testModifier())
    }
}
#endif
