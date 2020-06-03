//
//  MigrationLoadoutsSection.swift
//  Neocom
//
//  Created by Artem Shimanski on 5/7/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import CloudKit
import CoreData
import Expressible

struct MigrationLoadoutsSection: View {
    
    @ObservedObject var loadouts: CloudKitLoader
    @Binding var selection: Set<CKRecord>
    
    var header: some View {
        HStack {
            Text("LOADOUTS")
            Spacer()
            if !loadouts.records.isEmpty {
                if selection.isSuperset(of: loadouts.records) {
                    Button(NSLocalizedString("DESELECT ALL", comment: "")) {
                        withAnimation {
                            self.selection.subtract(self.loadouts.records)
                        }
                    }
                }
                else {
                    Button(NSLocalizedString("SELECT ALL", comment: "")) {
                        withAnimation {
                            self.selection.formUnion(self.loadouts.records)
                        }
                    }
                }
            }
        }.animation(nil)
    }
    
    var body: some View {
        Section(header: header) {
            ForEach(loadouts.records, id: \.self) { record in
                MigrationLoadoutCell(record: record)
            }
            if loadouts.isLoading {
                ActivityIndicatorView(style: .medium).frame(maxWidth: .infinity)
            }
            else if loadouts.error != nil {
                Text(loadouts.error!).foregroundColor(.secondary)
            }
            else if loadouts.records.isEmpty {
                Text("No Loadouts").foregroundColor(.secondary).frame(maxWidth: .infinity)
            }
        }
    }
    
}

struct MigrationLoadoutCell: View {
    var record: CKRecord
    
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    var body: some View {
        let type = (record["typeID"] as? Int).flatMap {
            try? managedObjectContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == Int32($0)).first()
        }
        
        return HStack {
            type.map{Icon($0.image).cornerRadius(4)}
            VStack(alignment: .leading) {
                type?.typeName.map{Text($0)} ?? Text("Unknown")
                (record["name"] as? String).map{Text($0).modifier(SecondaryLabelModifier())}
            }
        }
    }
}
