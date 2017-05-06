//: Playground - noun: a place where people can play

import UIKit

var a = [1: [1,2,3,4,5]]

_ = (a[2]?.append(1)) ?? (a[2] = [1])

a