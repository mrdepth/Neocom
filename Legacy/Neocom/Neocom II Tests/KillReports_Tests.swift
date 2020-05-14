//
//  KillReports_Tests.swift
//  Neocom II Tests
//
//  Created by Artem Shimanski on 11/13/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import XCTest
@testable import Neocom
import Futures
import EVEAPI

class KillReports_Tests: TestCase {

    override func setUp() {
		super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testKillmails() {
		let view = try! Killmails.default.instantiate().get()
		
		view.loadViewIfNeeded()
		let exp = expectation(description: "end")
		
		view.presenter.reload(cachePolicy: .useProtocolCachePolicy).then(on: .main) { result in
			view.present(result, animated: true).then(on: .main) { _ in
				DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
					self.add(view.screenshot())
					exp.fulfill()
				}
			}
		}
		
		wait(for: [exp], timeout: 10)
    }
	
	func testKillmailInfo() {
		
//		let killmail = try! Services.api.current.killmailInfo(killmailHash: "c9e56846f73b4cb82c3868e91d173bec99c7d630", killmailID: 22044992, cachePolicy: .useProtocolCachePolicy).get()
		let killmail = try! Services.api.current.killmailInfo(killmailHash: "f8ffc770033a08e65a34632dedad0e31e72f17d5", killmailID: 45560150, cachePolicy: .useProtocolCachePolicy).get()
		
		let view = try! KillmailInfo.default.instantiate(killmail.value).get()
		wait(for: [test(view)], timeout: 10)
		
	}

}
