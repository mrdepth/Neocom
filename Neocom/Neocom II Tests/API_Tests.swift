//
//  API_Tests.swift
//  Neocom II Tests
//
//  Created by Artem Shimanski on 23.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import XCTest
import Expressible
import EVEAPI
@testable import Neocom

class API_Tests: XCTestCase {
    
    override func setUp() {
		if storage.viewContext.account(with: oAuth2Token) == nil {
			_ = storage.viewContext.newAccount(with: oAuth2Token)
			try! storage.viewContext.save()
		}
		
		
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testAPIObserver() {
		let account: Account? = storage.viewContext.accounts().first
		XCTAssertNotNil(account)
		
		var api: API! = APIClient(account: account, cache: cache, sde: sde)
		
		let exp = expectation(description: "Wait")
		
		
		var observer: APIObserver<ESI.Character.Information>?
		
		let ci = api.characterInformation().then { result in
			observer = result.observer
			observer?.handler = { (_, _) in
				exp.fulfill()
			}
		}.catch { error in
			XCTFail(error.localizedDescription)
		}
		
		ci.finally(on: .main) {
			api = APIClient(account: account, cachePolicy: .reloadIgnoringLocalCacheData, cache: cache, sde: sde)
			_ = api.characterInformation().catch { error in
				XCTFail(error.localizedDescription)
			}
		}
		
		wait(for: [exp], timeout: 10)
		observer = nil
		api = nil
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
