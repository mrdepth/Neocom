//
//  API_Tests.swift
//  Neocom II Tests
//
//  Created by Artem Shimanski on 23.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import XCTest
import Expressible
@testable import EVEAPI
@testable import Neocom
import Futures

class API_Tests: TestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
	func testCharacter() {
		let account: Account? = Services.storage.viewContext.currentAccount
		XCTAssertNotNil(account)
		
		var api: API! = Services.api.make(for: account)
		let exp = expectation(description: "Wait")
		
		api.character(cachePolicy: .useProtocolCachePolicy).then { result in
			XCTAssertFalse(result.value.trainedSkills.isEmpty)
			
			exp.fulfill()
		}.catch { error in
			XCTFail(error.localizedDescription)
		}
		
		wait(for: [exp], timeout: 10)
		api = nil

	}
}
