//
//  NCActionHandler.swift
//  Neocom
//
//  Created by Artem Shimanski on 20.07.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import Foundation

extension UIControlEvents: Hashable {
	public var hashValue: Int {
		return rawValue.hashValue
	}
	
	static func == (lhs: UIControlEvents, rhs: UIControlEvents) -> Bool {
		return lhs.rawValue == rhs.rawValue
	}
}

class NCActionHandler {
	private let handler: NCOpaqueHandler
	private let control: UIControl
	private let controlEvents: UIControlEvents
	
	class NCOpaqueHandler: NSObject {
		let handler: (UIControl) -> Void
		
		init(_ handler: @escaping(UIControl) -> Void) {
			self.handler = handler
		}
		
		@objc func handle(_ sender: UIControl) {
			handler(sender)
		}
		
	}
	
	init(_ control: UIControl, for controlEvents: UIControlEvents, handler: @escaping(UIControl) -> Void) {
		self.handler = NCOpaqueHandler(handler)
		self.control = control
		self.controlEvents = controlEvents
		control.addTarget(self.handler, action: #selector(NCOpaqueHandler.handle(_:)), for: controlEvents)
	}
	
	deinit {
		control.removeTarget(self.handler, action: #selector(NCOpaqueHandler.handle(_:)), for: controlEvents)
	}
	
}
