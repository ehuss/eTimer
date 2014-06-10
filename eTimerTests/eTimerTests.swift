//
//  eTimerTests.swift
//  eTimerTests
//
//  Created by Eric Huss on 6/6/14.
//  Copyright (c) 2014 Eric Huss. All rights reserved.
//

import XCTest
import eTimer

class eTimerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testFormatDuration() {
        XCTAssertEqualObjects(ETFormatDuration(0.0), "0:00")
        XCTAssertEqualObjects(ETFormatDuration(0.1), "0:00")
        XCTAssertEqualObjects(ETFormatDuration(0.9), "0:00")
        XCTAssertEqualObjects(ETFormatDuration(1.0), "0:01")
        XCTAssertEqualObjects(ETFormatDuration(59.9), "0:59")
        XCTAssertEqualObjects(ETFormatDuration(60), "1:00")
        XCTAssertEqualObjects(ETFormatDuration(60*59), "59:00")
        XCTAssertEqualObjects(ETFormatDuration(60*60), "1:00:00")
        XCTAssertEqualObjects(ETFormatDuration(60*60*24), "24:00:00")
    }


    
//    func testExample() {
//        // This is an example of a functional test case.
//        XCTAssert(true, "Pass")
//    }
//    
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measureBlock() {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
