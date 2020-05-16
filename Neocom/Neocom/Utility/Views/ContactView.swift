//
//  ContactView.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/19/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import CoreData

struct ContactView: View {
//    var contact: Contact?
    var esi: ESI
    
    private var source: Avatar.Source?
    private var name: String?
    
    init(contact: Contact?, esi: ESI) {
        name = contact?.name
        self.esi = esi
        switch contact?.recipientType {
        case .character:
            source = .character(contact!.contactID, .size128)
        case .corporation:
            source = .corporation(contact!.contactID, .size128)
        case .alliance:
            source = .alliance(contact!.contactID, .size128)
        default:
            source = nil
        }
    }
    
    init(account: Account, esi: ESI) {
        name = account.characterName
        source = .character(account.characterID, .size128)
        self.esi = esi
    }
    
    var body: some View {
        
        return HStack {
            if source != nil {
                AvatarImageView(esi: esi, source: source!).aspectRatio(contentMode: .fit).clipShape(Circle())
            }
            else {
                Spacer().frame(width: 8)
            }
            name.map{Text($0)} ?? Text("Unknown")
        }
        .padding(2)
        .padding(.trailing, 8)
        .frame(height: 26)
        .background(Capsule().foregroundColor(Color(.systemFill)))
    }
}

struct ContactView_Previews: PreviewProvider {
    static var previews: some View {
        let contact1 = Contact(entity: NSEntityDescription.entity(forEntityName: "Contact", in: Storage.sharedStorage.persistentContainer.viewContext)!, insertInto: nil)
        contact1.name = "Artem Valiant"
        contact1.contactID = 1554561480
        contact1.category = ESI.RecipientType.character.rawValue

        let contact2 = Contact(entity: NSEntityDescription.entity(forEntityName: "Contact", in: Storage.sharedStorage.persistentContainer.viewContext)!, insertInto: nil)
        contact2.name = "Necrorise Squadron"
        contact2.contactID = 653533005
        contact2.category = ESI.RecipientType.corporation.rawValue

        return HStack {
            ContactView(contact: contact1, esi: ESI())
            ContactView(contact: contact2, esi: ESI())
            ContactView(contact: nil, esi: ESI())
        }
    }
}
