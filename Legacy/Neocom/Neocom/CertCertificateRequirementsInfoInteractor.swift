//
//  CertCertificateRequirementsInfoInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 9/28/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData

class CertCertificateRequirementsInfoInteractor: TreeInteractor {
	typealias Presenter = CertCertificateRequirementsInfoPresenter
	typealias Content = Void
	weak var presenter: Presenter?
	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
}
