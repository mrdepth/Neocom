//
//  Combine.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/22/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation
import Combine

extension Publisher where Failure: Error {
    func asResult() -> Publishers.Catch<Publishers.Map<Self, Result<Self.Output, Self.Failure>>, Just<Result<Self.Output, Self.Failure>>> {
		return map{Result.success($0)}.catch{Just(Result.failure($0))}
    }
}

extension Publisher {
	func tryGet<S, F: Error>() -> Publishers.MapError<Publishers.TryMap<Self, S>, F> where Output == Result<S, F>, Failure == Never {
		tryMap {try $0.get()}.mapError{$0 as! F}
	}
}
