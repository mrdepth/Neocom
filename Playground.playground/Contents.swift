//: Playground - noun: a place where people can play

import UIKit

var a = [1,1,0,0,0,0,1,1,1]

let b = a.partition { (i) -> Bool in
	return i == 1
}
a
b