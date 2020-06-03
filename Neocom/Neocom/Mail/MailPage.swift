//
//  MailPage.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/14/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import Combine

struct MailPage: View {
    var label: ESI.MailLabel
    
    @Environment(\.managedObjectContext) private var managedObjectContext
    @ObservedObject private var mailHeaders = Lazy<MailHeadersData, Account>()
    @EnvironmentObject private var sharedState: SharedState
    @State private var deleteSubscription: AnyPublisher<[Int], Never> = Empty().eraseToAnyPublisher()
    
    var body: some View {
        let result = sharedState.account.map { account in
            self.mailHeaders.get(account, initial: MailHeadersData(esi: sharedState.esi, characterID: account.characterID, labelID: label.labelID!, managedObjectContext: managedObjectContext))
        }
        let sections = result?.sections?.value
        
        let list = List {
            if sections != nil {
                ForEach(sections!, id: \.date) { section in
                    Section(header: Text(DateFormatter.localizedString(from: section.date, dateStyle: .medium, timeStyle: .none).uppercased())) {
                        ForEach(section.mails, id: \.mailID) { mail in
                            MailHeader(mail: mail, contacts: result?.contacts.compactMapValues{$0} ?? [:]).onAppear {
                                if mail.mailID == sections?.last?.mails.last?.mailID {
                                    result?.next()
                                }
                            }
                        }.onDelete { indices in
                            guard let characerID = self.sharedState.account?.characterID else {return}
                            let mailIDs = indices.compactMap{section.mails[$0].mailID}
                            self.deleteSubscription = Publishers.Sequence(sequence: mailIDs).flatMap { mailID in
                                self.sharedState.esi.characters.characterID(Int(characerID)).mail().mailID(mailID).delete()
                                    .map { _ in mailID }
                                    .catch {_ in Empty<Int, Never>()}
                            }
                            .collect()
                            .receive(on: RunLoop.main)
                            .eraseToAnyPublisher()
                        }
                    }
                }
            }
        }
        .listStyle(GroupedListStyle())
        .overlay(result == nil ? Text(RuntimeError.noAccount).padding() : nil)
        .overlay(result?.sections?.error.map{Text($0)})
        .overlay(sections?.isEmpty == true ? Text(RuntimeError.noResult).padding() : nil)
        
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
        .navigationBarTitle(label.name ?? "")
        .onReceive(deleteSubscription) { mailIDs in
            result?.delete(mailIDs: Set(mailIDs))
            self.deleteSubscription = Empty().eraseToAnyPublisher()
        }
    }
}

#if DEBUG
struct MailPage_Previews: PreviewProvider {
    static var previews: some View {
        let label = ESI.MailLabel(color: .h0000fe, labelID: 1, name: "Inbox", unreadCount: 12)

        return NavigationView {
            MailPage(label: label)
        }
        .environment(\.managedObjectContext, Storage.sharedStorage.persistentContainer.viewContext)
        .environmentObject(SharedState.testState())

    }
}
#endif
