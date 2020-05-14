//
//  CertCertificateInfoViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 9/28/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController

class CertCertificateInfoViewController: PageViewController, View {
	typealias Presenter = CertCertificateInfoPresenter
	lazy var presenter: Presenter! = Presenter(view: self)
	
	var unwinder: Unwinder?
	var input: SDECertCertificate?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		presenter.configure()
		
		guard let input = input else {return}
		
		try! viewControllers = [CertCertificateMasteryInfo.default.instantiate(input).get(),
								CertCertificateRequirementsInfo.default.instantiate(input).get()]
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

