//
//  String+Extensions.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/25/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation
import UIKit

extension String {
    private static let roman = ["","I","II","III","IV","V"]

    init(roman number: Int) {
        if String.roman.indices.contains(number) {
            self = String.roman[number]
        }
        else {
            self = ""
        }
    }
}

extension NSAttributedString.Key {
    static let fontDescriptorSymbolicTraits = NSAttributedString.Key("UIFontDescriptorSymbolicTraits")
    static let colorName = NSAttributedString.Key("ColorName")
    static let recipientID = NSAttributedString.Key("RecipientID")
}

extension NSAttributedString {
    func extract(with font: UIFont, color: UIColor) -> NSAttributedString {
        let result = NSMutableAttributedString(string: string)
        
        enumerateAttributes(in: NSMakeRange(0, length), options: []) { (attributes, range, _) in
            var font = font
            var color = color
            for (key, value) in attributes {
                switch key {
                case .colorName:
                    guard let name = value as? String, let newColor = UIColor(named: name) else {break}
                    color = newColor
                case .fontDescriptorSymbolicTraits:
                    guard let traits = value as? UInt32, let fontDescriptor = font.fontDescriptor.withSymbolicTraits(UIFontDescriptor.SymbolicTraits(rawValue: traits)) else {break}
                    font = UIFont(descriptor: fontDescriptor, size: font.pointSize)
                default:
                    result.addAttribute(key, value: value, range: range)
                }
            }
            result.addAttributes([.font: font, .foregroundColor: color], range: range)
        }
        return result
    }
}
