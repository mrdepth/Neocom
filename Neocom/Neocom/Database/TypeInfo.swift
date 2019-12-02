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
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct TypeInfo_Previews: PreviewProvider {
    static var previews: some View {
        TypeInfo(type: try! AppDelegate.sharedDelegate.persistentContainer.viewContext.fetch(SDEInvType.dominix()).first!)
    }
}
