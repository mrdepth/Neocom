//
//  MailHeader.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/14/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import CoreData

struct MailHeader: View {
    @Environment(\.account) private var account
    
    var mail: ESI.MailHeaders.Element
    var contacts: [Int64: Contact]
    
    var body: some View {
        let recipientIDs: [Int64] = mail.recipients?.map{Int64($0.recipientID)} ?? []
        let from = mail.from.map{Int64($0)}

        return  NavigationLink(destination: MailBody(mail: mail, contacts: contacts)) {
            MailHeaderContent(from: from, recipientIDs: recipientIDs, subject: mail.subject, timestamp: mail.timestamp, isRead: mail.isRead == true, contacts: contacts)
        }
    }
}

struct MailHeaderContent: View {
    @Environment(\.account) private var account
    let from: Int64?
    let recipientIDs: [Int64]
    let subject: String?
    let timestamp: Date?
    var isRead: Bool
    var contacts: [Int64: Contact]?

    var body: some View {
        let recipient: String?
        let recipientIDs: [Int64]

        if let from = from, from == account?.characterID {
            recipientIDs = Array(self.recipientIDs.prefix(3))
            recipient = recipientIDs.compactMap { contacts?[$0]?.name }.joined(separator: ", ")
        }
        else {
            recipientIDs = from.map{[$0]} ?? []
            recipient = from.flatMap{contacts?[$0]?.name}
        }

        
        return HStack {
            ZStack {
                ForEach(Array(recipientIDs.sorted().enumerated()), id: \.offset) { (offset, element) in
                    Avatar(characterID: element, size: .size128)
                        .frame(width: 40, height: 40)
                        .offset(x: CGFloat(offset * -4), y: 0)
                        .zIndex(Double(-offset))
                }
            }
            
            VStack(alignment: .leading) {
                if contacts != nil {
                    (recipient.map{Text($0)} ?? Text("Unknown"))
                }
                subject.map{Text($0).font(.caption).lineLimit(3)}
            }.foregroundColor(isRead ? .secondary : .primary)
            Spacer()
            timestamp.map { date in
                Text(DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .short)).modifier(SecondaryLabelModifier())
            }
        }
    }
}

struct MailHeader_Previews: PreviewProvider {
    static var previews: some View {
        let account = AppDelegate.sharedDelegate.testingAccount
        let esi = account.map{ESI(token: $0.oAuth2Token!)} ?? ESI()

        let contact = Contact(entity: NSEntityDescription.entity(forEntityName: "Contact", in: AppDelegate.sharedDelegate.persistentContainer.viewContext)!, insertInto: nil)
        contact.name = "Artem Valiant"
        contact.contactID = 1554561480

        let contact2 = Contact(entity: NSEntityDescription.entity(forEntityName: "Contact", in: AppDelegate.sharedDelegate.persistentContainer.viewContext)!, insertInto: nil)
        contact2.name = "Artie Ziff"
        contact2.contactID = 1965939845

        
        
        let mail = ESI.MailHeaders.Element(from: Int(contact.contactID),
                                           isRead: false,
                                           labels: [1],
                                           mailID: 1,
                                           recipients: [
                                            ESI.Characters.CharacterID.Mail.Recipient(recipientID: Int(contact.contactID), recipientType: .character),
                                            ESI.Characters.CharacterID.Mail.Recipient(recipientID: Int(contact2.contactID), recipientType: .character)
            ],
                                           subject: "Mail Subject",
                                           timestamp: Date(timeIntervalSinceNow: -3600 * 12))
        return List {
            MailHeader(mail: mail, contacts: [contact.contactID: contact, contact2.contactID: contact2])
        }.listStyle(GroupedListStyle())
            .environment(\.account, account)
            .environment(\.esi, esi)

    }
}
