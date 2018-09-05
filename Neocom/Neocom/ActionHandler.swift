//
//  ActionHandler.swift
//  Neocom
//
//  Created by Artem Shimanski on 05.09.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

extension UIControl.Event: Hashable {
	public var hashValue: Int {
		return rawValue.hashValue
	}
	
	static func == (lhs: UIControl.Event, rhs: UIControl.Event) -> Bool {
		return lhs.rawValue == rhs.rawValue
	}
}

class ActionHandler<Control: UIControl> {
	private let handler: OpaqueHandler
	private let control: Control
	private let controlEvents: UIControl.Event
	
	private class OpaqueHandler: NSObject {
		let handler: (Control) -> Void
		
		init(_ handler: @escaping(Control) -> Void) {
			self.handler = handler
		}
		
		@objc func handle(_ sender: UIControl) {
			guard let control = sender as? Control else {return}
			handler(control)
		}
		
	}
	
	init(_ control: Control, for controlEvents: UIControl.Event, handler: @escaping(Control) -> Void) {
		self.handler = OpaqueHandler(handler)
		self.control = control
		self.controlEvents = controlEvents
		control.addTarget(self.handler, action: #selector(OpaqueHandler.handle(_:)), for: controlEvents)
	}
	
	deinit {
		control.removeTarget(self.handler, action: #selector(OpaqueHandler.handle(_:)), for: controlEvents)
	}
	
}
