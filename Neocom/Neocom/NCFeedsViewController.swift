//
//  NCFeedsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 02.07.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCFeedsViewController: NCTreeViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.default])
		
	}
	
	override func updateContent(completionHandler: @escaping () -> Void) {
		let folders = try! JSONSerialization.jsonObject(with: try! Data(contentsOf: Bundle.main.url(forResource: "rssFeeds", withExtension: "json")!), options: []) as! [String: Any]
		
		let sections = (folders["folders"] as? [[String: Any]])?.map { i -> DefaultTreeSection in
			let rows = (i["feeds"] as? [[String: Any]])?.flatMap { j -> DefaultTreeRow? in
				guard let s = j["url"] as? String, let url = URL(string: s) else {return nil}
				guard let title = j["title"] as? String else {return nil}
				return DefaultTreeRow(image: #imageLiteral(resourceName: "rss"),
				                      title: title,
				                      subtitle: j["link"] as? String,
				                      accessoryType: .disclosureIndicator,
				                      route: Router.RSS.Channel(url: url, title: title))
			}
			let title = (i["title"] as? String)?.uppercased()
			return DefaultTreeSection(nodeIdentifier: title, title: title, children: rows)
		}
		
		treeController?.content = RootNode(sections ?? [], collapseIdentifier: "NCFeedsViewController")
		completionHandler()
	}
}
