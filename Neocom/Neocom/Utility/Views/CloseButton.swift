//
//  CloseButton.swift
//  Neocom
//
//  Created by Artem Shimanski on 1/31/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct CloseButton: View {
    var action: () -> Void
    var body: some View {
        BarButtonItem(action: action) {
            Image(systemName: "xmark")
        }
    }
}

struct CloseButton_Previews: PreviewProvider {
    static var previews: some View {
        CloseButton {
            
        }
    }
}
