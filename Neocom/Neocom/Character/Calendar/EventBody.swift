//
//  EventBody.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/27/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import Combine
import Alamofire

struct EventBody: View {
    var eventID: Int
    
    @EnvironmentObject private var sharedState: SharedState

    @ObservedObject private var event = Lazy<DataLoader<ESI.Event, AFError>, Account>()
    
    var body: some View {
        let result = sharedState.account.flatMap { account in
            self.event.get(account, initial: DataLoader(sharedState.esi.characters.characterID(Int(account.characterID)).calendar().eventID(eventID).get().map{$0.value}.receive(on: RunLoop.main)))
        }
        let event = result?.result?.value
        let error = result?.result?.error
        return Group {
            if event != nil {
                EventBodyContent(event: event!)
            }
            else if error != nil {
                Text(error!).padding()
            }
        }
    }
}

struct EventBodyContent: View {
    var event: ESI.Event
    
    var body: some View {
        let text = try? NSMutableAttributedString(data: event.text.data(using: .utf8) ?? Data(),
                                      options: [.documentType : NSAttributedString.DocumentType.html,
                                                .characterEncoding: String.Encoding.utf8.rawValue,
                                                .defaultAttributes: [:]],
                                      documentAttributes: nil)
        text?.removeAttribute(.foregroundColor, range: NSRange(location: 0, length: text?.length ?? 0))
        text?.removeAttribute(.font, range: NSRange(location: 0, length: text?.length ?? 0))
        text?.removeAttribute(.paragraphStyle, range: NSRange(location: 0, length: text?.length ?? 0))
        text?.addAttribute(.font, value: UIFont.preferredFont(forTextStyle: .body), range: NSRange(location: 0, length: text?.length ?? 0))
        
        let avatar: Avatar?
        
        switch event.ownerType {
        case .alliance:
            avatar = Avatar(allianceID: Int64(event.ownerID), size: .size128)
        case .character:
            avatar = Avatar(characterID: Int64(event.ownerID), size: .size128)
        case .corporation:
            avatar = Avatar(corporationID: Int64(event.ownerID), size: .size128)
        case .eveServer, .faction:
            avatar = nil
        }
        
        return GeometryReader { geometry in
            text.map { body in
                ScrollView(.vertical) {
                    VStack(alignment: .leading) {
                        HStack(alignment: .top) {
                            avatar?.frame(width: 40, height: 40)
                            VStack(alignment: .leading) {
                                Text(self.event.ownerName).font(.headline)
                                Group {
                                    Text(DateFormatter.localizedString(from: self.event.date, dateStyle: .medium, timeStyle: .medium)).foregroundColor(.secondary)
                                }.font(.subheadline)
                            }
                        }.padding(.horizontal)
                        
                        Divider()
                        Text(self.event.title).font(.headline).padding(.horizontal)
                        AttributedText(body, preferredMaxLayoutWidth: geometry.size.width - 32).padding(.horizontal, 16)
                    }
                }
            }
        }
    }
}

struct EventBody_Previews: PreviewProvider {
    static var previews: some View {
        let event = ESI.Event(date: Date.init(timeIntervalSinceNow: 3600 * 10),
                              duration: 10,
                              eventID: 1,
                              importance: 1,
                              ownerID: 1554561480,
                              ownerName: "Artem Valiant",
                              ownerType: .character,
                              response: "Response",
                              text: "Text", title: "Title")
        return EventBodyContent(event: event)
            .environmentObject(SharedState.testState())
    }
}
