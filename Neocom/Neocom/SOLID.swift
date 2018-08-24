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
	var storage: Storage {get set}
	
	func configure() -> Void
}

protocol Presenter: class {
	associatedtype V: View
	associatedtype I: Interactor
	var view: V! {get set}
	var interactor: I! {get set}
	
	func configure() -> Void
	func viewWillAppear(_ animated: Bool) -> Void
	func viewDidAppear(_ animated: Bool) -> Void
	func viewWillDisappear(_ animated: Bool) -> Void
	func viewDidDisappear(_ animated: Bool) -> Void
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
}

