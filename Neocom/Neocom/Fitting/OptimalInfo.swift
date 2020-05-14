//
//  OptimalInfo.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/5/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp

struct OptimalInfo: View {
    var optimal: DGMMeter
    var falloff: DGMMeter
    
    var body: some View {
        Group {
            if optimal > 0 {
                HStack(spacing: 0) {
                    Icon(Image("targetingRange"), size: .small)
                    if falloff > 0 {
                        Text(" optimal + falloff: ") +
                        Text(UnitFormatter.localizedString(from: optimal, unit: .meter, style: .long)).fontWeight(.semibold) +
                        Text(" + ") +
                        Text(UnitFormatter.localizedString(from: falloff, unit: .meter, style: .long)).fontWeight(.semibold)
                    }
                    else {
                        Text(" optimal: \(UnitFormatter.localizedString(from: optimal, unit: .meter, style: .long))")
                    }
                }
            }
        }
    }
}

struct OptimalInfo_Previews: PreviewProvider {
    static var previews: some View {
        OptimalInfo(optimal: 10000, falloff: 5000)
    }
}
