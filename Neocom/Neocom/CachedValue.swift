//
//  CachedValue.swift
//  Neocom
//
//  Created by Artem Shimanski on 24.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import CloudData
import CoreData

protocol CachedValueProtocol: class {
	associatedtype Value
	var value: Value {get set}
	var cachedUntil: Date? {get set}
	var observer: APIObserver<Self>? {get}
}

final class CachedValue<Value>: CachedValueProtocol {
	var value: Value
	var cachedUntil: Date?
	let observer: APIObserver<CachedValue<Value>>?
	
	init(value: Value, cachedUntil: Date?, observer: APIObserver<CachedValue<Value>>?) {
		self.value = value
		self.cachedUntil = cachedUntil
		self.observer = observer
		observer?.cachedValue = self
	}
	
	func map<T>(_ transform: @escaping (Value) throws -> T ) rethrows -> CachedValue<T> {
		return try CachedValue<T>(value: transform(value), cachedUntil: cachedUntil, observer: observer?.map(transform))
	}
}

class APIObserver<Value: CachedValueProtocol> {
	
	var handler: ((Value) -> Void)?
	weak var cachedValue: Value?
	
	func map<T>(_ transform: @escaping (Value.Value) throws -> T ) -> APIObserverMap<CachedValue<T>, Value> {
		return APIObserverMap(self, transform: transform)
	}
	
	func notify(newValue: Value.Value, cachedUntil: Date?) {
		if let handler = handler, let cachedValue = cachedValue {
			cachedValue.value = newValue
			cachedValue.cachedUntil = cachedUntil
			handler(cachedValue)
		}
	}
}

class APICacheRecordObserver<Value: CachedValueProtocol>: APIObserver<Value> where Value.Value: Codable {
	let recordID: NSManagedObjectID?
	let dataID: NSManagedObjectID?
	let cache: Cache
	
	init(cacheRecord: CacheRecord, cache: Cache) {
		self.cache = cache
		recordID = cacheRecord.objectID
		dataID = cacheRecord.data?.objectID
	}
	
	override var handler: ((Value) -> Void)? {
		didSet {
			if observer == nil {
				observer = NotificationCenter.default.addNotificationObserver(forName: .NSManagedObjectContextDidSave, object: nil, queue: nil, using: { [weak self] note in
					self?.didSave(note)
				})
			}
		}
	}
	
	private var observer: NotificationObserver?
	
	private func didSave(_ note: Notification) {
		guard let objectIDs = (note.userInfo?[NSUpdatedObjectsKey] as? NSSet)?.compactMap ({ ($0 as? NSManagedObject)?.objectID ?? $0 as? NSManagedObjectID }) else {return}
		guard !Set(objectIDs).intersection([recordID, dataID].compactMap{$0}).isEmpty else {return}
		cache.performBackgroundTask { context -> Void in
			guard let recordID = self.recordID else {return}
			guard let record: CacheRecord = (try? context.existingObject(with: recordID)) ?? nil else {return}
			guard let value: Value.Value = record.getValue() else {return}
			self.notify(newValue: value, cachedUntil: record.cachedUntil)
		}
	}
}

class APIObserverMap<Value: CachedValueProtocol, Base: CachedValueProtocol>: APIObserver<Value> {
	let base: APIObserver<Base>
	let transform: (Base.Value) throws -> Value.Value
	
	override var handler: ((Value) -> Void)? {
		didSet {
			if handler == nil {
				base.handler = nil
			}
			else {
				base.handler = { [weak self] newValue in
					guard let strongSelf = self else {return}
					try? strongSelf.notify(newValue: strongSelf.transform(newValue.value), cachedUntil: newValue.cachedUntil)
				}
			}
		}
	}
	
	init(_ base: APIObserver<Base>, transform: @escaping (Base.Value) throws -> Value.Value ) {
		self.base = base
		self.transform = transform
		super.init()
	}
}

func all<R, A, B>(_ a: CachedValue<A>, _ b: CachedValue<B>) -> Join2<R, A, B> {
	return Join2(a: a, b: b)
}

func all<R, A, B, C>(_ a: CachedValue<A>, _ b: CachedValue<B>, _ c: CachedValue<C>) -> Join3<R, A, B, C> {
	return Join3(a: a, b: b, c: c)
}

func all<R, A, B, C, D>(_ a: CachedValue<A>, _ b: CachedValue<B>, _ c: CachedValue<C>, _ d: CachedValue<D>) -> Join4<R, A, B, C, D> {
	return Join4(a: a, b: b, c: c, d: d)
}

