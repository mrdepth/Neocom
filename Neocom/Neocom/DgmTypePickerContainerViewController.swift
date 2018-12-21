//
//  DgmTypePickerContainerViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/30/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Expressible

class DgmTypePickerContainerViewController: PageViewController, View {
	
	typealias Presenter = DgmTypePickerContainerPresenter
	lazy var presenter: Presenter! = Presenter(view: self)
	
	var unwinder: Unwinder?
	typealias Input = SDEDgmppItemCategory
	var input: Input?

	override func viewDidLoad() {
		super.viewDidLoad()
		presenter.configure()

		guard let input = input else {return}
		let group = (try? Services.sde.viewContext.managedObjectContext
			.from(SDEDgmppItemGroup.self)
			.filter(\SDEDgmppItemGroup.parentGroup == nil && \SDEDgmppItemGroup.category == input)
			.first()) ?? nil
		if let group = group {
			title = group.groupName
			viewControllers = try! [DgmTypePickerGroups.default.instantiate(group).get(),
									DgmTypePickerRecents.default.instantiate(input).get()]
		}
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
}
