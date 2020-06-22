import AWSXRayRecorderTests
import HelloWorldTests
import XCTest

var tests = [XCTestCaseEntry]()
tests += AWSXRayRecorderTests.__allTests()
tests += HelloWorldTests.__allTests()

XCTMain(tests)
