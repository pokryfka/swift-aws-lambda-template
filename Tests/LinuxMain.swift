import AWSXRayRecorderTests
import HelloWorldTests
import XCTest

var tests = [XCTestCaseEntry]()
tests += HelloWorldTests.allTests()
tests += AWSXrayRecorderTests.allTests()
tests += AWSXRaySegmentTests.allTests()
XCTMain(tests)
