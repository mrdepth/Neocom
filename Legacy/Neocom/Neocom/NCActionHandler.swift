//
//  NCActionHandler.swift
//  Neocom
//
//  Created by Artem Shimanski on 20.07.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import Foundation

extension UIControlEvents: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
	
	static func == (lhs: UIControlEvents, rhs: UIControlEvents) -> Bool {
		return lhs.rawValue == rhs.rawValue
	}
}

class NCActionHandler<Control: UIControl> {
	private let handler: NCOpaqueHandler
	private let control: Control
	private let controlEvents: UIControlEvents
	
	class NCOpaqueHandler: NSObject {
		let handler: (Control) -> Void
		
		init(_ handler: @escaping(Control) -> Void) {
			self.handler = handler
		}
		
		@objc func handle(_ sender: UIControl) {
			guard let control = sender as? Control else {return}
			handler(control)
		}
		
	}
	
	init(_ control: Control, for controlEvents: UIControlEvents, handler: @escaping(Control) -> Void) {
		self.handler = NCOpaqueHandler(handler)
		self.control = control
		self.controlEvents = controlEvents
		control.addTarget(self.handler, action: #selector(NCOpaqueHandler.handle(_:)), for: controlEvents)
	}
	
	deinit {
		control.removeTarget(self.handler, action: #selector(NCOpaqueHandler.handle(_:)), for: controlEvents)
	}
	
}
