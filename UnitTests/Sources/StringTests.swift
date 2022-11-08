//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import XCTest

@testable import ElementX

class StringTests: XCTestCase {
    func testEmptyIsAscii() {
        XCTAssertTrue("".isASCII)
    }
    
    func testSpaceIsAscii() {
        XCTAssertTrue("".isASCII)
    }

    func testJohnnyIsAscii() {
        XCTAssertTrue("johnny".isASCII)
    }
    
    func testJöhnnyIsNotAscii() {
        XCTAssertFalse("jöhnny".isASCII)
    }
    
    func testJ🅾️hnnyIsNotAscii() {
        XCTAssertFalse("j🅾️hnny".isASCII)
    }

    func testAsciiStaysAscii() {
        XCTAssertEqual("johnny".asciified(), "johnny")
    }
    
    func testÖBecomesO() {
        XCTAssertEqual("jöhnny".asciified(), "johnny")
    }
    
    func testÅBecomesA() {
        XCTAssertEqual("jåhnny".asciified(), "jahnny")
    }
    
    func test1️⃣2️⃣3️⃣Becomes123() {
        XCTAssertEqual("1️⃣2️⃣3️⃣".asciified(), "123")
    }
    
    func testStripsTheHeartbreakHotel() {
        XCTAssertEqual("Heartbreak Hotel 🏩".asciified(), "Heartbreak Hotel")
    }
}