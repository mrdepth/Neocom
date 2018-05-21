//
//  NCFeedsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 02.07.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

struct NCRSS: Codable {
	struct Folder: Codable {
		struct Feed: Codable {
			let title: String
			let url: URL
			let link: String
		}
		
		let title: String
		let feeds: [Feed]
	}
	
	let folders: [Folder]
}

class NCFeedsViewController: NCTreeViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.default])
		
	}
	
	override func content() -> Future<TreeNode?> {
		guard let url = Bundle.main.url(forResource: "rssFeeds", withExtension: "json"),
			let data = try? Data(contentsOf: url),
			let rss = try? JSONDecoder().decode(NCRSS.self, from: data)
			else {return .init(nil)}
		
		let sections = rss.folders.map { i -> DefaultTreeSection in
			let rows = i.feeds.map { j -> DefaultTreeRow in
				return DefaultTreeRow(image: #imageLiteral(resourceName: "rss"),
				                      title: j.title,
				                      subtitle: j.link,
				                      accessoryType: .disclosureIndicator,
				                      route: Router.RSS.Channel(url: j.url, title: j.title))
			}
			
			let title = i.title.uppercased()
			return DefaultTreeSection(nodeIdentifier: title, title: title, children: rows)
		}
		return .init(RootNode(sections, collapseIdentifier: "NCFeedsViewController"))
	}
}
