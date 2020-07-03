import XCTest

@testable import HelloWorld

final class HelloWorldTests: XCTestCase {
    func testTimeZoneIdentifiersValid() {
        for tz in ["UTC", "UTC+2", "UTC-1"] {
            XCTAssertNoThrow(try hour(inTimeZone: tz))
        }
    }

    func testTimeZoneIdentifiersInvalid() {
        for tz in ["utc", "UTC+24", "UTC-24"] {
            XCTAssertThrowsError(try hour(inTimeZone: tz)) { error in
                if case DateError.invalidTimeZone(let invalidIdentifier) = error {
                    XCTAssertEqual(invalidIdentifier, tz)
                } else {
                    XCTFail()
                }
            }
        }
    }

    func testGreetings() {
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

    static var allTests = [
        ("testGreetings", testGreetings),
    ]
}
