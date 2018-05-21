//
//  NCAboutViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 17.10.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import Foundation
import Dgmpp
import EVEAPI

class NCAboutViewController: NCTreeViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCHeaderTableViewCell.empty,
		                    Prototype.NCDefaultTableViewCell.attributeNoImage,
		                    Prototype.NCDefaultTableViewCell.noImage])

	}
	
	override func content() -> Future<TreeNode?> {
		
		var sections = [TreeNode]()
		
		if let info = Bundle.main.infoDictionary, let version = info["CFBundleShortVersionString"] as? String, let build = info["CFBundleVersion"] as? String {
			let s = "\(version) (\(build))"
			sections.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attributeNoImage, title: NSLocalizedString("Application Version", comment: "").uppercased(), subtitle: s))
		}
		
		sections.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attributeNoImage, title: NSLocalizedString("SDE Version", comment: "").uppercased(), subtitle: NCDatabase.version))
		let dgmVersion = DGMVersion.current
		sections.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attributeNoImage, title: NSLocalizedString("DGMPP Version", comment: "").uppercased(), subtitle: "\(dgmVersion.major).\(dgmVersion.minor).\(dgmVersion.sde.build) (\(dgmVersion.sde.version))"))
		

//		if let version: NCDBVersion =  NCDatabase.sharedDatabase?.viewContext.fetch("Version") {
//			let s = "\(version.expansion ?? "") (\(version.version ?? ""))"
//		}
		
		sections.append(DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.empty, isExpandable: false, children: [
			DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attributeNoImage, title: NSLocalizedString("Support", comment: "").uppercased(), subtitle: NCSupportEmail, route: Router.Custom({ (_, _) in
				UIApplication.shared.openURL(URL(string: "mailto:\(NCSupportEmail)")!)
			})),
			DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attributeNoImage, title: NSLocalizedString("Homepage", comment: "").uppercased(), subtitle: NCHomepage.absoluteString, route: Router.Custom({ (_, _) in
				UIApplication.shared.openURL(NCHomepage)
			})),
			DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attributeNoImage, title: NSLocalizedString("Sources", comment: "").uppercased(), subtitle: NCSources.absoluteString, route: Router.Custom({ (_, _) in
				UIApplication.shared.openURL(NCSources)
			})),
			DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attributeNoImage, title: NSLocalizedString("Privacy Policy", comment: "").uppercased(), subtitle: NCPrivacy.absoluteString, route: Router.Custom({ (_, _) in
				UIApplication.shared.openURL(NCPrivacy)
			})),
			DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attributeNoImage, title: NSLocalizedString("Terms of Use", comment: "").uppercased(), subtitle: NCTerms.absoluteString, route: Router.Custom({ (_, _) in
				UIApplication.shared.openURL(NCTerms)
			})),

			]))
		
		sections.append(DefaultTreeSection(title: NSLocalizedString("Special Thanks", comment: "").uppercased(), children: NCSpecialThanks.map { DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.noImage, title: $0) }))
		
		return .init(RootNode(sections))
	}
}


