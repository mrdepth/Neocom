//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport
import CoreData

var a = [true, true, false, true, false]

let i = a.partition(by: {$0})

print(a)
