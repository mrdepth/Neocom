//
//  SOLID.swift
//  Neocom
//
//  Created by Artem Shimanski on 24.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

protocol View: class {
	associatedtype P: Presenter
	var presenter: P! {get set}
	
	associatedtype Input = Void
	var input: Input? {get set}
}

protocol Interactor: class {
	associatedtype P: Presenter
	var presenter: P! {get set}
	var cache: Cache! {get set}
	var sde: SDE! {get set}
	var storage: Storage! {get set}
	
	init(presenter: P)
	func configure() -> Void
	func api(cachePolicy: URLRequest.CachePolicy) -> API
}

protocol Presenter: class {
	associatedtype V: View
	associatedtype I: Interactor
	var view: V! {get set}
	var interactor: I! {get set}
	
	init(view: V)

	func configure() -> Void
	func viewWillAppear(_ animated: Bool) -> Void
	func viewDidAppear(_ animated: Bool) -> Void
	func viewWillDisappear(_ animated: Bool) -> Void
	func viewDidDisappear(_ animated: Bool) -> Void
	func applicationWillEnterForeground() -> Void
	func beginTask(totalUnitCount: Int64, indicator: ProgressTask.Indicator) -> ProgressTask
	func beginTask(totalUnitCount: Int64) -> ProgressTask
}

extension View where Input == Void {
	var input: Input? {
		get { return nil }
		set {}
	}
}

extension Presenter {
	func configure() -> Void {
		interactor.configure()
	}
	
	func viewWillAppear(_ animated: Bool) -> Void {
	}
	
	func viewDidAppear(_ animated: Bool) -> Void {
	}
	
	func viewWillDisappear(_ animated: Bool) -> Void {
	}
	
	func viewDidDisappear(_ animated: Bool) -> Void {
	}
	
	func applicationWillEnterForeground() {
		
	}
}

extension Presenter {
	func beginTask(totalUnitCount: Int64, indicator: ProgressTask.Indicator) -> ProgressTask {
		return ProgressTask(progress: Progress(totalUnitCount: totalUnitCount), indicator: indicator)
	}

}

extension Presenter where V: UIViewController {
	func beginTask(totalUnitCount: Int64) -> ProgressTask {
		return beginTask(totalUnitCount: totalUnitCount, indicator: .progressBar(view))
	}
	
}

extension Presenter where V: UIView {
	func beginTask(totalUnitCount: Int64) -> ProgressTask {
		return beginTask(totalUnitCount: totalUnitCount, indicator: .progressBar(view))
	}
	
}

extension Interactor {
	func api(cachePolicy: URLRequest.CachePolicy) -> API {
		return APIClient(account: storage.viewContext.currentAccount, cachePolicy: cachePolicy, cache: cache, sde: sde)
	}
}
