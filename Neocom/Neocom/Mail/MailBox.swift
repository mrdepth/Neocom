//
//  MailBox.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/14/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import Alamofire

struct MailBox: View {
    @Environment(\.esi) private var esi
    @Environment(\.account) private var account
    @Environment(\.self) private var environment
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \MailDraft.date, ascending: false)]) private var drafts: FetchedResults<MailDraft>
//
    @ObservedObject private var labels = Lazy<DataLoader<ESI.MailLabels, AFError>>()
    @State private var isComposeMailPresented = false
    
    private var composeButton: some View {
        Button(action: {
            self.isComposeMailPresented = true
        }) {
            Image(systemName: "square.and.pencil").font(.title)
        }
    }

    var body: some View {
       let result = account.map { account in
            self.labels.get(initial: DataLoader(esi.characters.characterID(Int(account.characterID)).mail().labels().get().map{$0.value}.receive(on: RunLoop.main)))
        }
        let labels = result?.result?.value
//        let draftsCount =
        return List {
            if labels?.labels != nil {
                Section(footer: Text("Total Unread: \(UnitFormatter.localizedString(from: labels!.totalUnreadCount ?? 0, unit: .none, style: .long))").frame(maxWidth: .infinity, alignment: .trailing)) {
                    ForEach(labels!.labels!, id: \.labelID) { label in
                        MailLabel(label: label)
                    }
                }
            }
            NavigationLink(destination: MailDrafts()) {
                HStack {
                Text("Drafts")
                    Spacer()
                    if drafts.count > 0 {
                        Text("\(drafts.count)").foregroundColor(.secondary)
                    }
                }
            }

        }.listStyle(GroupedListStyle())
            .overlay(result == nil ? Text(RuntimeError.noAccount).padding() : nil)
            .overlay((result?.result?.error).map{Text($0)})
            .overlay(labels?.labels?.isEmpty == true ? Text(RuntimeError.noResult).padding() : nil)
            .navigationBarTitle(Text("Mail"))
            .navigationBarItems(trailing: composeButton)
            .sheet(isPresented: $isComposeMailPresented) {
                ComposeMail {
                    self.isComposeMailPresented = false
                }.modifier(ServicesViewModifier(environment: self.environment))
        }
    }
}

struct MailBox_Previews: PreviewProvider {
    static var previews: some View {
        let account = AppDelegate.sharedDelegate.testingAccount
        let esi = account.map{ESI(token: $0.oAuth2Token!)} ?? ESI()

        return NavigationView {
            MailBox()
                .environment(\.account, account)
                .environment(\.esi, esi)
                .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        }
    }
}

