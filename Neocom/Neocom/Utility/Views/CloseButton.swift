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
        Button(action: action) {
            Image(systemName: "xmark").frame(width: 30, height: 30)
                .background(Circle().foregroundColor(Color(.tertiarySystemFill)))
        }
    }
}

struct CloseButton_Previews: PreviewProvider {
    static var previews: some View {
        CloseButton {
            
        }
    }
}
