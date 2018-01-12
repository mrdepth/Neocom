//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport
import CoreData

let url = URL(string: "nc://account?uuid=sdfsdfsdf")!

let components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
components.host
