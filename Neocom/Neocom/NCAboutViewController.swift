//
//  NCAboutViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 17.10.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import Foundation

class NCAboutViewController: NCTreeViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCHeaderTableViewCell.empty,
		                    Prototype.NCDefaultTableViewCell.attributeNoImage,
		                    Prototype.NCDefaultTableViewCell.noImage])

	}
	
	override func updateContent(completionHandler: @escaping () -> Void) {
		defer {completionHandler()}
		
		var sections = [TreeNode]()
		
		if let info = Bundle.main.infoDictionary, let version = info["CFBundleShortVersionString"] as? String, let build = info["CFBundleVersion"] as? String {
			let s = "\(version) (\(build))"
			sections.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attributeNoImage, title: NSLocalizedString("Application Version", comment: "").uppercased(), subtitle: s))
		}
		
		if let version: NCDBVersion =  NCDatabase.sharedDatabase?.viewContext.fetch("Version") {
			let s = "\(version.expansion ?? "") (\(version.version ?? ""))"
			sections.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attributeNoImage, title: NSLocalizedString("SDE Version", comment: "").uppercased(), subtitle: s))
		}
		
		sections.append(DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.empty, isExpandable: false, children: [
			DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attributeNoImage, title: NSLocalizedString("Support", comment: "").uppercased(), subtitle: NCSupportEmail, route: Router.Custom({ (_, _) in
				UIApplication.shared.openURL(URL(string: "mailto:\(NCSupportEmail)")!)
			})),
			DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attributeNoImage, title: NSLocalizedString("Homepage", comment: "").uppercased(), subtitle: NCHomepage, route: Router.Custom({ (_, _) in
				UIApplication.shared.openURL(URL(string: NCHomepage)!)
			})),
			DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attributeNoImage, title: NSLocalizedString("Sources", comment: "").uppercased(), subtitle: NCSources, route: Router.Custom({ (_, _) in
				UIApplication.shared.openURL(URL(string: NCSources)!)
			})),

			]))
		
		sections.append(DefaultTreeSection(title: NSLocalizedString("Special Thanks", comment: "").uppercased(), children: NCSpecialThanks.map { DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.noImage, title: $0) }))
		
		treeController?.content = RootNode(sections)
	}
}
