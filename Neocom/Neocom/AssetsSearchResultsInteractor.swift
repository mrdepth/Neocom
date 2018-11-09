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
	typealias Content = Value
	weak var presenter: Presenter?
	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
	
	struct Value {
		var suggestions: [(String, String)]
		var index: [(EVELocation, [String: [Tree.Item.AssetRow]])]
	}
	
	func load(cachePolicy: URLRequest.CachePolicy) -> Future<Content> {
		guard let input = presenter?.view?.input, !input.isEmpty else { return .init(.failure(NCError.reloadInProgress)) }
		if let content = presenter?.content {
			return .init(content)
		}
		else {
			return DispatchQueue.global(qos: .utility).async { () -> Content in
				
				var index = [(EVELocation, [String: [Tree.Item.AssetRow]])]()
				var suggestions = [String: String]()

				for section in input {
					var dic = [String: [Tree.Item.AssetRow]]()
					
					section.children?.flatMap {$0.flattened}.forEach { asset in

						[asset.typeName,
						 asset.groupName,
						 asset.categoryName,
						 asset.name]
							.compactMap {$0}
							.filter {!$0.isEmpty}
							.forEach {
								let key = $0.lowercased()
								suggestions[key] = $0
								dic[key, default: []].append(Tree.Item.AssetRow(asset))
						}
					}
					index.append((section.content, dic))
					[section.content.itemName, section.content.solarSystemName].compactMap {$0}.forEach {
						suggestions[$0.lowercased()] = $0
					}
				}
				
				return Value(suggestions: suggestions.sorted {$0.key.count < $1.key.count}, index: index)
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


