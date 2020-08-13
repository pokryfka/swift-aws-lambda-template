import XCTest

@testable import HelloWorld

final class GreetingTests: XCTestCase {
    func testGreetings() {
        XCTAssertEqual(try greeting(), Greeting.default)
        for hour in 0 ..< 6 {
            XCTAssertEqual(try greeting(atHour: hour), Greeting.night)
        }
        for hour in 6 ..< 12 {
            XCTAssertEqual(try greeting(atHour: hour), Greeting.morning)
        }
        for hour in 12 ..< 18 {
            XCTAssertEqual(try greeting(atHour: hour), Greeting.afternoon)
        }
        for hour in 18 ..< 24 {
            XCTAssertEqual(try greeting(atHour: hour), Greeting.evening)
        }
        for hour in [-1, 24, 25] {
            XCTAssertThrowsError(try greeting(atHour: hour)) { error in
                if case GreetingError.invalidHour(let invalidHour) = error {
                    XCTAssertEqual(invalidHour, hour)
                } else {
                    XCTFail()
                }
            }
        }
    }
}
