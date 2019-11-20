//
//  SOLID.swift
//  Neocom
//
//  Created by Artem Shimanski on 24.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures


protocol Assembly {
	associatedtype View: Neocom.View
//	typealias Input = View.Input
	func instantiate(_ input: View.Input) -> Future<View>
}

extension Assembly where View.Input == Void {
	func instantiate() -> Future<View> {
		return instantiate(())
	}
}

protocol View: class {
	associatedtype Presenter: Neocom.Presenter
	var presenter: Presenter! {get set}
	var unwinder: Unwinder? {get set}
	
	associatedtype Input = Void
	var input: Input? {get set}
	
	func prepareToRoute<T: View>(to view: T) -> Void
}

protocol Interactor: class {
	associatedtype Presenter: Neocom.Presenter
	var presenter: Presenter? {get set}
	
	init(presenter: Presenter)
	func configure() -> Void
}

protocol Presenter: class {
	associatedtype View: Neocom.View
	associatedtype Interactor: Neocom.Interactor
	var view: View? {get set}
	var interactor: Interactor! {get set}
	
	init(view: View)

	func configure() -> Void
	func viewWillAppear(_ animated: Bool) -> Void
	func viewDidAppear(_ animated: Bool) -> Void
	func viewWillDisappear(_ animated: Bool) -> Void
	func viewDidDisappear(_ animated: Bool) -> Void
	func applicationWillEnterForeground() -> Void
	func beginTask(totalUnitCount unitCount: Int64, indicator: ProgressTask.Indicator) -> ProgressTask
	func beginTask(totalUnitCount unitCount: Int64) -> ProgressTask
}

extension View {
	func prepareToRoute<T: View>(to view: T) -> Void { }
}

extension View where Input == Void {
	var input: Input? {
		get { return nil }
		set {}
	}
}

extension Presenter {
	func configure() -> Void { interactor.configure() }
	func viewWillAppear(_ animated: Bool) -> Void { }
	func viewDidAppear(_ animated: Bool) -> Void { }
	func viewWillDisappear(_ animated: Bool) -> Void { }
	func viewDidDisappear(_ animated: Bool) -> Void { }
	func applicationWillEnterForeground() { }
}

extension Presenter {
	func beginTask(totalUnitCount unitCount: Int64, indicator: ProgressTask.Indicator) -> ProgressTask {
		return ProgressTask(totalUnitCount: unitCount, indicator: indicator)
	}
}

extension Presenter where View: UIViewController {
	func beginTask(totalUnitCount unitCount: Int64) -> ProgressTask {
		return beginTask(totalUnitCount: unitCount, indicator: .progressBar(view!))
	}
}

extension Presenter where View: UIView {
	func beginTask(totalUnitCount unitCount: Int64) -> ProgressTask {
		return beginTask(totalUnitCount: unitCount, indicator: .progressBar(view!))
	}
}

extension Interactor {
	func configure() { }
}

protocol ContentProviderView: View where Presenter: ContentProviderPresenter {
	@discardableResult
	func present(_ content: Presenter.Presentation, animated: Bool) -> Future<Void>
	func fail(_ error: Error) -> Void
}

protocol ContentProviderPresenter: Presenter where View: ContentProviderView, Interactor: ContentProviderInteractor, Presentation == View.Presenter.Presentation {
	associatedtype Presentation
	var content: Interactor.Content? {get set}
	var presentation: Presentation? {get set}
	var loading: Future<Presentation>? {get set}
	
	func presentation(for content: Interactor.Content) -> Future<Presentation>
	func prepareForReload()
}

protocol ContentProviderInteractor: Interactor where Presenter: ContentProviderPresenter {
	associatedtype Content = Void
	func load(cachePolicy: URLRequest.CachePolicy) -> Future<Content>
	func isExpired(_ content: Content) -> Bool
}

extension ContentProviderPresenter {
	
	func prepareForReload() {
	}
	
//	@discardableResult
	func reload(cachePolicy: URLRequest.CachePolicy) -> Future<Presentation> {
		guard self.loading == nil else {return .init(.failure(NCError.reloadInProgress))}
		var task: ProgressTask! = beginTask(totalUnitCount: 2)
		
		let progress1 = task.performAsCurrent(withPendingUnitCount: 1) { Progress(totalUnitCount: 1)}
		let progress2 = task.performAsCurrent(withPendingUnitCount: 1) { Progress(totalUnitCount: 1)}
		
		prepareForReload()
		
		let loading = progress1.performAsCurrent(withPendingUnitCount: 1) {
			interactor.load(cachePolicy: cachePolicy).then(on: .main) { [weak self] content -> Future<Presentation> in
				guard let strongSelf = self else {throw NCError.cancelled(type: type(of: self), function: #function)}
				return progress2.performAsCurrent(withPendingUnitCount: 1) {
					strongSelf.presentation(for: content).then(on: .main) { presentation -> Presentation in
						guard let strongSelf = self else {throw NCError.cancelled(type: type(of: self), function: #function)}
						strongSelf.content = content
						strongSelf.presentation = presentation
						strongSelf.loading = nil
						return presentation
					}
				}
			}.catch(on: .main) { [weak self] _ in
				self?.loading = nil
			}.finally(on: .main) {
				task = nil
			}
		}
		
		if case .pending = loading.state {
			self.loading = loading
		}
		return loading
	}
}

extension ContentProviderPresenter where Interactor.Content == Void {
	var content: Void? {
		get { return ()}
		set {}
	}
}

extension ContentProviderInteractor where Content: ESIResultProtocol {
	
	func isExpired(_ content: Content) -> Bool {
		guard let expires = content.expires else {return true}
		return expires < Date()
	}
}

extension ContentProviderPresenter {
	func reloadIfNeeded() {
		if let content = content, presentation != nil, !interactor.isExpired(content) {
			return
		}
		else {
			let animated = presentation != nil
			reload(cachePolicy: .useProtocolCachePolicy).then(on: .main) { [weak self] presentation in
				self?.view?.present(presentation, animated: animated)
			}.catch(on: .main) { [weak self] error in
				self?.view?.fail(error)
			}
		}
	}
	
	func viewWillAppear(_ animated: Bool) -> Void {
		reloadIfNeeded()
	}
	
	func applicationWillEnterForeground() -> Void {
		reloadIfNeeded()
	}
}

extension ContentProviderInteractor where Content == Void {
	func load(cachePolicy: URLRequest.CachePolicy) -> Future<Void> {
		return .init(())
	}
	
	func isExpired(_ content: Void) -> Bool {
		return false
	}
}


class MyV: TreeViewController<MyP, Void>, TreeView {
	func present(_ content: Void, animated: Bool) -> Future<Void> {
		fatalError()
	}
	
	
}

class MyP: TreePresenter {
	var view: MyV?
	
	var interactor: MyI!
	
	required init(view: MyV) {
	}
	
	var presentation: Void?
	
	var loading: Future<Void>?
	
	func presentation(for content: ()) -> Future<Void> {
		fatalError()
	}
	
	typealias Presentation = Void
	
	typealias View = MyV
	
	typealias Interactor = MyI
	
	
}

class MyI: TreeInteractor {
	var presenter: MyP?
	
	required init(presenter: MyP) {
	}
	
	typealias Presenter = MyP
	
	
	
}


class MyA: Assembly {
	func instantiate(_ input: View.Input) -> Future<MyV> {
		fatalError()
	}
	
	typealias View = MyV
	
	
}
