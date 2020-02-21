//
//  MailDraftCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/19/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import CoreData
import Combine
import EVEAPI

struct MailDraftCell: View {
    @ObservedObject private var contacts = Lazy<DataLoader<[Int64: Contact], Never>>()
    @Environment(\.esi) private var esi
    @Environment(\.account) private var account
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    private func loadContacts() -> AnyPublisher<[Int64: Contact], Never> {
        guard var ids = draft.to else {return Just([:]).eraseToAnyPublisher()}
        if let id = account?.characterID {
            ids.append(id)
        }
        return Contact.contacts(with: Set(ids), esi: esi, characterID: account?.characterID, options: [.all], managedObjectContext: managedObjectContext).receive(on: RunLoop.main).eraseToAnyPublisher()
    }
    
    var draft: MailDraft
    var body: some View {
        let contacts = self.contacts.get(initial: DataLoader(loadContacts())).result?.value
        let subject = draft.subject?.isEmpty == false ? draft.subject : draft.body?.string
        return Group {
            MailHeaderContent(from: account?.characterID,
                              recipientIDs: draft.to ?? [],
                              subject: subject,
                              timestamp: draft.date,
                              isRead: true,
                              contacts: contacts)
        }
    }
}

struct MailDraftCell_Previews: PreviewProvider {
    static var previews: some View {
        let account = AppDelegate.sharedDelegate.testingAccount
        let esi = account.map{ESI(token: $0.oAuth2Token!)} ?? ESI()

        let context = AppDelegate.sharedDelegate.persistentContainer.viewContext
        let draft = MailDraft(entity: NSEntityDescription.entity(forEntityName: "MailDraft", in: context)!, insertInto: nil)
        draft.date = Date()
        draft.subject = "Subject"
        draft.body = NSAttributedString(string: "Some Body")
        draft.to = [1554561480]
        
        return MailDraftCell(draft: draft)
            .environment(\.managedObjectContext, context)
            .environment(\.account, account)
            .environment(\.esi, esi)
    }
}
