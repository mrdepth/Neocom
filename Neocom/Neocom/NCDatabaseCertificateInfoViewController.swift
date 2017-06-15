//
//  NCDatabaseCertificateInfoViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 26.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData


class NCDatabaseCertificateInfoViewController: NCPageViewController {
	var certificate: NCDBCertCertificate?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		let controller1 = storyboard!.instantiateViewController(withIdentifier: "NCDatabaseCertificateMasteryViewController") as! NCDatabaseCertificateMasteryViewController
		let controller2 = storyboard!.instantiateViewController(withIdentifier: "NCDatabaseCertificateRequirementsViewController") as! NCDatabaseCertificateRequirementsViewController
		controller1.certificate = certificate
		controller2.certificate = certificate
		viewControllers = [controller1, controller2]
	}
	
}
