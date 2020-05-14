//
//  UIKit+Extensions.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/26/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import UIKit

extension UIApplication {
    func endEditing(_ force: Bool) {
        self.windows.first{$0.isKeyWindow}?.endEditing(force)
    }
}


extension Notification.Name {
    static let didUpdateSkillPlan = Notification.Name(rawValue: "com.shimanski.neocom.didUpdateSkillPlan")
}

extension NSAttributedString {
    var attachments: [NSRange: NSTextAttachment] {
        var result = [NSRange: NSTextAttachment]()
        enumerateAttribute(.attachment, in: NSRange(location: 0, length: length), options: []) { value, range, _ in
            guard let attachment = value as? NSTextAttachment else {return}
            result[range] = attachment
        }
        return result
    }
}

extension UIBezierPath {
    convenience init(points: [CGPoint]) {
        self.init()
        guard !points.isEmpty else {return}
        move(to: points[0])
        points.dropFirst().forEach { addLine(to: $0) }
    }
}

extension UIViewController {
    var topMostPresentedViewController: UIViewController {
        return presentedViewController?.topMostPresentedViewController ?? self
    }
}

extension UIAlertController {
    convenience init(title: String? = NSLocalizedString("Error", comment: ""), error: Error, handler: ((UIAlertAction) -> Void)? = nil) {
        self.init(title: title, message: error.localizedDescription, preferredStyle: .alert)
        self.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .default, handler: handler))
    }
}
