//
//  NCRefreshable.swift
//  Neocom
//
//  Created by Artem Shimanski on 02.05.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit


var RefreshHandle = "refreshHandler"
var LoadingHandle = "isLoading"

@objc protocol NCRefreshable {
	weak var tableView: UITableView! {get}
	var refreshControl: UIRefreshControl? {get set}
	func reload(cachePolicy: URLRequest.CachePolicy, completionHandler: (() -> Void)? )
}

extension NCRefreshable {
	
	func registerRefreshable() {
		let refreshControl = UIRefreshControl()

		self.refreshControl = refreshControl
		
		let handler = NCActionHandler(refreshControl, for: .valueChanged) { [weak self] _ in
			self?.reload(cachePolicy: .reloadIgnoringLocalCacheData)
		}
		objc_setAssociatedObject(handler, &RefreshHandle, handler, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
	}
	
	func reload() {
		self.reload(cachePolicy: .useProtocolCachePolicy)
	}

	private func reload(cachePolicy: URLRequest.CachePolicy) {
		if objc_getAssociatedObject(self, &LoadingHandle) as? Bool == true {
			self.refreshControl?.endRefreshing()
			return
		}
		
		objc_setAssociatedObject(self, &LoadingHandle, true, .OBJC_ASSOCIATION_ASSIGN)
		let progress = self is UIViewController ? NCProgressHandler(viewController: self as! UIViewController, totalUnitCount: 1) : nil
		progress?.progress.becomeCurrent(withPendingUnitCount: 1)
		self.reload(cachePolicy: cachePolicy) { [weak self] in
			guard let strongSelf = self else {return}
			if let refreshControl = strongSelf.refreshControl, refreshControl.isRefreshing {
				refreshControl.endRefreshing()
			}
			
			progress?.finish()
			objc_setAssociatedObject(strongSelf, &LoadingHandle, false, .OBJC_ASSOCIATION_ASSIGN)
		}
		progress?.progress.resignCurrent()
	}
}
