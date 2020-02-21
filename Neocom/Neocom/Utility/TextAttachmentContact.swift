//
//  TextAttachmentContact.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/19/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI


class TextAttachmentContact: TextAttachmentView<ContactView> {
    let contact: Contact
    init(_ contact: Contact, esi: ESI) {
        self.contact = contact
        super.init(rootView: ContactView(contact: contact, esi: esi))
        view.isUserInteractionEnabled = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var insets: UIEdgeInsets {
        return UIEdgeInsets(top: -1, left: -2, bottom: -1, right: -2)
    }
}
