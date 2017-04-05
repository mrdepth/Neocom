//: Playground - noun: a place where people can play

import UIKit


var s = "0"

for i in 1...2 {
	print(s)
	defer {
		s = "\(i)"
	}
}