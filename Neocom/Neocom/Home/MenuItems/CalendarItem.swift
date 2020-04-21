//
//  CalendarItem.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/27/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI

struct CalendarItem: View {
    @EnvironmentObject private var sharedState: SharedState
    
    let require: [ESI.Scope] = [.esiCalendarReadCalendarEventsV1,
                                .esiCalendarRespondCalendarEventsV1]
    
    var body: some View {
        Group {
            if sharedState.account?.verifyCredentials(require) == true {
                NavigationLink(destination: EVECalendar()) {
                    Icon(Image("calendar"))
                    Text("Calendar")
                }
            }
        }
    }
}

struct CalendarItem_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                CalendarItem()
            }.listStyle(GroupedListStyle())
        }
        .environmentObject(SharedState.testState())
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
