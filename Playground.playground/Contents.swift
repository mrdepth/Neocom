//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport

var work = DispatchWorkItem {
	print("A")
}

DispatchQueue.main.async(execute: work)
//work.cancel()

work = DispatchWorkItem {
	print("B")
}

DispatchQueue.main.async(execute: work)

PlaygroundPage.current.needsIndefiniteExecution = true