func all<R, A, B, C, D, E>(_ a: CachedValue<A>, _ b: CachedValue<B>, _ c: CachedValue<C>, _ d: CachedValue<D>, _ e: CachedValue<E>) -> Join5<R, A, B, C, D, E> {
	return Join5(a: a, b: b, c: c, d: d, e: e)
}

func all<R, A, B, C, D, E, F>(_ a: CachedValue<A>, _ b: CachedValue<B>, _ c: CachedValue<C>, _ d: CachedValue<D>, _ e: CachedValue<E>, _ f: CachedValue<F>) -> Join6<R, A, B, C, D, E, F> {
	return Join6(a: a, b: b, c: c, d: d, e: e, f: f)
}

func all<R, A, B>(_ values: (CachedValue<A>, CachedValue<B>)) -> Join2<R, A, B> {
	return Join2(a: values.0, b: values.1)
}

func all<R, A, B, C>(_ values: (CachedValue<A>, CachedValue<B>, CachedValue<C>)) -> Join3<R, A, B, C> {
	return Join3(a: values.0, b: values.1, c: values.2)
}

func all<R, A, B, C, D>(_ values: (CachedValue<A>, CachedValue<B>, CachedValue<C>, CachedValue<D>)) -> Join4<R, A, B, C, D> {
	return Join4(a: values.0, b: values.1, c: values.2, d: values.3)
}

func all<R, A, B, C, D, E>(_ values: (CachedValue<A>, CachedValue<B>, CachedValue<C>, CachedValue<D>, CachedValue<E>)) -> Join5<R, A, B, C, D, E> {
	return Join5(a: values.0, b: values.1, c: values.2, d: values.3, e: values.4)
}

func all<R, A, B, C, D, E, F>(_ values: (CachedValue<A>, CachedValue<B>, CachedValue<C>, CachedValue<D>, CachedValue<E>, CachedValue<F>)) -> Join6<R, A, B, C, D, E, F> {
	return Join6(a: values.0, b: values.1, c: values.2, d: values.3, e: values.4, f: values.5)
}

struct Join2<R, A, B> {
	var a: CachedValue<A>
	var b: CachedValue<B>
	
	func map(_ transform: @escaping (A, B) -> R) -> CachedValue<R> {
		
		
		let cachedUntil = [a.cachedUntil, b.cachedUntil].compactMap{$0}.min()
		let value = transform(a.value, b.value)
		let observer = APIObserverJoin<CachedValue<R>>(values: [AnyCachedValue(a),
																AnyCachedValue(b)]) {transform($0[0] as! A,
																							   $0[1] as! B)}
		return CachedValue(value: value, cachedUntil: cachedUntil, observer: observer)
	}
}

struct Join3<R, A, B, C> {
	var a: CachedValue<A>
	var b: CachedValue<B>
	var c: CachedValue<C>
	
	func map(_ transform: @escaping (A, B, C) -> R) -> CachedValue<R> {
		let cachedUntil = [a.cachedUntil, b.cachedUntil, c.cachedUntil].compactMap{$0}.min()
		let value = transform(a.value, b.value, c.value)
		let observer = APIObserverJoin<CachedValue<R>>(values: [AnyCachedValue(a),
																AnyCachedValue(b),
																AnyCachedValue(c)]) {transform($0[0] as! A,
																							   $0[1] as! B,
																							   $0[2] as! C)}
		return CachedValue(value: value, cachedUntil: cachedUntil, observer: observer)
	}
}

struct Join4<R, A, B, C, D> {
	var a: CachedValue<A>
	var b: CachedValue<B>
	var c: CachedValue<C>
	var d: CachedValue<D>
	
	func map(_ transform: @escaping (A, B, C, D) -> R) -> CachedValue<R> {
		let cachedUntil = [a.cachedUntil, b.cachedUntil, c.cachedUntil, d.cachedUntil].compactMap{$0}.min()
		let value = transform(a.value, b.value, c.value, d.value)
		let observer = APIObserverJoin<CachedValue<R>>(values: [AnyCachedValue(a),
																AnyCachedValue(b),
																AnyCachedValue(c),
																AnyCachedValue(d)]) {transform($0[0] as! A,
																							   $0[1] as! B,
																							   $0[2] as! C,
																							   $0[3] as! D)}
		return CachedValue(value: value, cachedUntil: cachedUntil, observer: observer)
	}
}

