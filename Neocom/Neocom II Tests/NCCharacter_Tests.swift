//
//  NCCharacter_Tests.swift
//  Neocom II Tests
//
//  Created by Artem Shimanski on 21.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import XCTest
@testable import Neocom

class NCCharacter_Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSkill() {
		let context = sde.viewContext
		let skill = NCCharacter.Skill(type: context.invType("Navigation")!)!
		
		for (level, sp) in zip([1,2,3,4,5], [250, 1415, 8000, 45255, 256000]) {
			XCTAssertEqual(skill.skillPoints(at: level), sp)
			XCTAssertEqual(skill.level(with: sp), level)
			XCTAssertEqual(skill.level(with: sp - 1), level - 1)
			XCTAssertEqual(skill.level(with: sp + 1), level)
		}

		let attributes = NCCharacter.Attributes(intelligence: 25, memory: 20, perception: 15, willpower: 20, charisma: 19)
		XCTAssertEqual(skill.skillpointsPerSecond(with: attributes), ((25 + 15 / 2.0) / 60.0), accuracy: 0.001)
    }
    
}
