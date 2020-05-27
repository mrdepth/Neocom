//
//  TutorialContinue.swift
//  Neocom
//
//  Created by Artem Shimanski on 5/22/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct TutorialButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.foregroundColor(.white)
        .frame(maxWidth: 320)
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).foregroundColor(.skyBlue))
    }
}

struct TutorialContinue_Previews: PreviewProvider {
    static var previews: some View {
        Text("Continue").modifier(TutorialButtonModifier())
    }
}