struct Join5<R, A, B, C, D, E> {
	var a: CachedValue<A>
	var b: CachedValue<B>
	var c: CachedValue<C>
	var d: CachedValue<D>
	var e: CachedValue<E>
	
	func map(_ transform: @escaping (A, B, C, D, E) -> R) -> CachedValue<R> {
		let cachedUntil = [a.cachedUntil, b.cachedUntil, c.cachedUntil, d.cachedUntil, e.cachedUntil].compactMap{$0}.min()
		let value = transform(a.value, b.value, c.value, d.value, e.value)
		let observer = APIObserverJoin<CachedValue<R>>(values: [AnyCachedValue(a),
																AnyCachedValue(b),
																AnyCachedValue(c),
																AnyCachedValue(d),
																AnyCachedValue(e)]) {transform($0[0] as! A,
																							   $0[1] as! B,
																							   $0[2] as! C,
																							   $0[3] as! D,
																							   $0[4] as! E)}
		return CachedValue(value: value, cachedUntil: cachedUntil, observer: observer)
	}
}

struct Join6<R, A, B, C, D, E, F> {
	var a: CachedValue<A>
	var b: CachedValue<B>
	var c: CachedValue<C>
	var d: CachedValue<D>
	var e: CachedValue<E>
	var f: CachedValue<F>
	
	func map(_ transform: @escaping (A, B, C, D, E, F) -> R) -> CachedValue<R> {
		let cachedUntil = [a.cachedUntil, b.cachedUntil, c.cachedUntil, d.cachedUntil, e.cachedUntil, f.cachedUntil].compactMap{$0}.min()
		let value = transform(a.value, b.value, c.value, d.value, e.value, f.value)
		let observer = APIObserverJoin<CachedValue<R>>(values: [AnyCachedValue(a),
																AnyCachedValue(b),
																AnyCachedValue(c),
																AnyCachedValue(d),
																AnyCachedValue(e),
																AnyCachedValue(f)]) {transform($0[0] as! A,
																							   $0[1] as! B,
																							   $0[2] as! C,
																							   $0[3] as! D,
																							   $0[4] as! E,
																							   $0[5] as! F)}
		return CachedValue(value: value, cachedUntil: cachedUntil, observer: observer)
	}
}

protocol CachedValueBox {
	func setHandler(_ handler: ((AnyCachedValue) -> Void)?)
	func unbox<T: CachedValueProtocol>() -> T?
	var cachedUntil: Date? {get}
	var value: Any {get}
}

struct ConcreteCachedValueBox<Base: CachedValueProtocol>: CachedValueBox {
	var base: Base
	
	func setHandler(_ handler: ((AnyCachedValue) -> Void)?) {
		if let handler = handler {
			base.observer?.handler = { newValue in
				handler(AnyCachedValue(newValue))
			}
		}
		else {
			base.observer?.handler = nil
		}
	}
	
	func unbox<T: CachedValueProtocol>() -> T? {
		return base as? T
	}
	
	var cachedUntil: Date? {
		return base.cachedUntil
	}
	
	var value: Any {
		return base.value
	}
}

struct AnyCachedValue {
	fileprivate var box: CachedValueBox
	
	var cachedUntil: Date? {
		return box.cachedUntil
	}
	
	var value: Any {
		return box.value
	}
	
	init<T: CachedValueProtocol>(_ base: T) {
		box = ConcreteCachedValueBox(base: base)
	}
	
	func setHandler(_ handler: ((AnyCachedValue) -> Void)?) {
		box.setHandler(handler)
	}
}

class APIObserverJoin<Value: CachedValueProtocol>: APIObserver<Value> {
	var values: [AnyCachedValue]
	let transform: ([Any]) -> Value.Value

	init(values: [AnyCachedValue], transform: @escaping ([Any]) -> Value.Value ) {
		self.values = values
		self.transform = transform
	}
	
	override var handler: ((Value) -> Void)? {
		didSet {
			if handler == nil {
				for value in values {
					value.setHandler(nil)
				}
			}
			else {
				for value in values {
					value.setHandler { [weak self] newValue in
						self?.notify()
					}
				}
			}
		}
	}
	
	func notify() {
		notify(newValue: transform(values.map{$0.value}), cachedUntil: values.compactMap{$0.cachedUntil}.min())
	}
}

func all<R, A, B>(_ a: CachedValue<A>?, _ b: CachedValue<B>?) -> OptionalJoin2<R, A, B> {
	return OptionalJoin2(a: a, b: b)
}

