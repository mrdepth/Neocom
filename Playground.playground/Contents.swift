//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport

var a = [0,1,2,3,4,5]

a[6..<6] = [6,7,8]
//a.replaceSubrange(6..<6, with: [6,7,8])

print("\(a)")