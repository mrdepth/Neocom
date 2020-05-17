//
//  MigrationAccountsSection.swift
//  Neocom
//
//  Created by Artem Shimanski on 5/7/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import CloudKit

struct MigrationAccountsSection: View {
    
    @ObservedObject var accounts: CloudKitLoader
    @Binding var selection: Set<CKRecord>
    
    var header: some View {
        HStack {
            Text("ACCOUNTS")
            Spacer()
            if !accounts.records.isEmpty {
                if selection.isSuperset(of: accounts.records) {
                    Button(NSLocalizedString("DESELECT ALL", comment: "")) {
                        withAnimation {
                            self.selection.subtract(self.accounts.records)
                        }
                    }
                }
                else {
                    Button(NSLocalizedString("SELECT ALL", comment: "")) {
                        withAnimation {
                            self.selection.formUnion(self.accounts.records)
                        }
                    }
                }
            }
        }.animation(nil)
    }
    
    var body: some View {
        return Section(header: header) {
            ForEach(accounts.records, id: \.self) { record in
                MigrationAccountCell(record: record)
            }
            if accounts.isLoading {
                ActivityIndicatorView(style: .medium).frame(maxWidth: .infinity)
            }
            else if accounts.error != nil {
                Text(accounts.error!).foregroundColor(.secondary)
            }
            else if accounts.records.isEmpty {
                Text("No Accounts").foregroundColor(.secondary).frame(maxWidth: .infinity)
            }
        }
    }
}

struct MigrationAccountCell: View {
    var record: CKRecord
    
    var body: some View {
        HStack {
            (record["characterID"] as? Int64).map {
                Avatar(characterID: $0, size: .size128).frame(width: 40, height: 40)
            }
            (record["characterName"] as? String).map{Text($0)} ?? Text("Unknown")
        }
    }
}
