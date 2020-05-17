//
//  TextView.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/18/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct TextView: View {
    enum Style {
        case `default`
        case preferredMaxLayoutWidth(CGFloat)
        case fixedLayoutWidth(CGFloat)
        
        var preferredMaxLayoutWidth: CGFloat? {
            guard case let .preferredMaxLayoutWidth(width) = self else {return nil}
            return width
        }
    }
    
    @Binding var text: NSAttributedString
    var selectedRange: Binding<NSRange>? = nil
    var typingAttributes: [NSAttributedString.Key: Any] = [:]
    var placeholder: NSAttributedString = NSAttributedString()
    var style: Style = .default
    var onBeginEditing: ((UITextView) -> Void)? = nil
    var onEndEditing: ((UITextView) -> Void)? = nil

    var body: some View {
        TextViewRepresentation(text: $text, selectedRange: selectedRange, typingAttributes: typingAttributes, placeholder: placeholder, style: style, onBeginEditing: onBeginEditing, onEndEditing: onEndEditing)
    }
    
}

private struct TextViewRepresentation: UIViewRepresentable {
    @Binding var text: NSAttributedString
    var selectedRange: Binding<NSRange>?
    var typingAttributes: [NSAttributedString.Key: Any]
    var placeholder: NSAttributedString
    var style: TextView.Style
    var onBeginEditing: ((UITextView) -> Void)?
    var onEndEditing: ((UITextView) -> Void)?

    class Coordinator: NSObject, UITextViewDelegate {
        var text: Binding<NSAttributedString>
        var selectedRange: Binding<NSRange>?
        var placeholder: NSAttributedString
        var typingAttributes: [NSAttributedString.Key: Any]
        var onBeginEditing: ((UITextView) -> Void)?
        var onEndEditing: ((UITextView) -> Void)?
        var textView: SelfSizedTextView?
        private var attachments = [TextAttachmentViewProtocol]()

        init(text: Binding<NSAttributedString>, selectedRange: Binding<NSRange>?, placeholder: NSAttributedString, typingAttributes: [NSAttributedString.Key: Any], onBeginEditing: ((UITextView) -> Void)?, onEndEditing: ((UITextView) -> Void)?) {
            self.text = text
            self.selectedRange = selectedRange
            self.placeholder = placeholder
            self.typingAttributes = typingAttributes
            self.onBeginEditing = onBeginEditing
            self.onEndEditing = onEndEditing
            super.init()
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
        
        @objc func keyboardWillChangeFrame(_ note: Notification) {
            guard let textView = textView else {return}
            guard let keyboardFrame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {return}
            guard let localFrame = textView.superview?.convert(textView.frame, to: nil) else {return}
            textView.contentInset.bottom = keyboardFrame.intersection(localFrame).height
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            textView.attributedText = text.wrappedValue
            textView.typingAttributes = typingAttributes
            onBeginEditing?(textView)
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            if text.wrappedValue.length == 0 {
                textView.attributedText = placeholder
            }
            onEndEditing?(textView)
        }
        
        func textViewDidChange(_ textView: UITextView) {
            text.wrappedValue = textView.attributedText//.copy() as! NSAttributedString
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            DispatchQueue.main.async {
                self.selectedRange?.wrappedValue = textView.selectedRange
            }
        }
    }

    func makeUIView(context: UIViewRepresentableContext<TextViewRepresentation>) -> SelfSizedTextView {
        let textView = SelfSizedTextView()
        textView.delegate = context.coordinator
        context.coordinator.textView = textView
        textView.typingAttributes = typingAttributes
        textView.style = style
        
        textView.attributedText = text
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.layoutManager.usesFontLeading = false
        textView.layoutManager.delegate = context.coordinator
        
        if case .default = style {
            textView.isScrollEnabled = true
        }
        else {
            textView.isScrollEnabled = false
            textView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            textView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        }
        return textView
    }
    
    func updateUIView(_ uiView: SelfSizedTextView, context: UIViewRepresentableContext<TextViewRepresentation>) {
        context.coordinator.text = $text
        context.coordinator.selectedRange = selectedRange
        func attributes() -> [NSAttributedString.Key: Any] {
            var attributes = self.typingAttributes
            attributes[.foregroundColor] = UIColor.secondaryLabel
            return attributes
        }
        
        if !uiView.isFirstResponder {
            uiView.attributedText = text.length > 0 ? text : placeholder
        }
        else if !uiView.attributedText.isEqual(to: text) {
            uiView.attributedText = text
        }
        uiView.typingAttributes = typingAttributes
        uiView.style = style
    }
    
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, selectedRange: selectedRange, placeholder: placeholder, typingAttributes: typingAttributes, onBeginEditing: onBeginEditing, onEndEditing: onEndEditing)
    }
    
}

struct TextViewPreview: View {
    @State var text: NSAttributedString = NSAttributedString(string: "")
    var body: some View {
        GeometryReader { geometry in
            VStack {
                TextView(text: self.$text, placeholder: NSAttributedString(string: "Placeholder", attributes: [.foregroundColor: UIColor.secondaryLabel]))
                .background(Color.gray)
            }.padding().background(Color.green)
        }
    }
}

struct TextView_Previews: PreviewProvider {
    static var previews: some View {
        TextViewPreview()
    }
}

class SelfSizedTextView: UITextView {
    var style: TextView.Style = .default
    
    override var intrinsicContentSize: CGSize {
        switch style {
        case .default:
            return super.intrinsicContentSize
        case let .preferredMaxLayoutWidth(width):
            return sizeThatFits(CGSize(width: width, height: .infinity))
        case let .fixedLayoutWidth(width):
            var size = sizeThatFits(CGSize(width: width, height: .infinity))
            size.width = width
            size.height = max(size.height, 24)
            return size
        }
    }
}

extension TextViewRepresentation.Coordinator: NSLayoutManagerDelegate {
    func layoutManager(_ layoutManager: NSLayoutManager, didCompleteLayoutFor textContainer: NSTextContainer?, atEnd layoutFinishedFlag: Bool) {
        guard let textView = textView else {return}
        let storage = textView.textStorage
        
        var currentAttachments = [TextAttachmentViewProtocol]()
        storage.enumerateAttribute(.attachment, in: NSRange(location: 0, length: storage.length)) { value, range, _ in
            guard let attachment = value as? NSTextAttachment & TextAttachmentViewProtocol else {return}
            currentAttachments.append(attachment)
            if !attachments.contains(where: {$0 === attachment}) {
                textView.addSubview(attachment.view)
            }
            attachment.view.frame = layoutManager.boundingRect(forGlyphRange: range, in: textView.textContainer).inset(by: -attachment.insets)
        }
        for attachment in attachments {
            if (!currentAttachments.contains(where: {$0 === attachment})) {
                attachment.view.removeFromSuperview()
            }
        }
        attachments = currentAttachments
    }
}
