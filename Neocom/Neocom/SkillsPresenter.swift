//
//  SkillsPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 19/10/2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import CloudData

class SkillsPresenter: Presenter {
	typealias View = SkillsViewController
	typealias Interactor = SkillsInteractor
	
	weak var view: View?
	lazy var interactor: Interactor! = Interactor(presenter: self)
	
	required init(view: View) {
		self.view = view
	}
	
	func configure() {
		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
}
