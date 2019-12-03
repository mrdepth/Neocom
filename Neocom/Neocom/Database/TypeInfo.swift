//
//  TypeInfo.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/2/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct TypeInfo: View {
    
    var type: SDEInvType
    var body: some View {
        List {
            Section {
                TypeInfoHeader(type: type, renderImage: Image("dominix")).listRowInsets(EdgeInsets())
            }
        }.listStyle(GroupedListStyle()).navigationBarTitle("Info")
    }
}

struct TypeInfo_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TypeInfo(type: try! AppDelegate.sharedDelegate.persistentContainer.viewContext.fetch(SDEInvType.dominix()).first!)
        }
    }
}

