//
//  TextAttachmentView.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/19/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

protocol TextAttachmentViewProtocol: AnyObject {
    var view: UIView {get}
    var insets: UIEdgeInsets {get}
}

class TextAttachmentView<Content: View>: NSTextAttachment, TextAttachmentViewProtocol {
    let controller: UIHostingController<Content>
    
    var insets: UIEdgeInsets {
        return .zero
    }
    
    var view: UIView {
        return controller.view
    }
    
    init(rootView: Content) {
        controller = UIHostingController(rootView: rootView)
        controller.view.backgroundColor = .clear
        super.init(data: nil, ofType: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        let size = controller.sizeThatFits(in: CGRect.infinite.size)
        var rect = CGRect(origin: .zero, size: size)
        rect.origin.y = (lineFrag.height - rect.size.height) / 2
        return rect.inset(by: insets)
    }
    
    override func image(forBounds imageBounds: CGRect, textContainer: NSTextContainer?, characterIndex charIndex: Int) -> UIImage? {
        return nil
    }
}

