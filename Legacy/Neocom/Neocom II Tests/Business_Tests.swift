//
//  Business_Tests.swift
//  Neocom II Tests
//
//  Created by Artem Shimanski on 11/9/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import XCTest
@testable import Neocom
import Futures
import EVEAPI

class Business_Tests: TestCase {

    func testAssets() {
		let controller = try! Assets.default.instantiate().get()
		wait(for: [test(controller)], timeout: 20)
		
		controller.treeController.tableView(controller.tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
		
		let exp = expectation(description: "end")
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
			self.add(controller.screenshot())
			exp.fulfill()
    	}

		wait(for: [exp], timeout: 1)
	}
	
	func testMarketOrders() {
		let controller = try! MarketOrders.default.instantiate().get()
		wait(for: [test(controller)], timeout: 10)
	}
	
	func testIndustryJobs() {
		let controller = try! IndustryJobs.default.instantiate().get()
		wait(for: [test(controller)], timeout: 10)
	}

	func testContracts() {
		let controller = try! Contracts.default.instantiate().get()
		
		wait(for: [test(controller)], timeout: 10)
	}

	func testContractInfo() {
		let contract = try! Services.api.current.contracts(cachePolicy: .useProtocolCachePolicy).get()
		XCTAssertFalse(contract.value.isEmpty)
		let controller = try! ContractInfo.default.instantiate(contract.value[0]).get()

		wait(for: [test(controller)], timeout: 10)
	}

	func testWalletJournal() {
		let controller = try! WalletJournalPage.default.instantiate().get()
		let nc = NavigationController(rootViewController: controller)
		wait(for: [test(controller, takeScreenshot: false)], timeout: 10)
		add(nc.screenshot())
	}

	func testWalletTransactions() {
		let controller = try! WalletTransactionsPage.default.instantiate().get()
		let nc = NavigationController(rootViewController: controller)
		wait(for: [test(controller, takeScreenshot: false)], timeout: 10)
		add(nc.screenshot())
	}

}
