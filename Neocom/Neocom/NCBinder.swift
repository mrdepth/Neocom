//
//  NCBinder.swift
//  Neocom
//
//  Created by Artem Shimanski on 01.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import Foundation

struct NCBinding {
	unowned let target: AnyObject
	let observable: AnyObject
	let binding: String
	let keyPath: String
	let transformer: ValueTransformer?
}

public class NCBinder: NSObject {
	unowned let target: AnyObject
	var bindings: [String: NCBinding] = [:]
	
	public init(target: AnyObject) {
		self.target = target
		super.init()
	}
	
	deinit {
		unbindAll()
	}
	
	public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		guard let object = object as AnyObject?, let keyPath = keyPath else {return}
		for (_, value) in bindings {
			if value.observable === object as AnyObject && keyPath == value.keyPath {
				var v = object.value(forKeyPath: keyPath)
				if let transformer = value.transformer {
					v = transformer.transformedValue(v)
				}
				value.target.setValue(v, forKeyPath: value.binding)
				break
			}
		}
	}
	
	public func bind(_ binding: String, toObject observable: AnyObject, withKeyPath keyPath: String, transformer: ValueTransformer?) {
		self.bindings[binding] = NCBinding(target: target, observable: observable, binding: binding, keyPath: keyPath, transformer: transformer)
		observable.addObserver(self, forKeyPath: keyPath, options: [], context: nil)
		
		var value = observable.value(forKeyPath: keyPath)
		if let transformer = transformer {
			value = transformer.transformedValue(value)
		}
		self.target.setValue(value, forKeyPath: binding)
	}
	
	public func unbind(_ binding: String) {
		if let bind = bindings[binding] {
			bind.observable.removeObserver(self, forKeyPath: bind.keyPath)
			bindings[binding] = nil
		}
	}
	
	public func unbindAll() {
		let bindings = self.bindings
		for (key, _) in bindings {
			unbind(key)
		}
	}
}
