//
//  ContentView.swift
//  Neocom
//
//  Created by Artem Shimanski on 19.11.2019.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//
#if DEBUG
import SwiftUI
import Combine
import EVEAPI
import CoreData


struct ContentView: View {
    
    @State private var isFinished = false
    
    var body: some View {
        let contact1 = Contact(entity: NSEntityDescription.entity(forEntityName: "Contact", in: Storage.sharedStorage.persistentContainer.viewContext)!, insertInto: nil)
        contact1.name = "Artem Valiant"
        contact1.contactID = 1554561480
        contact1.category = ESI.RecipientType.character.rawValue

        let attachment = TextAttachmentContact(contact1, esi: ESI())
        
        
        let string = NSMutableAttributedString(string: "Text\n\n\nHello\nHello Wrold")
        string.append(NSAttributedString(attachment: attachment))
        string.append(NSAttributedString(attachment: TextAttachmentContact(contact1, esi: ESI())))
        string.append(NSAttributedString(attachment: TextAttachmentContact(contact1, esi: ESI())))
        string.append(NSAttributedString(string: "Rest text\nBlaBlaBla"))

        
        return ZStack {
            if isFinished {
                FinishedView(isPresented: $isFinished)
            }
        }.onReceive(NotificationCenter.default.publisher(for: .didUpdateSkillPlan)) { _ in
            withAnimation {
                self.isFinished = true
            }
        }

    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

#endif
