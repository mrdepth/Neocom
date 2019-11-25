//
//  AccountCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/25/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI

struct AccountCell: View {
    var account: Account
    var esi: ESI
    
    var body: some View {
        Text("sdf")
    }
}

struct AccountCell_Previews: PreviewProvider {
    static var previews: some View {
        AccountCell(account: Account(), esi: ESI())
    }
}
