//
//  Contracts.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/13/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import CoreData
import Expressible

struct Contracts: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    @EnvironmentObject private var sharedState: SharedState

    @ObservedObject var contracts: Lazy<ContractsData, Account> = Lazy()

    
    var body: some View {
        let result = sharedState.account.map { account in
            self.contracts.get(account, initial: ContractsData(esi: sharedState.esi, characterID: account.characterID, managedObjectContext: managedObjectContext))
        }
        let contracts = (result?.result?.value).map{$0.open + $0.closed}

        let list = List {
            if contracts != nil {
                ContractsContent(contracts: contracts!,
                                  contacts: result!.result!.value!.contacts,
                                  locations: result!.result!.value!.locations)
            }
        }.listStyle(GroupedListStyle())
            .overlay(result == nil ? Text(RuntimeError.noAccount).padding() : nil)
            .overlay((result?.result?.error).map{Text($0)})
            .overlay(contracts?.isEmpty == true ? Text(RuntimeError.noResult).padding() : nil)
        
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
        .navigationBarTitle(Text("Contracts"))
    }
}

struct ContractsContent: View {
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

#if DEBUG
struct Contracts_Previews: PreviewProvider {
    static var previews: some View {
        Contracts()
            .modifier(ServicesViewModifier.testModifier())
    }
}
#endif
