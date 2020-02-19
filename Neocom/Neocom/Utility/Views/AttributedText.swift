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
    
    init(_ text: NSAttributedString, preferredMaxLayoutWidth: CGFloat) {
        self.text = text
        self.preferredMaxLayoutWidth = preferredMaxLayoutWidth
    }

    var body: some View {
        AttributedTextView(text: text, preferredMaxLayoutWidth: preferredMaxLayoutWidth)
    }
}

fileprivate struct AttributedTextView: UIViewRepresentable {
    var text: NSAttributedString
    var preferredMaxLayoutWidth: CGFloat
    
    func makeUIView(context: UIViewRepresentableContext<AttributedTextView>) -> SelfSizedTextView {
        let view = SelfSizedTextView()
        view.attributedText = text
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isScrollEnabled = false
        view.backgroundColor = .clear
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.layoutManager.usesFontLeading = false
        view.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        view.setContentHuggingPriority(.defaultHigh, for: .vertical)
        view.isEditable = false
        return view
    }
    
    func updateUIView(_ uiView: SelfSizedTextView, context: UIViewRepresentableContext<AttributedTextView>) {
        uiView.attributedText = text
        uiView.style = .preferredMaxLayoutWidth(preferredMaxLayoutWidth)
    }
}

struct AttributedTextPreview: View {
    @State var text: NSAttributedString = NSAttributedString(string: repeatElement("Hello World ", count: 50).joined())
    var body: some View {
        GeometryReader { geometry in
            VStack {
                AttributedText(self.text, preferredMaxLayoutWidth: geometry.size.width - 30)
                .background(Color.gray)
            }.padding().background(Color.green)
        }
    }
}

struct AttributedText_Previews: PreviewProvider {
    static var previews: some View {
        AttributedTextPreview()
    }
}
