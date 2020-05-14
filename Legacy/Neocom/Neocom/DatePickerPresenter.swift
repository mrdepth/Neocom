//
//  DatePickerPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/20/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import CloudData

class DatePickerPresenter: Presenter {
	typealias View = DatePickerViewController
	typealias Interactor = DatePickerInteractor
	
	weak var view: View?
	lazy var interactor: Interactor! = Interactor(presenter: self)
	
	required init(view: View) {
		self.view = view
	}
	
	var value: Date?
	
	func configure() {
		value = view?.input?.current
		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
	}
	
	func viewWillDisappear(_ animated: Bool) {
		guard let value = value, let view = view, let input = view.input else {return}
		input.completion(view, value)
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func done() {
		view?.unwinder?.unwind()
	}
	
	func cancel() {
		value = nil
		view?.unwinder?.unwind()
	}
	
	func onChangeValue(_ value: Date) {
		self.value = value
	}
}
