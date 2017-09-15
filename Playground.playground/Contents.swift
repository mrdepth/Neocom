//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport

let d = [NSAttributedStringKey.font.rawValue: UIFont.systemFont(ofSize: 12)]

let d2 =  d.map {(NSAttributedStringKey(rawValue: $0), $1)}
