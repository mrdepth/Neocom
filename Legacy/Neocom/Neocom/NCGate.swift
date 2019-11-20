//
//  NCGate.swift
//  Neocom
//
//  Created by Artem Shimanski on 08.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI

class NCGate {
	private lazy var dispatchQueue: DispatchQueue = DispatchQueue(label: "NCGate")
	
	init() {
		
	}
	
	private var block: (() -> Void)?
	private var executing: Bool = false
	
	func perform(block: @escaping () -> Void) {
		synchronized (self) {
			if (self.executing) {
				self.block = block
			}
			else {
				self.executing = true
				self.block = nil;
				self.dispatchQueue.async {
					autoreleasepool {
						block()
						DispatchQueue.main.async {
							synchronized (self) {
								self.executing = false
								if let block = self.block {
									self.perform(block: block)
								}
							}
						}
					}
				}
			}
		}
	}
	
}
