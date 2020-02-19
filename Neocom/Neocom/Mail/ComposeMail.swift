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

struct ComposeMail: View {
    @Environment(\.account) private var account
    @State private var text = NSAttributedString()
    @State private var recipients = NSAttributedString()
    @State private var firstResponder: UITextView?
    @Environment(\.esi) private var esi
    @Environment(\.managedObjectContext) private var managedObjectContext
    @State private var recipientsFieldFrame: CGRect?
    @ObservedObject private var contactsSearchController = Lazy<SearchController<[Contact]?, NSAttributedString>>()

    private var sendButton: some View {
        Button(action: {}) {
            Image(systemName: "paperplane")
        }
    }
    
    private var cancelButton: some View {
        Button(action: {}) {
            Text("Cancel")
        }
    }
    
    private var attachmentButton: some View {
        Button(action: {}) {
            Image(systemName: "paperclip")
        }
    }
    
    
    private func search(_ string: NSAttributedString) -> AnyPublisher<[Contact]?, Never> {
        let s = string.string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else {return Just(nil).eraseToAnyPublisher()}
        return Contact.searchContacts(containing: s, esi: esi, options: [.universe], managedObjectContext: managedObjectContext)
            .map{$0 as Optional}
            .eraseToAnyPublisher()
    }

    
    private func recipients(_ rootGeometry: GeometryProxy) -> some View {
//        let searchController = contactsSearchController.get(initial: SearchController(initialValue: nil, predicate: NSAttributedString(), search))
        return GeometryReader { geometry in
            TextView(text: self.$recipients,
                     typingAttributes: [.font: UIFont.preferredFont(forTextStyle: .body)],
                     placeholder: NSAttributedString(string: NSLocalizedString("To:", comment: ""),
                                                     attributes: [.font: UIFont.preferredFont(forTextStyle: .headline),
                                                                  .foregroundColor: UIColor.secondaryLabel]),
                     style: .fixedLayoutWidth(geometry.size.width),
                     onBeginEditing: { self.firstResponder = $0 },
                     onEndEditing: {
                        if self.firstResponder == $0 {
                            self.firstResponder = nil
                        }
            })
                .anchorPreference(key: FramePreferenceKey.self, value: Anchor<CGRect>.Source.bounds) {
                    [rootGeometry[$0]]
            }
        }.frame(height: self.recipientsFieldFrame?.height)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        HStack {
                            self.recipients(geometry)
                        }
                        HStack {
                            Text("From:").font(.headline).foregroundColor(.secondary)
                            Text(self.account?.characterName ?? "")
                        }
                    }.padding(.horizontal)
                    Divider()
                    TextView(text: self.$text, typingAttributes: [.font: UIFont.preferredFont(forTextStyle: .body)]).padding(.horizontal)
                }
            }
            VStack(spacing: 0) {
                Spacer().frame(height: self.recipientsFieldFrame?.maxY)
            }
        }
        .onPreferenceChange(FramePreferenceKey.self) {
            self.recipientsFieldFrame = $0.first
        }
        .padding(.top)
        .navigationBarTitle("Compose Mail")//, displayMode: .inline)
        .navigationBarItems(leading: cancelButton,
                            trailing: sendButton)
    }
}

struct ComposeMail_Previews: PreviewProvider {
    static var previews: some View {
        let account = AppDelegate.sharedDelegate.testingAccount
        let esi = account.map{ESI(token: $0.oAuth2Token!)} ?? ESI()

        return NavigationView {
            ComposeMail()
        }
        .environment(\.account, account)
        .environment(\.esi, esi)
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)

    }
}
