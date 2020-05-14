//
//  InfoButton.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/26/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct InfoButton: View {
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "info.circle").font(.title2).frame(width: 32, height: 32)
            .contentShape(Rectangle())
        }
    }
}

struct InfoButton_Previews: PreviewProvider {
    static var previews: some View {
        InfoButton {
        }
    }
}
