//
//  MailDrafts.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/19/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import CoreData
import EVEAPI

struct MailDrafts: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.self) private var environment
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \MailDraft.date, ascending: false)]) var drafts: FetchedResults<MailDraft>
    @State private var selectedDraft: MailDraft?
    @EnvironmentObject private var sharedState: SharedState
    
    var body: some View {
        List {
            ForEach(drafts) { draft in
                Button(action: {
                    self.selectedDraft = draft
                }) {
                    MailDraftCell(draft: draft).contentShape(Rectangle())
                }.buttonStyle(PlainButtonStyle())
            }.onDelete { indices in
                indices.map{self.drafts[$0]}.forEach {
                    $0.managedObjectContext?.delete($0)
                }
            }
        }.listStyle(GroupedListStyle())
        .overlay(drafts.isEmpty ? Text(RuntimeError.noResult) : nil)
        .sheet(item: $selectedDraft) { draft in
            ComposeMail(draft: draft) {
                self.selectedDraft = nil
            }
            .modifier(ServicesViewModifier(environment: self.environment, sharedState: self.sharedState))
            .navigationViewStyle(StackNavigationViewStyle())
        }
        .navigationBarTitle(Text("Drafts"))
        .navigationBarItems(trailing: EditButton())
    }
}

extension MailDraft: Identifiable {
    public var id: NSManagedObjectID {
        return objectID
    }
}

#if DEBUG
struct MailDrafts_Previews: PreviewProvider {
    
    static var previews: some View {
        let context = Storage.sharedStorage.persistentContainer.viewContext
        let draft = MailDraft(entity: NSEntityDescription.entity(forEntityName: "MailDraft", in: context)!, insertInto: context)
        draft.date = Date()
        draft.subject = "Subject"
        draft.body = NSAttributedString(string: "Some Body")
        draft.to = [1554561480]

        
        return NavigationView {
            MailDrafts()
        }
            .environmentObject(SharedState.testState())
            .environment(\.managedObjectContext, Storage.sharedStorage.persistentContainer.viewContext)

    }
}
#endif