func all<R, A, B, C>(_ a: CachedValue<A>?, _ b: CachedValue<B>?, _ c: CachedValue<C>?) -> OptionalJoin3<R, A, B, C> {
	return OptionalJoin3(a: a, b: b, c: c)
}

func all<R, A, B, C, D>(_ a: CachedValue<A>?, _ b: CachedValue<B>?, _ c: CachedValue<C>?, _ d: CachedValue<D>?) -> OptionalJoin4<R, A, B, C, D> {
	return OptionalJoin4(a: a, b: b, c: c, d: d)
}

func all<R, A, B, C, D, E>(_ a: CachedValue<A>?, _ b: CachedValue<B>?, _ c: CachedValue<C>?, _ d: CachedValue<D>?, _ e: CachedValue<E>?) -> OptionalJoin5<R, A, B, C, D, E> {
	return OptionalJoin5(a: a, b: b, c: c, d: d, e: e)
}

func all<R, A, B, C, D, E, F>(_ a: CachedValue<A>?, _ b: CachedValue<B>?, _ c: CachedValue<C>?, _ d: CachedValue<D>?, _ e: CachedValue<E>?, _ f: CachedValue<F>?) -> OptionalJoin6<R, A, B, C, D, E, F> {
	return OptionalJoin6(a: a, b: b, c: c, d: d, e: e, f: f)
}

func all<R, A, B>(_ values: (CachedValue<A>?, CachedValue<B>?)) -> OptionalJoin2<R, A, B> {
	return OptionalJoin2(a: values.0, b: values.1)
}

func all<R, A, B, C>(_ values: (CachedValue<A>?, CachedValue<B>?, CachedValue<C>?)) -> OptionalJoin3<R, A, B, C> {
	return OptionalJoin3(a: values.0, b: values.1, c: values.2)
}

func all<R, A, B, C, D>(_ values: (CachedValue<A>?, CachedValue<B>?, CachedValue<C>?, CachedValue<D>?)) -> OptionalJoin4<R, A, B, C, D> {
	return OptionalJoin4(a: values.0, b: values.1, c: values.2, d: values.3)
}

func all<R, A, B, C, D, E>(_ values: (CachedValue<A>?, CachedValue<B>?, CachedValue<C>?, CachedValue<D>?, CachedValue<E>?)) -> OptionalJoin5<R, A, B, C, D, E> {
	return OptionalJoin5(a: values.0, b: values.1, c: values.2, d: values.3, e: values.4)
}

func all<R, A, B, C, D, E, F>(_ values: (CachedValue<A>?, CachedValue<B>?, CachedValue<C>?, CachedValue<D>?, CachedValue<E>?, CachedValue<F>?)) -> OptionalJoin6<R, A, B, C, D, E, F> {
	return OptionalJoin6(a: values.0, b: values.1, c: values.2, d: values.3, e: values.4, f: values.5)
}

struct OptionalJoin2<R, A, B> {
	var a: CachedValue<A>?
	var b: CachedValue<B>?
	
	func map(_ transform: @escaping (A?, B?) -> R) -> CachedValue<R> {
		
		
		let cachedUntil = [a?.cachedUntil, b?.cachedUntil].compactMap{$0}.min()
		let value = transform(a?.value, b?.value)
		let observer = APIObserverOptionalJoin<CachedValue<R>>(values: [a.map {AnyCachedValue($0)},
																		b.map {AnyCachedValue($0)}]) {transform($0[0] as? A,
																												$0[1] as? B)}
		return CachedValue(value: value, cachedUntil: cachedUntil, observer: observer)
	}
}

struct OptionalJoin3<R, A, B, C> {
	var a: CachedValue<A>?
	var b: CachedValue<B>?
	var c: CachedValue<C>?
	
	func map(_ transform: @escaping (A?, B?, C?) -> R) -> CachedValue<R> {
		let cachedUntil = [a?.cachedUntil, b?.cachedUntil, c?.cachedUntil].compactMap{$0}.min()
		let value = transform(a?.value, b?.value, c?.value)
		let observer = APIObserverOptionalJoin<CachedValue<R>>(values: [a.map {AnyCachedValue($0)},
																		b.map {AnyCachedValue($0)},
																		c.map {AnyCachedValue($0)}]) {transform($0[0] as? A,
																												$0[1] as? B,
																												$0[2] as? C)}
		return CachedValue(value: value, cachedUntil: cachedUntil, observer: observer)
	}
}

