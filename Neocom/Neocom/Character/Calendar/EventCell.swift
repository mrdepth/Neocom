//
//  EventCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/27/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI

struct EventCell: View {
    var event: ESI.Calendar.Element
    
    var body: some View {
        let content = HStack {
            Text(event.title ?? "")
            Spacer()
            VStack(alignment: .trailing) {
                Text(DateFormatter.localizedString(from: event.eventDate!, dateStyle: .none, timeStyle: .medium))
                event.eventResponse.map {
                    Text($0.rawValue.capitalized)
                }
            }.modifier(SecondaryLabelModifier())
        }
        
        return Group {
            if event.eventID != nil {
                NavigationLink(destination: EventBody(eventID: event.eventID!)) {
                    content
                }
            }
            else {
                content
            }
        }
    }
}

struct EventCell_Previews: PreviewProvider {
    static var previews: some View {
        List {
            EventCell(event: ESI.Calendar.Element(eventDate: Date(timeIntervalSinceNow: 3600), eventID: 1, eventResponse: .accepted, importance: 1, title: "Title"))
        }.listStyle(GroupedListStyle())
    }
}
