//
//  Router_Tests.swift
//  Neocom II Tests
//
//  Created by Artem Shimanski on 03.09.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import XCTest
@testable import Neocom
import Futures

class Router_Tests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testPush() {
		let exp = expectation(description: "wait")
		let root = try! RouterTests.default.instantiate().get()
		let navigationController = UINavigationController(rootViewController: root)
		
		
		var window: UIWindow? = UIWindow(frame: navigationController.view.frame)
		window?.rootViewController = navigationController
		window?.makeKeyAndVisible()
		
		Route<RouterTests>(assembly: RouterTests.default).perform(from: root, kind: .push).then(on: .main) { result in
			XCTAssertEqual(navigationController.viewControllers.count, 2)
			let last = navigationController.viewControllers.last as! RouterTestsViewController
			
			Route<RouterTests>(assembly: RouterTests.default).perform(from: last, kind: .push).then(on: .main) { result in
				XCTAssertEqual(navigationController.viewControllers.count, 3)
				let last = navigationController.viewControllers.last as! RouterTestsViewController
				last.unwinder!.unwind(to: root).then(on: .main) { _ in
					XCTAssertEqual(navigationController.viewControllers.count, 1)
					exp.fulfill()
				}
			}
		}
		
		wait(for: [exp], timeout: 10)
		window = nil
    }
	
	func testModal() {
		let exp = expectation(description: "wait")
		let root = try! RouterTests.default.instantiate().get()
		let navigationController = UINavigationController(rootViewController: root)
		
		
		var window: UIWindow? = UIWindow(frame: navigationController.view.frame)
		window?.rootViewController = navigationController
		window?.makeKeyAndVisible()
		
		Route<RouterTests>(assembly: RouterTests.default).perform(from: root, kind: .modal).then(on: .main) { result in
			let chain = sequence(first: navigationController, next: {$0.presentedViewController}).map{$0}
			XCTAssertEqual(chain.count, 2)
			let last = chain.last as! RouterTestsViewController
			
			Route<RouterTests>(assembly: RouterTests.default).perform(from: last, kind: .modal).then(on: .main) { result in
				let chain = sequence(first: navigationController, next: {$0.presentedViewController}).map{$0}
				XCTAssertEqual(chain.count, 3)
				let last = chain.last as! RouterTestsViewController

				last.unwinder!.unwind(to: root).then(on: .main) { _ in
					let chain = sequence(first: navigationController, next: {$0.presentedViewController}).map{$0}
					XCTAssertEqual(chain.count, 1)
					exp.fulfill()
				}
			}
		}
		
		wait(for: [exp], timeout: 10)
		window = nil
	}
	
	func testPushModal() {
		let exp = expectation(description: "wait")
		let root = try! RouterTests.default.instantiate().get()
		let navigationController = UINavigationController(rootViewController: root)
		
		
		var window: UIWindow? = UIWindow(frame: navigationController.view.frame)
		window?.rootViewController = navigationController
		window?.makeKeyAndVisible()
		
		Route<RouterTests>(assembly: RouterTests.default).perform(from: root, kind: .push).then(on: .main) { result in
			XCTAssertEqual(navigationController.viewControllers.count, 2)
			let last = navigationController.viewControllers.last as! RouterTestsViewController

			Route<RouterTests>(assembly: RouterTests.default).perform(from: last, kind: .modal).then(on: .main) { result in
				let chain = sequence(first: navigationController, next: {$0.presentedViewController}).map{$0}
				XCTAssertEqual(chain.count, 2)
				let last = chain.last as! RouterTestsViewController
				
				last.unwinder!.unwind(to: root).then(on: .main) { _ in
					XCTAssertEqual(navigationController.viewControllers.count, 1)
					let chain = sequence(first: navigationController, next: {$0.presentedViewController}).map{$0}
					XCTAssertEqual(chain.count, 1)
					exp.fulfill()
				}
			}
		}
		
		wait(for: [exp], timeout: 10)
		window = nil
	}

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

enum RouterTests: Assembly {
	case `default`
	
	func instantiate(_ input: RouterTestsViewController.Input) -> Future<RouterTestsViewController> {
		return .init(RouterTestsViewController())
	}
}

class RouterTestsViewController: UIViewController, View {
	var unwinder: Unwinder?
	lazy var presenter: RouterTestsPresenter! = RouterTestsPresenter(view: self)
}

class RouterTestsPresenter: Presenter {
	weak var view: RouterTestsViewController!
	lazy var interactor: RouterTestsInteractor! = RouterTestsInteractor(presenter: self)
	required init(view: RouterTestsViewController) {
		self.view = view
	}
}

class RouterTestsInteractor: Interactor {
	weak var presenter: RouterTestsPresenter!
	required init(presenter: RouterTestsPresenter) {
		self.presenter = presenter
	}
}