struct OptionalJoin4<R, A, B, C, D> {
	var a: CachedValue<A>?
	var b: CachedValue<B>?
	var c: CachedValue<C>?
	var d: CachedValue<D>?
	
	func map(_ transform: @escaping (A?, B?, C?, D?) -> R) -> CachedValue<R> {
		let cachedUntil = [a?.cachedUntil, b?.cachedUntil, c?.cachedUntil, d?.cachedUntil].compactMap{$0}.min()
		let value = transform(a?.value, b?.value, c?.value, d?.value)
		let observer = APIObserverOptionalJoin<CachedValue<R>>(values: [a.map {AnyCachedValue($0)},
																		b.map {AnyCachedValue($0)},
																		c.map {AnyCachedValue($0)},
																		d.map {AnyCachedValue($0)}]) {transform($0[0] as? A,
																												$0[1] as? B,
																												$0[2] as? C,
																												$0[3] as? D)}
		return CachedValue(value: value, cachedUntil: cachedUntil, observer: observer)
	}
}

struct OptionalJoin5<R, A, B, C, D, E> {
	var a: CachedValue<A>?
	var b: CachedValue<B>?
	var c: CachedValue<C>?
	var d: CachedValue<D>?
	var e: CachedValue<E>?
	
	func map(_ transform: @escaping (A?, B?, C?, D?, E?) -> R) -> CachedValue<R> {
		let cachedUntil = [a?.cachedUntil, b?.cachedUntil, c?.cachedUntil, d?.cachedUntil, e?.cachedUntil].compactMap{$0}.min()
		let value = transform(a?.value, b?.value, c?.value, d?.value, e?.value)
		let observer = APIObserverOptionalJoin<CachedValue<R>>(values: [a.map {AnyCachedValue($0)},
																		b.map {AnyCachedValue($0)},
																		c.map {AnyCachedValue($0)},
																		d.map {AnyCachedValue($0)},
																		e.map {AnyCachedValue($0)}]) {transform($0[0] as? A,
																												$0[1] as? B,
																												$0[2] as? C,
																												$0[3] as? D,
																												$0[4] as? E)}
		return CachedValue(value: value, cachedUntil: cachedUntil, observer: observer)
	}
}

struct OptionalJoin6<R, A, B, C, D, E, F> {
	var a: CachedValue<A>?
	var b: CachedValue<B>?
	var c: CachedValue<C>?
	var d: CachedValue<D>?
	var e: CachedValue<E>?
	var f: CachedValue<F>?
	
	func map(_ transform: @escaping (A?, B?, C?, D?, E?, F?) -> R) -> CachedValue<R> {
		let cachedUntil = [a?.cachedUntil, b?.cachedUntil, c?.cachedUntil, d?.cachedUntil, e?.cachedUntil, f?.cachedUntil].compactMap{$0}.min()
		let value = transform(a?.value, b?.value, c?.value, d?.value, e?.value, f?.value)
		let observer = APIObserverOptionalJoin<CachedValue<R>>(values: [a.map {AnyCachedValue($0)},
																		b.map {AnyCachedValue($0)},
																		c.map {AnyCachedValue($0)},
																		d.map {AnyCachedValue($0)},
																		e.map {AnyCachedValue($0)},
																		f.map {AnyCachedValue($0)},]) {transform($0[0] as? A,
																												 $0[1] as? B,
																												 $0[2] as? C,
																												 $0[3] as? D,
																												 $0[4] as? E,
																												 $0[5] as? F)}
		return CachedValue(value: value, cachedUntil: cachedUntil, observer: observer)
	}
}

class APIObserverOptionalJoin<Value: CachedValueProtocol>: APIObserver<Value> {
	var values: [AnyCachedValue?]
	let transform: ([Any?]) -> Value.Value?
	
	init(values: [AnyCachedValue?], transform: @escaping ([Any?]) -> Value.Value? ) {
		self.values = values
		self.transform = transform
	}
	
	override var handler: ((Value) -> Void)? {
		didSet {
			if handler == nil {
				for value in values {
					value?.setHandler(nil)
				}
			}
			else {
				for value in values {
					value?.setHandler { [weak self] newValue in
						self?.notify()
					}
				}
			}
		}
	}
	
	func notify() {
		guard let value = transform(values.map{$0?.value}) else {return}
		notify(newValue: value, cachedUntil: values.compactMap{$0?.cachedUntil}.min())
	}
}
