//
//  MailBody.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/17/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import Combine
import CoreData
import Alamofire

struct MailBody: View {
    @Binding var mail: ESI.MailHeaders.Element
    var contacts: [Int64: Contact]
    
    @EnvironmentObject private var sharedState: SharedState

    @ObservedObject private var mailBody = Lazy<DataLoader<(ESI.MailBody, NSAttributedString?), AFError>, Never>()
//    @State private var markReadPublisher: AnyPublisher<Void, Never>? = nil
    
    var body: some View {
        let result = sharedState.account.flatMap {account in
            mail.mailID.map { mailID in
                mailBody.get(initial: DataLoader(sharedState.esi.characters.characterID(Int(account.characterID)).mail().mailID(mailID).get()
                    .map{$0.value}
                    .map { mailBody -> (ESI.MailBody, NSAttributedString?) in
                        let text = mailBody.body?.data(using: .utf8).flatMap {
                            try? NSMutableAttributedString(data: $0,
                                                           options: [.documentType : NSAttributedString.DocumentType.html,
                                                                     .characterEncoding: String.Encoding.utf8.rawValue,
                                                                     .defaultAttributes: [:]],
                                                           documentAttributes: nil)
                            
                        }
                        text?.removeAttribute(.foregroundColor, range: NSRange(location: 0, length: text?.length ?? 0))
                        text?.removeAttribute(.font, range: NSRange(location: 0, length: text?.length ?? 0))
                        text?.removeAttribute(.paragraphStyle, range: NSRange(location: 0, length: text?.length ?? 0))
                        text?.addAttributes([.font: UIFont.preferredFont(forTextStyle: .body), .foregroundColor: UIColor.label],
                                            range: NSRange(location: 0, length: text?.length ?? 0))
                        return (mailBody, text)
                }
                .receive(on: RunLoop.main)))
            }
        }
        let body = result?.result?.value
        let error = result?.result?.error
        return Group {
            if body != nil {
                MailBodyContent(mailBody: body!.0, text: body!.1, contacts: contacts)
            }
            else if error != nil {
                Text(error!).padding()
            }
        }
//        .navigationBarTitle(mail.subject ?? "Mail")
    }
}

struct MailBodyContent: View {
    var mailBody: ESI.MailBody
    var text: NSAttributedString?
    var contacts: [Int64: Contact]
    
    @Environment(\.self) private var environment
    @Environment(\.managedObjectContext) private var managedObjectContext
    @EnvironmentObject private var sharedState: SharedState
    @State private var selectedDraft: MailDraft?
    
    private var from: some View {
        mailBody.from.flatMap {
            contacts[Int64($0)]?.name
        }.map {
            Text($0)
        }
    }
    
    private var to: Text {
        (mailBody.recipients?.compactMap {contacts[Int64($0.recipientID)]?.name}.joined(separator: ", ")).map {
            Text($0)
        } ?? Text("Unknown")
    }
    
    private func onReply() {
        let draft = MailDraft(entity: NSEntityDescription.entity(forEntityName: "MailDraft", in: managedObjectContext)!, insertInto: nil)
        let text = self.text?.mutableCopy() as? NSMutableAttributedString ?? NSMutableAttributedString()
        text.insert(NSAttributedString(string: "--------------------------------\n"), at: 0)
        text.addAttribute(.foregroundColor, value: UIColor.secondaryLabel, range: NSRange(location: 0, length: text.length))
        text.insert(NSAttributedString(string: "\n\n", attributes: [.foregroundColor: UIColor.label]), at: 0)
        draft.body = text
        draft.to = mailBody.recipients?.map{Int64($0.recipientID)} ?? []
        draft.subject = "RE: \(mailBody.subject ?? "")"
        self.selectedDraft = draft
    }
    
    var body: some View {
        GeometryReader { geometry in
            self.text.map { body in
                ScrollView(.vertical) {
                    VStack(alignment: .leading) {
                        HStack(alignment: .top) {
                            (self.mailBody.from.map{Avatar(characterID: Int64($0), size: .size128)} ?? Avatar(image: nil))
                                .frame(width: 40, height: 40)
                            VStack(alignment: .leading) {
                                self.from.font(.headline)
                                Group {
                                    (Text("To: ") + self.to.foregroundColor(.secondary))
//                                    self.mailBody.subject.map{Text("Subject: ") + Text($0).foregroundColor(.secondary)}
                                    self.mailBody.timestamp.map { date in
                                        Text(DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .medium)).foregroundColor(.secondary)
                                    }
                                }.font(.subheadline)
                            }
                        }.padding(.horizontal)
                        
                        Divider()
                        AttributedText(body, preferredMaxLayoutWidth: geometry.size.width - 32).padding(.horizontal, 16)
                    }
                }
            }
        }
        .navigationBarTitle(mailBody.subject ?? NSLocalizedString("Mail", comment: ""))
        .navigationBarItems(trailing: Button(action: onReply) {
            Text("Reply")
        })
        .sheet(item: $selectedDraft) { draft in
            ComposeMail(draft: draft) {
                self.selectedDraft = nil
            }
            .modifier(ServicesViewModifier(environment: self.environment, sharedState: self.sharedState))
            .navigationViewStyle(StackNavigationViewStyle())
        }

    }
}

#if DEBUG
struct MailBody_Previews: PreviewProvider {
    static var previews: some View {
        let contact = Contact(entity: NSEntityDescription.entity(forEntityName: "Contact", in: Storage.testStorage.persistentContainer.viewContext)!, insertInto: nil)
        contact.name = "Artem Valiant"
        contact.contactID = 1554561480

        let recipient = ESI.Characters.CharacterID.Mail.Recipient(recipientID: Int(contact.contactID), recipientType: .character)
        let body = ESI.MailBody(body: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
                     from: Int(contact.contactID),
                     labels: [1],
                     read: false,
                     recipients: repeatElement(recipient, count: 4).map{$0},
                     subject: "Mail Subject",
                     timestamp: Date())
        
        return
            NavigationView {
                MailBodyContent(mailBody: body, contacts: [contact.contactID: contact])
            }
            .modifier(ServicesViewModifier.testModifier())
    }
}
#endif
