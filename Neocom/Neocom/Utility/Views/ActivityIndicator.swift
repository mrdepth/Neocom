//
//  ActivityIndicator.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/23/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct ActivityIndicator: UIViewRepresentable {
    var style: UIActivityIndicatorView.Style
    
    func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
        let indicator = UIActivityIndicatorView(style: style)
        indicator.startAnimating()
        return indicator
    }
    
    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>) {
    }
    
    typealias UIViewType = UIActivityIndicatorView
    
    
}

struct ActivityIndicator_Previews: PreviewProvider {
    static var previews: some View {
        ActivityIndicator(style: .large)
    }
}
