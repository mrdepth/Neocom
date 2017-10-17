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
		
		sections.append(DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.empty, children: [
			DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attributeNoImage, title: NSLocalizedString("Support", comment: "").uppercased(), subtitle: "support@eveuniverseiphone.com", route: Router.Custom({ (_, _) in
				UIApplication.shared.openURL(URL(string: "mailto:support@eveuniverseiphone.com")!)
			})),
			DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attributeNoImage, title: NSLocalizedString("Homepage", comment: "").uppercased(), subtitle: "https://facebook.com/groups/Neocom", route: Router.Custom({ (_, _) in
				UIApplication.shared.openURL(URL(string: "https://www.facebook.com/groups/Neocom")!)
			})),
			DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attributeNoImage, title: NSLocalizedString("Sources", comment: "").uppercased(), subtitle: "https://github.com/mrdepth/Neocom", route: Router.Custom({ (_, _) in
				UIApplication.shared.openURL(URL(string: "https://github.com/mrdepth/Neocom")!)
			})),

			]))
		
		let thanks = ["Ilya Gepp aka Kane Gepp",
		              "Dick Starmans aka Enrique d'Ancourt",
		              "Guy Neale",
		              "Peter Vlaar aka Tess La'Coil",
		              "Wayne Hindle",
		              "Tobias Tango",
		              "Niclas Titius",
		              "Fela Sowande",
		              "Denis Chernov",
		              "Andrei Kokarev",
		              "Kurt Otto"]
		
		sections.append(DefaultTreeSection(title: NSLocalizedString("Special Thanks", comment: "").uppercased(), children: thanks.map { DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.noImage, title: $0) }))
		
		treeController?.content = RootNode(sections)
	}
}
