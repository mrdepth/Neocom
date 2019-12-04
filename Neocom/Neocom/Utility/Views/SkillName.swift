//
//  SkillName.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/4/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct SkillName: View {
    private let name: String
    private let level: Int
    init(name: String, level: Int) {
        self.name = name
        self.level = level
    }
    var body: some View {
        Text(name + " ") + Text(String(roman: level)).foregroundColor(Color.skyBlue).fontWeight(.medium)
    }
}

struct SkillName_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            SkillName(name: "Battleships", level: 5).padding().background(Color(.systemBackground)).colorScheme(.light)
            SkillName(name: "Battleships", level: 5).padding().background(Color(.systemBackground)).colorScheme(.dark)
        }
    }
}
