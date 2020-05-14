//
//  BlurView.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/30/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style = .prominent

    func makeUIView(context: UIViewRepresentableContext<BlurView>) -> UIView {
        let blurEffect = UIBlurEffect(style: style)
        let view = UIVisualEffectView(effect: blurEffect)
        return view
    }

    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<BlurView>) {
        
    }
}

struct BlurView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            List(0..<100, id: \.self) { _ in
                Color.red
            }
            
            BlurView().frame(width: 300, height: 300).cornerRadius(32)
            Text("Text")
        }
        
    }
}
