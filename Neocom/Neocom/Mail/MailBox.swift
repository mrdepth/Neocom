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
import Combine

struct MailBox: View {
    @EnvironmentObject private var sharedState: SharedState
    @Environment(\.self) private var environment
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \MailDraft.date, ascending: false)]) private var drafts: FetchedResults<MailDraft>
//
    @ObservedObject private var labels = Lazy<DataLoader<ESI.MailLabels, AFError>, Account>()
    @State private var isComposeMailPresented = false
    
    private var composeButton: some View {
        BarButtonItems.compose {
            self.isComposeMailPresented = true
        }
    }
    
    private func getLabels(account: Account, cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy) -> AnyPublisher<ESI.MailLabels, AFError> {
        sharedState.esi.characters.characterID(Int(account.characterID)).mail().labels().get(cachePolicy: cachePolicy)
            .map{$0.value}
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    var body: some View {
        let result = sharedState.account.map { account in
            self.labels.get(account, initial: DataLoader(getLabels(account: account)))
        }
        let labels = result?.result?.value
//        let draftsCount =
        let list = List {
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
            
        
        return Group {
            if result != nil {
                list.onRefresh(isRefreshing: Binding(result!, keyPath: \.isLoading)) {
                    guard let account = self.sharedState.account else {return}
                    result?.update(self.getLabels(account: account, cachePolicy: .reloadIgnoringLocalCacheData))
                }
            }
            else {
                list
            }
        }
        .navigationBarTitle(Text("Mail"))
        .navigationBarItems(trailing: composeButton)
        .sheet(isPresented: $isComposeMailPresented) {
            ComposeMail {
                self.isComposeMailPresented = false
            }
            .modifier(ServicesViewModifier(environment: self.environment, sharedState: self.sharedState))
            .navigationViewStyle(StackNavigationViewStyle())
        }

    }
}

struct MailBox_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MailBox()
                .environmentObject(SharedState.testState())
                .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        }
    }
}

