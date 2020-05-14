//
//  ActivityIndicatorView.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/23/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct ActivityIndicatorView: UIViewRepresentable {
    var style: UIActivityIndicatorView.Style
    
    func makeUIView(context: UIViewRepresentableContext<ActivityIndicatorView>) -> UIActivityIndicatorView {
        let indicator = UIActivityIndicatorView(style: style)
        indicator.startAnimating()
        return indicator
    }
    
    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicatorView>) {
    }
    
    typealias UIViewType = UIActivityIndicatorView
    
    
}

struct ActivityIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityIndicatorView(style: .large)
    }
}
