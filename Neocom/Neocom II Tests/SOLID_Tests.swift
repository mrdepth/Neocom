//
//  SOLID_Tests.swift
//  Neocom II Tests
//
//  Created by Artem Shimanski on 29.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import XCTest
@testable import Neocom
import TreeController
import Futures
import EVEAPI

class SOLID_Tests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSolid() {
		let exp = expectation(description: "end")

		var view: SolidTestViewController! = SolidTestViewController()
		
		view.didPresent = { [weak view] in
			XCTAssertNotNil(view)
			XCTAssertEqual(view!.tableView.numberOfSections, 1)
			XCTAssertEqual(view!.tableView.numberOfRows(inSection: 0), 1)
			
			
			
			var counter = 0
			view!.didPresent = {
				XCTAssertLessThan(counter, 2)
				counter += 1
				if  counter == 2 {
					DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
						exp.fulfill()
					})
				}
			}
			
			DispatchQueue.main.async {
				view!.presenter.interactor.load(cachePolicy: .reloadIgnoringLocalCacheData).finally(on: .main) {
					view!.presenter.content!.cachedUntil = Date.init(timeIntervalSinceNow: -10)
					view!.presenter.applicationWillEnterForeground()
				}
			}
		}
		
		view.loadViewIfNeeded()
		view.viewWillAppear(true)
		
		
		wait(for: [exp], timeout: 10)
		view = nil
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}


class SolidTestViewController: UITableViewController, TreeView {
	lazy var presenter: SolidTestPresenter! = SolidTestPresenter(view: self)
	lazy var treeController: TreeController! = TreeController()
	
	var didPresent: (() -> Void)?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		treeController.delegate = self
		treeController.tableView = tableView
		presenter.configure()
	}
	
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		presenter.viewWillAppear(animated)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		presenter.viewDidAppear(animated)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		presenter.viewWillDisappear(animated)
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		presenter.viewDidDisappear(animated)
	}
	
	func present(_ content: Array<Tree.Item.Row<Tree.Content.Default>>) -> Future<Void> {
		return treeController.reload(content).finally { [weak self] in
			self?.didPresent?()
		}
	}
}

class SolidTestPresenter: TreePresenter {
	var content: CachedValue<ESI.Status.ServerStatus>?
	
	
	typealias Item = Tree.Item.Row<Tree.Content.Default>
	var presentation: [Item]?
	var isLoading: Bool = false
	
	weak var view: SolidTestViewController!
	lazy var interactor: SolidTestInteractor! = SolidTestInteractor(presenter: self)
	
	required init(view: SolidTestViewController) {
		self.view = view
	}
	
	func configure() {
		view.tableView.register([Prototype.TreeHeaderCell.default,
								 Prototype.TreeDefaultCell.default])
		
		interactor.configure()
	}
	
	func presentation(for content: CachedValue<ESI.Status.ServerStatus>) -> Future<[Item]> {
		let result = [Tree.Item.Row(content: Tree.Content.Default(title: "\(content.value)"))]
		return .init(result)
	}
}

class SolidTestInteractor: TreeInteractor {
	typealias Content = CachedValue<ESI.Status.ServerStatus>
	weak var presenter: SolidTestPresenter!
	lazy var cache: Cache! = Neocom_II_Tests.cache
	lazy var sde: SDE! = Neocom_II_Tests.sde
	lazy var storage: Storage! = Neocom_II_Tests.storage
	
	required init(presenter: SolidTestPresenter) {
		self.presenter = presenter
	}
	
	
	func load(cachePolicy: URLRequest.CachePolicy) -> Future<CachedValue<ESI.Status.ServerStatus>> {
		var api: API! = self.api(cachePolicy: cachePolicy)
		return api.serverStatus().finally {
			api = nil
		}
	}
	
	func api(cachePolicy: URLRequest.CachePolicy) -> API {
		return APIMock(account: storage.viewContext.currentAccount, server: .tranquility, cachePolicy: cachePolicy, cache: cache, sde: sde)
	}
}


class APIMock: APIClient {
	override func serverStatus() -> Future<CachedValue<ESI.Status.ServerStatus>> {
		return load(for: "ESI.Status.ServerStatus", account: nil, loader: { etag in
			let value = ESI.Status.ServerStatus(players: 0, serverVersion: "1", startTime: Date(), vip: false)
			return .init(ESI.Result(value: value, cached: 60, etag: etag))
//			return esi.status.retrieveTheUptimeAndPlayerCounts(ifNoneMatch: etag)
		})
	}
}
