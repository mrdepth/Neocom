//
//  AssetsSearchResultsInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/8/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData

class AssetsSearchResultsInteractor: TreeInteractor {
	typealias Presenter = AssetsSearchResultsPresenter
	typealias Content = [(Tree.Content.Section, [String: [Tree.Item.AssetRow]])]
	weak var presenter: Presenter?
	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
	
	struct SearchIndex: Hashable {
		enum Category {
			case location
			case typeName
			case groupName
			case categoryName
			case name
		}
		let category: Category
		let key: String
	}
	
	func load(cachePolicy: URLRequest.CachePolicy) -> Future<Content> {
		guard let input = presenter?.view?.input, !input.isEmpty else { return .init(.failure(NCError.reloadInProgress)) }
		if let content = presenter?.content {
			return .init(content)
		}
		else {
			return DispatchQueue.global(qos: .utility).async { () -> Content in
				
				var index = Content()

				for section in input {
					var dic = [String: [Tree.Item.AssetRow]]()
					
					section.children?.flatMap {$0.flattened}.forEach { asset in

						[asset.typeName,
						 asset.groupName,
						 asset.categoryName,
						 asset.name]
							.compactMap {$0?.lowercased()}
							.filter {!$0.isEmpty}
							.forEach {dic[$0, default: []].append(Tree.Item.AssetRow(asset))}
					}
					index.append((section.content, dic))
				}
				return index
			}
		}
	}
	
	func isExpired(_ content: Content) -> Bool {
		return false
	}
	
	private var didChangeAccountObserver: NotificationObserver?
	
	func configure() {
		didChangeAccountObserver = NotificationCenter.default.addNotificationObserver(forName: .didChangeAccount, object: nil, queue: .main) { [weak self] _ in
			_ = self?.presenter?.reload(cachePolicy: .useProtocolCachePolicy).then(on: .main) { presentation in
				self?.presenter?.view?.present(presentation, animated: true)
			}
		}
	}
}


