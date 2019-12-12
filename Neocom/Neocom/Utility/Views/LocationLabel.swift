//
//  LocationLabel.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/12/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible

//struct LocationLabel: View {
//    var location: EVELocation
//
//    init(_ location: EVELocation) {
//        self.location = location
//    }
//
//    var body: some View {
//        Text(location)
//    }
//}

extension Text {
    init(_ location: EVELocation) {
        let security = location.solarSystem.map{String(format: "%.1f ", $0.security)} ?? ""
        let solarSystemName: String
        let locationName: String
        if let solarSystem = location.solarSystem {
            if let name = location.structureName {
                if name.hasPrefix(solarSystem.solarSystemName) {
                    solarSystemName = solarSystem.solarSystemName
                    locationName = String(name.dropFirst(solarSystemName.count))
                }
                else {
                    solarSystemName = ""
                    locationName = name
                }
            }
            else {
                solarSystemName = solarSystem.solarSystemName
                locationName = ""
            }
        }
        else {
            solarSystemName = ""
            locationName = location.structureName ?? NSLocalizedString("Unknown Location", comment: "")
        }
        
        self = Text(security).fontWeight(.bold).foregroundColor(.security(location.solarSystem?.security ?? 0)) + Text(solarSystemName).fontWeight(.bold) + Text(locationName)
    }
}

struct LocationLabel_Previews: PreviewProvider {
    static var previews: some View {
        try! Text(EVELocation(AppDelegate.sharedDelegate.persistentContainer.viewContext.from(SDEStaStation.self).first()!))
    }
}
