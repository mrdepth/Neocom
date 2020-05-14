//
//  ZKillboardItem.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/6/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct ZKillboardItem: View {
    var body: some View {
        NavigationLink(destination: ZKillboardSearchForm()) {
            Icon(Image("killrights"))
            Text("zKillboard Reports")
        }
    }
}

struct ZKillboardItem_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                ZKillboardItem()
            }.listStyle(GroupedListStyle())
        }
    }
}
