//
//  DatePickerViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/20/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

class DatePickerViewController: UIViewController, View {
	
	typealias Presenter = DatePickerPresenter
	lazy var presenter: Presenter! = Presenter(view: self)
	
	struct Input {
		var title: String
		var range: ClosedRange<Date>
		var current: Date
		let completion: (DatePickerViewController, Date) -> Void
	}
	var input: Input?
	
	var unwinder: Unwinder?
	
	@IBOutlet weak var datePicker: UIDatePicker!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		datePicker.setValue(UIColor.white, forKeyPath: "textColor")
		datePicker.setValue(false, forKeyPath: "highlightsToday")

		title = input?.title
		if let input = input {
			datePicker.minimumDate = input.range.lowerBound
			datePicker.maximumDate = input.range.upperBound
			datePicker.date = input.current
		}
		presenter.configure()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		presenter.viewWillAppear(animated)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		presenter.viewDidAppear(animated)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		presenter.viewWillDisappear(animated)
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		presenter.viewDidDisappear(animated)
	}
	
	@IBAction func onDone(_ sender: Any) {
		presenter.done()
	}
	
	@IBAction func onCancel(_ sender: Any) {
		presenter.cancel()
	}
	
	@IBAction func onChangeValue(_ sender: Any) {
		presenter.onChangeValue(datePicker.date)
	}
}
