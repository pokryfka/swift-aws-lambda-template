import XCTest

import AWSXRayRecorderTests
import HelloWorldTests

var tests = [XCTestCaseEntry]()
tests += AWSXRayRecorderTests.__allTests()
tests += HelloWorldTests.__allTests()

XCTMain(tests)
