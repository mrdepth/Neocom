//
//  MailLabel.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/14/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI

struct MailLabel: View {
    var label: ESI.MailLabel
    var body: some View {
        NavigationLink(destination: MailPage(label: label)) {
            HStack {
                Text(label.name ?? "Unnamed")
                Spacer()
                if (label.unreadCount ?? 0) > 0 {
                    Text("\(UnitFormatter.localizedString(from: label.unreadCount!, unit: .none, style: .long))").foregroundColor(.secondary)
                }
            }
        }
    }
}

struct MailLabel_Previews: PreviewProvider {
    static var previews: some View {
        let label = ESI.MailLabel(color: .h0000fe, labelID: 1, name: "Label Name", unreadCount: 1000)
        return NavigationView {
            List {
                MailLabel(label: label)
            }.listStyle(GroupedListStyle())
        }
    }
}
