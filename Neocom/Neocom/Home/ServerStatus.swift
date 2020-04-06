//
//  ServerStatus.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/29/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import Alamofire
import Combine

struct ServerStatus: View {
    @Environment(\.esi) private var esi
    @ObservedObject private var status = Lazy<DataLoader<ESI.ServerStatus, AFError>>()
    var body: some View {
        let status = self.status.get(initial: DataLoader(esi.status.get().map{$0.value}.receive(on: RunLoop.main))).result?.value
        return Group {
            if status != nil {
                ServerStatusContent(status: status!)
            }
        }
    }
}

struct ServerStatusContent: View {
    var status: ESI.ServerStatus
    @State private var serverTime = Date()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
    
    var body: some View {
        HStack() {
            Text(dateFormatter.string(from: serverTime))
            Text("|")
            if status.players > 0 {
                 Text("Tranquility - ") + Text("Online").fontWeight(.semibold) + Text(" (\(UnitFormatter.localizedString(from: status.players, unit: .none, style: .long)) players)")
            }
            else {
                Text("Tranquility - ") + Text("Offline").fontWeight(.semibold)
            }
        }
        .modifier(SecondaryLabelModifier())
        .onReceive(Timer.publish(every: 1, on: RunLoop.main, in: .default).autoconnect()) { _ in
            self.serverTime = Date()
        }
    }
}

struct ServerStatus_Previews: PreviewProvider {
    static var previews: some View {
        ServerStatusContent(status: ESI.ServerStatus(players: 1000, serverVersion: "1.0", startTime: Date(timeIntervalSinceNow: -3600), vip: false))
    }
}
