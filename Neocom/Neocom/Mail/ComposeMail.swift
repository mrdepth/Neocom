//
//  ComposeMail.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/17/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import CoreData
import Combine
import Alamofire

struct ComposeMail: View {
    var draft: MailDraft? = nil
    var onComplete: () -> Void
    
    @Environment(\.esi) private var esi
    @Environment(\.account) private var account
    @Environment(\.managedObjectContext) private var managedObjectContext

    var body: some View {
        NavigationView {
            if account != nil {
                ComposeMailContent(esi: esi, account: account!, managedObjectContext: managedObjectContext, draft: draft, onComplete: onComplete)
            }
        }
    }
}

fileprivate struct ContactsSearchAlignmentID: AlignmentID {
    static func defaultValue(in context: ViewDimensions) -> CGFloat {
        return context[.top]
    }
}

fileprivate struct ComposeMailContent: View {
    var onComplete: () -> Void
    
    private var account: Account
    private var managedObjectContext: NSManagedObjectContext
    private var esi: ESI
    @State private var text = NSAttributedString()
    @State private var subject: String
    @State private var firstResponder: UITextView?
    @State private var recipientsFieldFrame: CGRect?
    @State private var sendSubscription: AnyCancellable?
    @State private var error: IdentifiableWrapper<Error>?
    @State private var needsSaveDraft = true
    @State private var isSaveDraftAlertPresented = false
    private var draft: MailDraft?
    
    @ObservedObject var contactsSearchController: SearchController<[Contact]?, NSAttributedString>
    @State private var contactsInitialLoading: AnyPublisher<[Int64:Contact], Never>

    init(esi: ESI, account: Account, managedObjectContext: NSManagedObjectContext, draft: MailDraft?, onComplete: @escaping () -> Void) {
        self.esi = esi
        self.account = account
        self.managedObjectContext = managedObjectContext
        self.onComplete = onComplete
        self.draft = draft
        func search(_ string: NSAttributedString) -> AnyPublisher<[Contact]?, Never> {
            let s = string.string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(.symbols))
            guard !s.isEmpty else {return Just(nil).eraseToAnyPublisher()}
            return Contact.searchContacts(containing: s, esi: esi, options: [.universe], managedObjectContext: managedObjectContext)
                .map{$0 as Optional}
                .eraseToAnyPublisher()
        }
        
        _subject = State(initialValue: draft?.subject ?? "")
        _text = State(initialValue: draft?.body ?? NSAttributedString())
        
        contactsSearchController = SearchController(initialValue: nil, predicate: NSAttributedString(), search)
        
        let contactsInitialLoading: AnyPublisher<[Int64:Contact], Never>
        if let ids = draft?.to, !ids.isEmpty {
//            var subscription: AnyCancellable?
            contactsInitialLoading = Contact.contacts(with: Set(ids), esi: esi, characterID: account.characterID, options: [.all], managedObjectContext: managedObjectContext).receive(on: RunLoop.main).eraseToAnyPublisher()
//            subscription = Contact.contacts(with: Set(ids), esi: esi, characterID: account.characterID, options: [.all], managedObjectContext: managedObjectContext).receive(on: RunLoop.main).sink { contacts in
//                subscription?.cancel()
//                subscription = nil
//            }
        }
        else {
            contactsInitialLoading = Empty().eraseToAnyPublisher()
        }
        _contactsInitialLoading = State(initialValue: contactsInitialLoading)
    }
    
    private func loadContacts(_ contacts: [Int64: Contact]) {
        let s = contacts.values.filter{$0.name != nil}.sorted{$0.name! < $1.name!}.map {
            TextAttachmentContact($0, esi: esi)
        }.reduce(into: NSMutableAttributedString()) {s, contact in s.append(NSAttributedString(attachment: contact))}
        self.contactsSearchController.predicate = s
        self.contactsInitialLoading = Empty().eraseToAnyPublisher()
    }
    
    private var currentMail: ESI.Mail {
        let recipients = contactsSearchController.predicate.attachments.values
            .compactMap{$0 as? TextAttachmentContact}
            .map{ESI.Recipient(recipientID: Int($0.contact.contactID), recipientType: $0.contact.recipientType ?? .character)}

        let data = try? text.data(from: NSRange(location: 0, length: text.length),
                                  documentAttributes: [.documentType : NSAttributedString.DocumentType.html])
        
        let html = data.flatMap{String(data: $0, encoding: .utf8)} ?? text.string
        return ESI.Mail(approvedCost: 0, body: html, recipients: recipients, subject: self.subject)
    }
    
    private func sendMail() {
        let mail = currentMail
        self.sendSubscription = esi.characters.characterID(Int(account.characterID)).mail().post(mail: mail).sink(receiveCompletion: { (result) in
            self.sendSubscription = nil
            switch result {
            case .finished:
                self.onComplete()
            case let .failure(error):
                self.error = IdentifiableWrapper(error)
            }
        }, receiveValue: {_ in})
    }
    
    private var sendButton: some View {
        let recipients = contactsSearchController.predicate.attachments.values.compactMap{$0 as? TextAttachmentContact}

        return Button(action: {
            self.sendMail()
        }) {
            Image(systemName: "paperplane")
        }.disabled(recipients.isEmpty || text.length == 0 || sendSubscription != nil)
    }
    
    private var cancelButton: some View {
        BarButtonItems.close {
            if self.text.length > 0 {
                self.isSaveDraftAlertPresented = true
            }
            else {
                self.onComplete()
            }
        }
    }
    
    private var saveDraftAlert: Alert {
        Alert(title: Text("Save Draft"), primaryButton: Alert.Button.default(Text("Save"), action: {
            self.needsSaveDraft = true
            self.onComplete()
        }), secondaryButton: Alert.Button.destructive(Text("Discard Changes"), action: {
            self.needsSaveDraft = false
            self.onComplete()
        }))
    }
    
    private func saveDraft() {
        let recipients = contactsSearchController.predicate.attachments.values
            .compactMap{$0 as? TextAttachmentContact}
            .map{$0.contact.contactID}
        let draft = self.draft ?? MailDraft(context: managedObjectContext)
        draft.body = text
        draft.subject = subject
        draft.to = recipients
        draft.date = Date()
    }
    
    private var attachmentButton: some View {
        Button(action: {}) {
            Image(systemName: "paperclip")
        }
    }
    
    private func recipients(_ rootGeometry: GeometryProxy) -> some View {
        TextView(text: self.$contactsSearchController.predicate,
                 typingAttributes: [.font: UIFont.preferredFont(forTextStyle: .body)],
                 placeholder: NSAttributedString(string: NSLocalizedString("To:", comment: ""),
                                                 attributes: [.font: UIFont.preferredFont(forTextStyle: .headline),
                                                              .foregroundColor: UIColor.secondaryLabel]),
                 style: .fixedLayoutWidth(rootGeometry.size.width - 32),
                 onBeginEditing: { self.firstResponder = $0 },
                 onEndEditing: {
                    if self.firstResponder == $0 {
                        self.firstResponder = nil
                    }
        }).alignmentGuide(VerticalAlignment(ContactsSearchAlignmentID.self)) {$0[.bottom]}
    }
    
    private var contactsSearchView: some View {
        Group {
            if firstResponder != nil && contactsSearchController.results != nil {
                ZStack(alignment: Alignment(horizontal: .center, vertical: VerticalAlignment(ContactsSearchAlignmentID.self))) {
                    ContactsSearchResults(contacts: contactsSearchController.results ?? []) { contact in
                        var attachments = self.contactsSearchController.predicate.attachments.map{($0.key.location, $0.value)}.sorted{$0.0 < $1.0}.map{$0.1}
                        attachments.append(TextAttachmentContact(contact, esi: self.esi))
                        self.firstResponder?.resignFirstResponder()
                        self.contactsSearchController.predicate = attachments.reduce(into: NSMutableAttributedString()) { s, attachment in
                            s.append(NSAttributedString(attachment: attachment))
                        }
                    }
                }
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    HStack {
                        self.recipients(geometry)
                    }
                    HStack {
                        Text("From:").font(.headline).foregroundColor(.secondary)
                        ContactView(account: self.account, esi: self.esi)
                    }
                    HStack {
                        TextField("Subject", text: self.$subject)
                    }
                }.padding(.horizontal, 16)
                Divider()
                TextView(text: self.$text, typingAttributes: [.font: UIFont.preferredFont(forTextStyle: .body)]).padding(.horizontal, 16)
            }.overlay(self.contactsSearchView, alignment: Alignment(horizontal: .center, vertical: VerticalAlignment(ContactsSearchAlignmentID.self)))
                .overlay(self.sendSubscription != nil ? ActivityView() : nil)
        }
        .onPreferenceChange(FramePreferenceKey.self) {
            if self.recipientsFieldFrame?.size != $0.first?.integral.size {
                self.recipientsFieldFrame = $0.first?.integral
            }
        }
        .padding(.top)
            .navigationBarTitle("Compose Mail")//, displayMode: .inline)
            .navigationBarItems(leading: cancelButton,
                                trailing: sendButton)
            .alert(item: self.$error) { error in
                Alert(title: Text("Error"), message: Text(error.wrappedValue.localizedDescription), dismissButton: Alert.Button.default(Text("Close")))
        }
        .alert(isPresented: $isSaveDraftAlertPresented) {
            self.saveDraftAlert
        }
        .onDisappear {
            if self.needsSaveDraft {
                self.saveDraft()
            }
        }
        .onReceive(contactsInitialLoading) { contacts in
            self.loadContacts(contacts)
        }
    }
}

struct ComposeMail_Previews: PreviewProvider {
    static var previews: some View {
        let account = AppDelegate.sharedDelegate.testingAccount
        let esi = account.map{ESI(token: $0.oAuth2Token!)} ?? ESI()

        return ComposeMail {}
            .environment(\.account, account)
            .environment(\.esi, esi)
            .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        
    }
}
