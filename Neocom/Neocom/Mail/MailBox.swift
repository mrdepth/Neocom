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

    @ObservedObject private var labels = Lazy<DataLoader<ESI.MailLabels, AFError>>()

    var body: some View {
        let result = account.map { account in
            self.labels.get(initial: DataLoader(esi.characters.characterID(Int(account.characterID)).mail().labels().get().map{$0.value}.receive(on: RunLoop.main)))
        }
        let labels = result?.result?.value
        return List {
            if labels?.labels != nil {
                Section(footer: Text("Total Unread: \(UnitFormatter.localizedString(from: labels!.totalUnreadCount ?? 0, unit: .none, style: .long))").frame(maxWidth: .infinity, alignment: .trailing)) {
                    ForEach(labels!.labels!, id: \.labelID) { label in
                        NavigationLink(destination: MailPage(label: label)) {
                            MailLabel(label: label)
                        }
                    }
                }
            }
        }.listStyle(GroupedListStyle())
            .overlay(result == nil ? Text(RuntimeError.noAccount).padding() : nil)
            .overlay((result?.result?.error).map{Text($0)})
            .overlay(labels?.labels?.isEmpty == true ? Text(RuntimeError.noResult).padding() : nil)
            .navigationBarTitle(Text("Mail"))
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

