//: Playground - noun: a place where people can play

import UIKit

let expression = try! NSRegularExpression(pattern: "<i[^>]*>(.*?)</i>", options: [.caseInsensitive, .dotMatchesLineSeparators])

let s = "From the formless void's gaping maw, there springs an entity.\r\n\r\n<i>-Dr. Damella Macaper,\r\nThe Seven Events of the Apocalypse</i>"

expression.matches(in: s, options: [], range: NSMakeRange(0, s.utf8.count))

var indexes = IndexSet()

indexes.insert(0)
indexes.insert(3)
indexes.insert(2)
indexes.insert(5)
indexes.insert(1)

for i in indexes.reversed() {
	print (String(i))
}
