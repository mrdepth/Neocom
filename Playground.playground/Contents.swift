//: Playground - noun: a place where people can play

import UIKit


var a: [Int] = [1,2,3,4028423434534534533]
let b = a as NSArray

b.filtered(using: NSPredicate(format: "self == %qi", 4028423434534534533))
