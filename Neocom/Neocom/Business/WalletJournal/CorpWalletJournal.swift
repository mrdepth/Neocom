//
//  CorpWalletJournal.swift
//  Neocom
//
//  Created by Artem Shimanski on 7/2/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

import EVEAPI
import Alamofire
import Combine

struct CorpWalletJournal: View {
    
    @Environment(\.managedObjectContext) private var managedObjectContext
    @EnvironmentObject private var sharedState: SharedState

    @ObservedObject var journal: Lazy<DataLoader<ESI.WalletJournal, AFError>, Account> = Lazy()
    
    private func getJournal(characterID: Int64, cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy) -> AnyPublisher<ESI.WalletJournal, AFError> {
        sharedState.esi.characters.characterID(Int(characterID)).wallet().journal().get(cachePolicy: cachePolicy)
            .map{$0.value}
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    var body: some View {
        let result = sharedState.account.map { account in
            self.journal.get(account, initial: DataLoader(self.getJournal(characterID: account.characterID)))
        }
        let list = List {
            if result?.result?.value != nil {
                WalletJournalContent(journal: result!.result!.value!)
            }
        }
        .listStyle(GroupedListStyle())
        .overlay(result == nil ? Text(RuntimeError.noAccount).padding() : nil)
        .overlay((result?.result?.error).map{Text($0)})
        .overlay(result?.result?.value?.isEmpty == true ? Text(RuntimeError.noResult).padding() : nil)
        
        return Group {
            if result != nil {
                list.onRefresh(isRefreshing: Binding(result!, keyPath: \.isLoading)) {
                    guard let account = self.sharedState.account else {return}
                    result?.update(self.getJournal(characterID: account.characterID, cachePolicy: .reloadIgnoringLocalCacheData))
                }
            }
            else {
                list
            }
        }
        .navigationBarTitle(Text("Wallet Journal"))

    }
}

#if DEBUG
struct CorpWalletJournal_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CorpWalletJournal()
        }
        .environment(\.managedObjectContext, Storage.sharedStorage.persistentContainer.viewContext)
        .environmentObject(SharedState.testState())
    }
}
#endif
