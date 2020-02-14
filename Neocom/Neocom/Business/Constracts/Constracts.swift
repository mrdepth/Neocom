//
//  Constracts.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/13/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import CoreData
import Expressible

struct Constracts: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.esi) private var esi
    @Environment(\.account) private var account

    @ObservedObject var contracts: Lazy<ContractsData> = Lazy()

    
    var body: some View {
        let result = account.map { account in
            self.contracts.get(initial: ContractsData(esi: esi, characterID: account.characterID, managedObjectContext: managedObjectContext))
        }
        let contracts = (result?.result?.value).map{$0.open + $0.closed}

        return List {
            if contracts != nil {
                ConstractsContent(contracts: contracts!,
                                  contacts: result!.result!.value!.contacts,
                                  locations: result!.result!.value!.locations)
            }
        }.listStyle(GroupedListStyle())
            .overlay(result == nil ? Text(RuntimeError.noAccount).padding() : nil)
            .overlay((result?.result?.error).map{Text($0)})
            .overlay(contracts?.isEmpty == true ? Text(RuntimeError.noResult).padding() : nil)
            .navigationBarTitle(Text("Contracts"))
    }
}

struct ConstractsContent: View {
    var contracts: ESI.PersonalContracts
    var contacts: [Int64: Contact]
    var locations: [Int64: EVELocation]
    
    private struct WalletTransactionsSection {
        var date: Date
        var transactions: ESI.WalletTransactions
    }

    
    var body: some View {
        ForEach(contracts, id: \.contractID) { contract in
            NavigationLink(destination: ContractInfo(contract: contract)) {
                ContractCell(contract: contract, contacts: self.contacts, locations: self.locations)
            }
        }
    }
}

struct Constracts_Previews: PreviewProvider {
    static var previews: some View {
        Constracts()
    }
}
