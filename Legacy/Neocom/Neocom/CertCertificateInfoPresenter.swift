//
//  CertCertificateInfoPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 9/28/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import TreeController

class CertCertificateInfoPresenter: Presenter {
	typealias View = CertCertificateInfoViewController
	typealias Interactor = CertCertificateInfoInteractor
	
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
		view?.title = view?.input?.certificateName ?? NSLocalizedString("Certificate", comment: "")
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
}
