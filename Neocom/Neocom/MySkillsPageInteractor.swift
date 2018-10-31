//
//  MySkillsPageInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 10/31/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData

class MySkillsPageInteractor: TreeInteractor {
	
	typealias Presenter = MySkillsPagePresenter
	typealias Content = MySkillsPageViewController.Input
	weak var presenter: Presenter?
	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
	
	func load(cachePolicy: URLRequest.CachePolicy) -> Future<Content> {
		guard let input = presenter?.view?.input, !input.isEmpty else { return .init(.failure(NCError.reloadInProgress)) }
		return .init(input)
	}
	
	func isExpired(_ content: MySkillsPageViewController.Input) -> Bool {
		return content.isEmpty
	}
}
