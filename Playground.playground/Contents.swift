//: Playground - noun: a place where people can play

import UIKit


var c = NSURLComponents(string: "http://google.com")
c?.queryItems = [URLQueryItem(name: "test", value: "/\\sdfwe&?")]

let i: Any = "wef"
String(describing: i)