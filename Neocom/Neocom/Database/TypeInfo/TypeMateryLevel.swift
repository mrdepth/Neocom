//
//  TypeMateryLevel.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/6/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct TypeMateryLevel: View {
    var type: SDEInvType
    var level: SDECertMasteryLevel
    var pilot: Pilot?
    var mastery: Lazy<MasteryData> = Lazy()
    
    var body: some View {
        let mastery = self.mastery.get(initial: MasteryData(for: type, with: level, pilot: pilot))
        
        return List {
            ForEach(mastery.sections) { section in
                HStack {
                    section.image.font(.caption).foregroundColor(Color(section.color))
                    VStack(alignment: .leading) {
                        Text(section.title)
                        section.subtitle.map{Text($0).foregroundColor(.secondary)}
                    }.font(.footnote)
                }
            }
        }.listStyle(GroupedListStyle())
            .navigationBarTitle(level.displayName?.capitalized ?? (NSLocalizedString("Level", comment: "") + " " + String(roman: Int(level.level + 1))))
    }
}

struct TypeMateryLevel_Previews: PreviewProvider {
    static var previews: some View {
        let type = SDEInvType.dominix
        let level = ((type.certificates?.anyObject() as? SDECertCertificate)?.masteries?.firstObject as? SDECertMastery)?.level
        return NavigationView {
            TypeMateryLevel(type: type, level: level!, pilot: nil)
        }
    }
}
