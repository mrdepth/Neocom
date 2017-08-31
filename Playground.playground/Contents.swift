//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport

var a: [Int] = [1,2,3,4,5,6,7]

let i = a.partition(by: {$0 % 2 == 0})
let b = a[0..<i]
a.removeSubrange(0..<i)


a
b

