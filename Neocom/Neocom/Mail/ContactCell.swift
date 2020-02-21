//
//  ContactCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/18/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import CoreData
import EVEAPI

struct ContactCell: View {
    @Environment(\.esi) private var esi
    
    var contact: Contact
    
    var body: some View {
        HStack {
            if contact.recipientType == .character {
                Avatar(characterID: contact.contactID, size: .size128).frame(width: 40, height: 40)
            }
            else if contact.recipientType == .corporation {
                Avatar(corporationID: contact.contactID, size: .size128).frame(width: 40, height: 40)
            }
            else if contact.recipientType == .alliance {
                Avatar(allianceID: contact.contactID, size: .size128).frame(width: 40, height: 40)
            }
            contact.name.map{Text($0)} ?? Text("Unknown")
            Spacer()
        }
        
    }
}

struct ContactCell_Previews: PreviewProvider {
    static var previews: some View {
        let contact1 = Contact(entity: NSEntityDescription.entity(forEntityName: "Contact", in: AppDelegate.sharedDelegate.persistentContainer.viewContext)!, insertInto: nil)
        contact1.name = "Artem Valiant"
        contact1.contactID = 1554561480
        contact1.category = ESI.RecipientType.character.rawValue

        let contact2 = Contact(entity: NSEntityDescription.entity(forEntityName: "Contact", in: AppDelegate.sharedDelegate.persistentContainer.viewContext)!, insertInto: nil)
        contact2.name = "Necrorise Squadron"
        contact2.contactID = 653533005
        contact2.category = ESI.RecipientType.corporation.rawValue
        
        
        return List {
            ContactCell(contact: contact1)
            ContactCell(contact: contact2)
        }.listStyle(GroupedListStyle())
    }
}
