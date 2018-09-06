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
import Expressible
import CoreData

class SOLID_Tests: XCTestCase {

    override func setUp() {
		Services.cache = cache
		Services.sde = sde
		Services.storage = storage

		if storage.viewContext.account(with: oAuth2Token) == nil {
			_ = storage.viewContext.newAccount(with: oAuth2Token)
			try! storage.viewContext.save()
		}
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
			
			
			view!.didPresent = {
				exp.fulfill()
			}
			
			DispatchQueue.main.async {
				view!.presenter.content!.expires = Date.init(timeIntervalSinceNow: -10)
				view!.presenter.applicationWillEnterForeground()
			}
		}
		
		view.loadViewIfNeeded()
		view.viewWillAppear(true)
		
		
		wait(for: [exp], timeout: 10)
		view = nil
    }
	
	func testCoreData() {
		let exp = expectation(description: "end")
		
		var view: SolidTestViewController2! = SolidTestViewController2()
		try! XCTAssertEqual(storage.viewContext.managedObjectContext.from(Account.self).count(), 1)
		
		view.didPresent = { [weak view] in
			
			
			XCTAssertNotNil(view)
			XCTAssertEqual(view!.tableView.numberOfSections, 2)
			XCTAssertEqual(view!.tableView.numberOfRows(inSection: 0), 2)
			XCTAssertEqual(view!.tableView.numberOfRows(inSection: 1), 0)
			
			let account = storage.viewContext.newAccount(with: oAuth2Token)
			account.folder = AccountsFolder(context:storage.viewContext.managedObjectContext)
			account.folder?.name = "Folder"
			try! account.managedObjectContext?.save()

			XCTAssertEqual(view!.tableView.numberOfSections, 2)
			XCTAssertEqual(view!.tableView.numberOfRows(inSection: 0), 2)
			XCTAssertEqual(view!.tableView.numberOfRows(inSection: 1), 2)
			
			view!.tableView.layoutIfNeeded()
			DispatchQueue.main.async {
				self.add(view!.screenshot())
				exp.fulfill()
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
	var unwinder: Unwinder?
	
	lazy var presenter: SolidTestPresenter! = SolidTestPresenter(view: self)
	lazy var treeController: TreeController! = TreeController()
	
	var didPresent: (() -> Void)?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		treeController.delegate = self
		treeController.scrollViewDelegate = self
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
	
	@discardableResult
	func present(_ content: Array<Tree.Item.Row<Tree.Content.Default>>) -> Future<Void> {
		return treeController.reloadData(content).finally { [weak self] in
			self?.didPresent?()
		}
	}
}

class SolidTestPresenter: TreePresenter {
	var content: ESI.Result<ESI.Status.ServerStatus>?
	
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
	
	func presentation(for content: ESI.Result<ESI.Status.ServerStatus>) -> Future<[Item]> {
		let result = [Tree.Item.Row(Tree.Content.Default(title: "\(content.value)"))]
		return .init(result)
	}
}

class SolidTestInteractor: TreeInteractor {
	typealias Content = ESI.Result<ESI.Status.ServerStatus>
	weak var presenter: SolidTestPresenter!
	
	required init(presenter: SolidTestPresenter) {
		self.presenter = presenter
	}
	
	
	func load(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<ESI.Status.ServerStatus>> {
		
		var api: API! = APIMock(esi: ESI())
		return api.serverStatus(cachePolicy: .useProtocolCachePolicy).finally {
			api = nil
		}
	}
	
}


class APIMock: APIClient {
	override func serverStatus(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<ESI.Status.ServerStatus>> {
		let value = ESI.Status.ServerStatus(players: 0, serverVersion: "1", startTime: Date(), vip: false)
		return .init(ESI.Result(value: value, expires: Date.init(timeIntervalSinceNow: 60)))
	}
}

class SolidTestViewController2: UITableViewController, TreeView {
	var unwinder: Unwinder?
	
	lazy var presenter: SolidTestPresenter2! = SolidTestPresenter2(view: self)
	lazy var treeController: TreeController! = TreeController()
	
	var didPresent: (() -> Void)?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		treeController.delegate = self
		treeController.scrollViewDelegate = self
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
	
	@discardableResult
	func present(_ content: Array<AnyTreeItem>) -> Future<Void> {
		return treeController.reloadData(content).finally { [weak self] in
			self?.didPresent?()
		}
	}
}

class SolidTestPresenter2: TreePresenter {
	
	typealias Item = AnyTreeItem
	var presentation: [AnyTreeItem]?
	var isLoading: Bool = false
	
	weak var view: SolidTestViewController2!
	lazy var interactor: SolidTestInteractor2! = SolidTestInteractor2(presenter: self)
	
	required init(view: SolidTestViewController2) {
		self.view = view
	}
	
	func configure() {
		view.tableView.register([Prototype.TreeHeaderCell.default,
								 Prototype.TreeDefaultCell.default])
		
		interactor.configure()
	}
	
	func presentation(for content: ()) -> Future<[Item]> {
//		let result = [Tree.Item.Row(Tree.Content.Default(title: "\(content.value)"))]
		let fetchRequest = storage.viewContext.managedObjectContext.from(AccountsFolder.self).sort(by: \AccountsFolder.name, ascending: true).fetchRequest
		let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: storage.viewContext.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
		let defaultFolder = Tree.Item.SolidTestDefaultFolder(treeController: view.treeController)
		let folders = Tree.Item.SolidTestFoldersResultsController(frc, treeController: view.treeController)
		
		return .init([defaultFolder.asAnyItem, folders.asAnyItem])
	}
}

class SolidTestInteractor2: TreeInteractor {
	weak var presenter: SolidTestPresenter2!
	
	required init(presenter: SolidTestPresenter2) {
		self.presenter = presenter
	}
}

extension Tree.Item {
	
	class SolidTestFoldersResultsController: FetchedResultsController<FetchedResultsSection<SolidTestFolderItem>> {
	}
	
	class SolidTestFolderItem: Tree.Item.Section<SolidTestAccountsResultsController>, FetchedResultsTreeItem {
		var result: AccountsFolder
		unowned var section: FetchedResultsSectionProtocol
		
		private lazy var _children: [SolidTestAccountsResultsController]? = {
			let request = result.managedObjectContext!.from(Account.self)
				.filter(\Account.folder == result)
				.sort(by: \Account.folder, ascending: true).sort(by: \Account.characterName, ascending: true)
				.fetchRequest

			let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: result.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
			return [SolidTestAccountsResultsController(frc, treeController: section.controller.treeController)]
		}()
		
		override var children: [SolidTestAccountsResultsController]? {
			get {
				return _children
			}
			set {
				_children = newValue
			}
		}
		
		required init(_ result: AccountsFolder, section: FetchedResultsSectionProtocol) {
			self.result = result
			self.section = section
			super.init(Tree.Content.Section(title: result.name), diffIdentifier: result, expandIdentifier: result.objectID, treeController: section.controller.treeController)
		}
		
	}
	
	class SolidTestAccountsResultsController: FetchedResultsController<FetchedResultsSection<SolidTestAccountItem>> {
	}
	
	class SolidTestDefaultFolder: Tree.Item.Section<SolidTestAccountsResultsController> {
		
		init(treeController: TreeController?) {
			let managedObjectContext = Services.storage.viewContext.managedObjectContext
			
			let request = managedObjectContext.from(Account.self)
				.filter(\Account.folder == nil)
				.sort(by: \Account.folder, ascending: true).sort(by: \Account.characterName, ascending: true)
				.fetchRequest
			
			let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
			let children = [SolidTestAccountsResultsController(frc, treeController: treeController)]
			
			super.init(Tree.Content.Section(title: "Default"), diffIdentifier: "defaultFolder", expandIdentifier: "defaultFolder", treeController: treeController, children: children)
		}
	}
	
	class SolidTestAccountItem: FetchedResultsTreeItem, CellConfiguring {
		var result: Account
		unowned var section: FetchedResultsSectionProtocol
		
		var prototype: Prototype? {
			return Prototype.TreeDefaultCell.default
		}
		
		func configure(cell: UITableViewCell) {
			guard let cell = cell as? TreeDefaultCell else {return}
			cell.titleLabel?.text = result.characterName
		}
		
		required init(_ result: Account, section: FetchedResultsSectionProtocol) {
			self.result = result
			self.section = section
		}
		
	}
}
