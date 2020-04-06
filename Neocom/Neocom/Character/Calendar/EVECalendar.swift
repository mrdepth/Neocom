//
//  EVECalendar.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/27/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import Alamofire

struct EVECalendar: View {
    @ObservedObject private var calendar = Lazy<DataLoader<ESI.Calendar, AFError>>()
    @Environment(\.esi) private var esi
    @Environment(\.account) private var account

    private func calendar(characterID: Int64) -> DataLoader<ESI.Calendar, AFError> {
        let calendar = esi.characters.characterID(Int(characterID)).calendar().get(fromEvent: nil).map{$0.value}
            .receive(on: RunLoop.main)
        return DataLoader(calendar)
    }
    
    private struct CalendarSection {
        var date: Date
        var events: ESI.Calendar
    }

    var body: some View {
        let calendar = account.map { account in
            self.calendar.get(initial: self.calendar(characterID: account.characterID))
        }
        
        let date = Date()
        let events = calendar?.result?.value?.filter{$0.eventDate != nil && $0.eventDate! > date}

        return List {
            if events != nil {
                EVECalendarContent(events: events!)
            }
        }.listStyle(GroupedListStyle())
            .overlay(calendar == nil ? Text(RuntimeError.noAccount).padding() : nil)
            .overlay((calendar?.result?.error).map{Text($0)})
            .overlay(events?.isEmpty == true ? Text(RuntimeError.noResult).padding() : nil)
            .navigationBarTitle(Text("Calendar"))

    }
}

struct EVECalendarContent: View {
    var events: ESI.Calendar
    
    private struct CalendarSection {
        var date: Date
        var events: ESI.Calendar
    }

    var body: some View {
        let calendar = Calendar(identifier: .gregorian)
        let items = events.sorted{$0.eventDate! < $1.eventDate!}
        
        let sections = Dictionary(grouping: items, by: { (i) -> Date in
            let components = calendar.dateComponents([.year, .month, .day], from: i.eventDate!)
            return calendar.date(from: components) ?? i.eventDate!
        }).sorted {$0.key < $1.key}.map { (date, events) in
            CalendarSection(date: date, events: events)
        }

        return ForEach(sections, id: \.date) { section in
            Section(header: Text(DateFormatter.localizedString(from: section.date, dateStyle: .medium, timeStyle: .none).uppercased())) {
                ForEach(section.events, id: \.eventID) { item in
                    EventCell(event: item)
                }
            }
        }

    }
}

struct EVECalendar_Previews: PreviewProvider {
    static var previews: some View {
        let account = AppDelegate.sharedDelegate.testingAccount
        let esi = account.map{ESI(token: $0.oAuth2Token!)} ?? ESI()
        
        let calendar = (0..<100).map { i in
            ESI.Calendar.Element(eventDate: Date(timeIntervalSinceNow: 3600 * TimeInterval(i) * 3),
                                 eventID: i,
                                 eventResponse: .accepted,
                                 importance: 1,
                                 title: "Event id: \(i)")
        }
        
        return NavigationView {
            List {
                EVECalendarContent(events: calendar)
            }.listStyle(GroupedListStyle())
                .navigationBarTitle(Text("Wallet Journal"))
            
        }
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environment(\.account, account)
        .environment(\.esi, esi)
    }
}
