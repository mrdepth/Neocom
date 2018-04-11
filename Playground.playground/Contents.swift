//: Playground - noun: a place where people can play

import UIKit
import EVEAPI
import PlaygroundSupport

var a = -0.0
var b = 0.0

withUnsafeBytes(of: &a) {Data.init(buffer: $0)}
withUnsafePointer(to: &a) {Data.init(buffer: a)}
