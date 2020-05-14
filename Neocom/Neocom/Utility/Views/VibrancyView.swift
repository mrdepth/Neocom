//
//  VibrancyView.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/30/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI

class VibrancyCoordinator<Content: View> {
    var controller: UIHostingController<Content>?
}

struct VibrancyView<Content: View>: UIViewRepresentable {
    var vibrancyStyle: UIVibrancyEffectStyle = .fill
    var blurStyle: UIBlurEffect.Style = .prominent
    var content: () -> Content
    
    
    init(@ViewBuilder _ content: @escaping () -> Content) {
        self.content = content
    }
    
    func makeCoordinator() -> VibrancyCoordinator<Content> {
        VibrancyCoordinator()
    }
    
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView {
        let controller = UIHostingController(rootView: content())
        context.coordinator.controller = controller

        let blurEffect = UIBlurEffect(style: blurStyle)
        let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect, style: vibrancyStyle)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        let vibrancyEffectView = UIVisualEffectView(effect: vibrancyEffect)


        vibrancyEffectView.contentView.addSubview(controller.view)
        blurEffectView.contentView.addSubview(vibrancyEffectView)
        
        vibrancyEffectView.frame = blurEffectView.bounds
        vibrancyEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        controller.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        controller.view.frame = vibrancyEffectView.bounds
        
        return blurEffectView
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) {
    }
}

struct VibrancyView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            List(0..<100, id: \.self) { _ in
                Color.red
            }
            VibrancyView {
                VStack {
                Image("turrets")
                Text("sdf").font(.title).bold().foregroundColor(.secondary)
                }
            }.frame(width: 128, height: 128)
        }
    }
}
