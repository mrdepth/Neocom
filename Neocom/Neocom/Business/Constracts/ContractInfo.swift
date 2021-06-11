//
//  ContractInfo.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/14/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import Expressible
import CoreData

struct ContractInfo: View {
    var contract: ESI.PersonalContracts.Element
    @ObservedObject private var contractInfo: Lazy<ContractInfoData, Account> = Lazy()
    @Environment(\.managedObjectContext) private var managedObjectContext
    @EnvironmentObject private var sharedState: SharedState

    var body: some View {
        let result = sharedState.account.map { account in
            self.contractInfo.get(account, initial: ContractInfoData(esi: sharedState.esi, characterID: account.characterID, contract: contract, managedObjectContext: managedObjectContext))
        }

        let list = List {
            ContractInfoBasic(contract: contract, locations: result?.locations ?? [:])
            (result?.items?.value).map{ContractInfoItems(items: $0)}
            (result?.bids?.value).flatMap { bids in
                (result?.contacts).map { contacts in
                    ContractInfoBids(bids: bids, contacts: contacts)
                }
            }
        }.listStyle(GroupedListStyle())
        
        return Group {
            if result != nil {
                list.onRefresh(isRefreshing: Binding(result!, keyPath: \.isLoading)) {
                    result?.update(cachePolicy: .reloadIgnoringLocalCacheData)
                }
            }
            else {
                list
            }
        }
        .navigationBarTitle(contract.type.title)


    }
}

struct ContractInfoBasic: View {
    var contract: ESI.PersonalContracts.Element
    var locations: [Int64: EVELocation]
    
    private func cell(title: Text, subtitle: String?) -> some View {
        Group {
            if subtitle?.isEmpty == false {
                VStack (alignment: .leading) {
                    title
                    Text(subtitle!).modifier(SecondaryLabelModifier())
                }
            }
        }
    }

    private func cell(title: Text, location: EVELocation?) -> some View {
        Group {
            if location != nil {
                VStack (alignment: .leading) {
                    title
                    Text(location!).modifier(SecondaryLabelModifier())
                }
            }
        }
    }

    private func cell(title: Text, amount: Double?) -> some View {
        Group {
            if amount != nil {
                VStack (alignment: .leading) {
                    title
                    Text(UnitFormatter.localizedString(from: amount!, unit: .isk, style: .long)).modifier(SecondaryLabelModifier())
                }
            }
        }
    }

    private func cell(title: Text, date: Date?) -> some View {
        Group {
            if date != nil {
                VStack (alignment: .leading) {
                    title
                    Text(DateFormatter.localizedString(from: date!, dateStyle: .medium, timeStyle: .medium)).modifier(SecondaryLabelModifier())
                }
            }
        }
    }

    var body: some View {
        Section {
            Group {
                cell(title: Text("Description"), subtitle: contract.title)
                cell(title: Text("Availability"), subtitle: contract.availability.title)
                cell(title: Text("Status"), subtitle: contract.currentStatus.title)
            }
            if contract.startLocationID != nil &&
                contract.endLocationID != nil &&
                contract.startLocationID != contract.endLocationID {
                cell(title: Text("Start Location"), location: contract.startLocationID.flatMap{locations[$0]})
                cell(title: Text("End Location"), location: contract.endLocationID.flatMap{locations[$0]})
            }
            else {
                cell(title: Text("Location"), location: contract.startLocationID.flatMap{locations[$0]})
            }
            Group {
                cell(title: Text("Price"), amount: contract.price)
                cell(title: Text("Reward"), amount: contract.reward)
            }
            Group {
                cell(title: Text("Date Issued"), date: contract.dateIssued)
                cell(title: Text("Date Expired"), date: contract.dateExpired)
                cell(title: Text("Date Accepted"), date: contract.dateAccepted)
                cell(title: Text("Date Completed"), date: contract.dateCompleted)
            }
        }
    }
}

struct ContractInfoItems: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    var items: ESI.ContractItems
    
    private func cell(for item: ESI.ContractItems.Element) -> some View {
        let type = try? managedObjectContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == Int32(item.typeID)).first()
        
        let content = HStack {
            type.map{Icon($0.image).cornerRadius(4)}
            VStack(alignment: .leading) {
                (type?.typeName).map {Text($0)} ?? Text("Unknown Type")
                Text("Quantity: \(UnitFormatter.localizedString(from: item.quantity, unit: .none, style: .long))").modifier(SecondaryLabelModifier())
            }
        }
        
        return Group {
            if type != nil {
                NavigationLink(destination: TypeInfo(type: type!)) {
                    content
                }
            }
            else {
                content
            }
        }

    }
    var body: some View {
        var items = self.items
        let i = items.partition{$0.isIncluded}
        let get = items[i...]
        let pay = items[..<i]
        return Group {
            if !get.isEmpty {
                Section(header: Text("BUYER WILL GET")) {
                    ForEach(get, id: \.recordID) {
                        self.cell(for: $0)
                    }
                }
            }
            if !pay.isEmpty {
                Section(header: Text("BUYER WILL PAY")) {
                    ForEach(pay, id: \.recordID) {
                        self.cell(for: $0)
                    }
                }
            }
        }
    }
}


struct ContractInfoBids: View {
    var bids: ESI.ContractBids
    var contacts: [Int64: Contact]

    var body: some View {
        let bids = self.bids.sorted{$0.dateBid > $1.dateBid}
        return Group {
            if !bids.isEmpty {
                Section(header: Text("BIDS")) {
                    ForEach(bids, id: \.bidID) { bid in
                        ContractBidCell(bid: bid, contact: self.contacts[Int64(bid.bidderID)])
                    }
                }
            }
        }
    }
}


#if DEBUG
struct ContractInfo_Previews: PreviewProvider {
    static var previews: some View {
        let contact = Contact(entity: NSEntityDescription.entity(forEntityName: "Contact", in: Storage.testStorage.persistentContainer.viewContext)!, insertInto: nil)
        contact.name = "Artem Valiant"
        contact.contactID = 1554561480
        
        let solarSystem = try! Storage.testStorage.persistentContainer.viewContext.from(SDEMapSolarSystem.self).first()!
        let location = EVELocation(solarSystem: solarSystem, id: Int64(solarSystem.solarSystemID))

        
        let items = (0..<3).map { i in
            ESI.ContractItems.Element(isIncluded: i % 2 == 0, isSingleton: false, quantity: 10, rawQuantity: 15, recordID: i, typeID: 645)
        }
        
        let bids = (0..<3).map { i in
            ESI.ContractBids.Element(amount: 1000 * Double (i + 1), bidID: i, bidderID: Int(contact.contactID), dateBid: Date(timeIntervalSinceNow: -3600 * 10 * TimeInterval(i)))
        }
        
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
                ContractInfoBasic(contract: contract, locations: [location.id: location])
                ContractInfoItems(items: items)
                ContractInfoBids(bids: bids, contacts: [contact.contactID: contact])
            }.listStyle(GroupedListStyle())
                .navigationBarTitle(contract.type.title)
        }.modifier(ServicesViewModifier.testModifier())
    }
}
#endif
