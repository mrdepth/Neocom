//
//  Migration.swift
//  Neocom
//
//  Created by Artem Shimanski on 5/7/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import CloudKit
import Combine

struct Migration: View {
    let container = CKContainer.default()
    @State var editMode: EditMode = .active
    @State private var selection = Set<CKRecord>()
    @State private var migration: AnyPublisher<Result<Void, Error>, Never>?
    @State private var error: IdentifiableWrapper<Error>?
    @Environment(\.managedObjectContext) private var managedObjectContext
    @State private var isFinished = false
    
    func getAccounts() -> CloudKitLoader {
        let query = CKQuery(recordType: "Account", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "characterName", ascending: true)]
        return CloudKitLoader(container.privateCloudDatabase, query: query)
    }

    func getLoadouts() -> CloudKitLoader {
        let query = CKQuery(recordType: "Loadout", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "typeID", ascending: true)]
        return CloudKitLoader(container.privateCloudDatabase, query: query)
    }

    @ObservedObject private var accounts = Lazy<CloudKitLoader, Never>()
    @ObservedObject private var loadouts = Lazy<CloudKitLoader, Never>()
    
    private func onImport() {
        migration = MigrationHelper.migrate(records: selection, from: container.privateCloudDatabase, to: managedObjectContext)
            .asResult()
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    var body: some View {
        let accounts = self.accounts.get(initial: getAccounts())
        let loadouts = self.loadouts.get(initial: getLoadouts())
        
        let trailingItem = Group {
            if !accounts.records.isEmpty || !loadouts.records.isEmpty {
                if selection.count == accounts.records.count + loadouts.records.count {
                    Button(NSLocalizedString("Deselect All", comment: "")) {
                        withAnimation {
                            self.selection.removeAll()
                        }
                    }
                }
                else {
                    Button(NSLocalizedString("Select All", comment: "")) {
                        withAnimation {
                            self.selection = Set(accounts.records + loadouts.records)
                        }
                    }
                }
            }
        }
        
        let selectedAcounts = selection.filter{$0.recordType == "Account"}.count
        let selectedLoadouts = selection.count - selectedAcounts
        
        return ZStack {
            VStack(spacing: 0) {
                List(selection: $selection.animation()) {
                    MigrationAccountsSection(accounts: accounts, selection: $selection)
                    MigrationLoadoutsSection(loadouts: loadouts, selection: $selection)
                }
                .listStyle(GroupedListStyle())
                
                if !selection.isEmpty {
                    VStack(spacing: 0) {
                        Divider()
                        HStack {
                            Group {
                                if selectedAcounts > 0 && selectedLoadouts > 0 {
                                    Text("Selected \(selectedAcounts) Accounts and \(selectedLoadouts) Loadouts")
                                }
                                else if selectedAcounts > 0 {
                                    Text("Selected \(selectedAcounts) Accounts")
                                }
                                else if selectedLoadouts > 0 {
                                    Text("Selected \(selectedLoadouts) Loadouts")
                                }
                            }.animation(nil)
                            Spacer()
                            Button("Import", action: onImport)
                        }.padding()
                    }
                    .transition(.offset(x: 0, y: 100))
                    .background(Color(.systemBackground).edgesIgnoringSafeArea(.all))
                }
            }
            if isFinished {
                FinishedView(isPresented: $isFinished)
            }
        }
        .navigationBarTitle(Text("Migration"))
        .navigationBarItems(trailing: trailingItem)
        .environment(\.editMode, $editMode)
        .overlay(self.migration != nil ? ActivityIndicator() : nil)
        .onReceive(migration ?? Empty().eraseToAnyPublisher()) { result in
            self.migration = nil
            switch result {
            case .success:
                withAnimation {
                    self.isFinished = true
                }
            case let .failure(error):
                self.error = IdentifiableWrapper(error)
            }
        }
        .alert(item: $error) { error in
            Alert(title: Text("Error"), message: Text(error.wrappedValue.localizedDescription), dismissButton: .cancel(Text("Close")))
        }
    }
}

struct Migration_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            Migration()
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .modifier(ServicesViewModifier.testModifier())
    }
}
