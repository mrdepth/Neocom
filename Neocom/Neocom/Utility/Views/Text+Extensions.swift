//
//  LocationLabel.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/12/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible
import Alamofire

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
    init(security: Float) {
        self = Text(String(format: "%.1f ", security)).foregroundColor(.security(security))
    }
    
    
    init(_ location: EVELocation) {
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
        
        self = ((location.solarSystem?.security).map{Text(security: $0) + Text(" ") } ?? Text("")) + Text(solarSystemName).fontWeight(.bold) + Text(locationName)
    }
	
	init(_ error: Error) {
		self = Text(error.localizedDescription).foregroundColor(.secondary)
	}
}

struct LocationLabel_Previews: PreviewProvider {
    static var previews: some View {
		VStack {
        try! Text(EVELocation(AppDelegate.sharedDelegate.persistentContainer.viewContext.from(SDEStaStation.self).first()!))
			Text(AFError.explicitlyCancelled)
		}
    }
}
