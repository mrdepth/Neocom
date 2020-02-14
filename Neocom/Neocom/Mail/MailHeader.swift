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
    
    var header: ESI.MailHeaders.Element
    var contacts: [Int64: Contact]
    
    var body: some View {
        let recipient: String?
        let recipientIDs: [Int64]
        let from = header.from.map{Int64($0)}
        
        if let from = from, from == account?.characterID {
            let recipients = header.recipients?.prefix(3)
            recipientIDs = recipients?//.filter{$0.recipientType == .character}
                .map{Int64($0.recipientID)} ?? []
            recipient = recipients?.compactMap {
                contacts[Int64($0.recipientID)]?.name
            }.joined(separator: ", ")
        }
        else {
            recipientIDs = from.map{[$0]} ?? []
            recipient = from.flatMap{contacts[$0]?.name}
        }

        return HStack {
            ZStack {
                ForEach(Array(Set(recipientIDs).sorted().enumerated()), id: \.offset) { (offset, element) in
                    Avatar(characterID: element, size: .size128)
                        .frame(width: 40, height: 40)
                        .offset(x: CGFloat(offset * -4), y: 0)
                        .zIndex(Double(-offset))
                }
            }
            
            VStack(alignment: .leading) {
                (recipient.map{Text($0)} ?? Text("Unknown"))
                header.subject.map{Text($0).font(.caption).lineLimit(3)}
            }.foregroundColor(header.isRead == true ? .secondary : .primary)
            Spacer()
            header.timestamp.map { date in
                Text(DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .short)).modifier(SecondaryLabelModifier()).layoutPriority(1)
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

        
        
        let header = ESI.MailHeaders.Element(from: Int(contact.contactID),
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
            MailHeader(header: header, contacts: [contact.contactID: contact, contact2.contactID: contact2])
        }.listStyle(GroupedListStyle())
            .environment(\.account, account)
            .environment(\.esi, esi)

    }
}
