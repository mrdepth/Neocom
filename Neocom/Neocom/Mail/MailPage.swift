//
//  MailPage.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/14/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI

struct MailPage: View {
    var label: ESI.MailLabel
    
    @Environment(\.managedObjectContext) private var managedObjectContext
    @ObservedObject private var mailHeaders = Lazy<MailHeadersData>()
    @Environment(\.esi) private var esi
    @Environment(\.account) private var account

    var body: some View {
        let result = account.map { account in
            self.mailHeaders.get(initial: MailHeadersData(esi: esi, characterID: account.characterID, labelID: label.labelID!, managedObjectContext: managedObjectContext))
        }
        let sections = result?.sections?.value
        
        return List {
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
                            let mailIDs = indices.compactMap{section.mails[$0].mailID}
                            result?.delete(mailIDs: Set(mailIDs))
                        }
                    }
                }
            }
        }
        .listStyle(GroupedListStyle())
        .overlay(result == nil ? Text(RuntimeError.noAccount).padding() : nil)
        .overlay(result?.sections?.error.map{Text($0)})
        .overlay(sections?.isEmpty == true ? Text(RuntimeError.noResult).padding() : nil)
        .navigationBarTitle(Text("Planetaries"))
        .navigationBarTitle(label.name ?? "")
    }
}

struct MailPage_Previews: PreviewProvider {
    static var previews: some View {
        let account = AppDelegate.sharedDelegate.testingAccount
        let esi = account.map{ESI(token: $0.oAuth2Token!)} ?? ESI()
        let label = ESI.MailLabel(color: .h0000fe, labelID: 1, name: "Inbox", unreadCount: 12)

        return NavigationView {
            MailPage(label: label)
        }
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environment(\.account, account)
        .environment(\.esi, esi)

    }
}
