//
//  AttributedText.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/3/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct AttributedText: View {
    private var text: NSAttributedString
    private var preferredMaxLayoutWidth: CGFloat
//    @State var height: CGFloat = 24
    
    init(_ text: NSAttributedString, preferredMaxLayoutWidth: CGFloat) {
        self.text = text
        self.preferredMaxLayoutWidth = preferredMaxLayoutWidth
    }
    
    var body: some View {
        TextView(text: self.text, preferredMaxLayoutWidth: preferredMaxLayoutWidth)
//        GeometryReader { geometry in
//            TextView(text: self.text, preferredMaxLayoutWidth: geometry.size.width).anchorPreference(key: SizePreferenceKey.self, value: Anchor<CGRect>.Source.bounds) {[geometry[$0].size]}
//        }.frame(height: height).onPreferenceChange(SizePreferenceKey.self) {
//            guard let height = $0.first?.height else {return}
//            self.height = height
//        }
    }
}

fileprivate struct TextView: UIViewRepresentable {
    var text: NSAttributedString
    var preferredMaxLayoutWidth: CGFloat
    
    func makeUIView(context: UIViewRepresentableContext<TextView>) -> TextViewRepresentation {
        let view = TextViewRepresentation()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isScrollEnabled = false
        view.backgroundColor = .clear
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.layoutManager.usesFontLeading = false
        view.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        view.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return view
    }
    
    func updateUIView(_ uiView: TextViewRepresentation, context: UIViewRepresentableContext<TextView>) {
        uiView.attributedText = text
        uiView.preferredMaxLayoutWidth = preferredMaxLayoutWidth
    }
}

struct AttributedText_Previews: PreviewProvider {
    static var previews: some View {
        GeometryReader { geometry in
            VStack {
                AttributedText(NSAttributedString(string: repeatElement("Hello World ", count: 50).joined()), preferredMaxLayoutWidth: geometry.size.width - 30)
                .background(Color.gray)
            }.padding().background(Color.green)
        }
    }
}

fileprivate class TextViewRepresentation: UITextView {
    var preferredMaxLayoutWidth: CGFloat = .infinity
    
    override var intrinsicContentSize: CGSize {
        sizeThatFits(CGSize(width: preferredMaxLayoutWidth, height: .infinity))
    }
}
