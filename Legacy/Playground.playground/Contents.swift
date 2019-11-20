//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport
import CoreData

enum Error1: Error {
	case a
}

enum Error2: Error {
	case b
	case c
}

let a: Result<Int, Error1> = .failure(Error1.a)


let b = a.mapError { error -> Error2 in
	print(error)
	return Error2.b
}

func f() throws -> Error {
//	throw Error2.b
	return Error2.c
}

let c = a.flatMapError { error -> Result<Int, Error> in
	return Result { throw try f() }
}

print(a, b, c)
