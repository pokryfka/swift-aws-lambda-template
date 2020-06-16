import XCTest

#if !canImport(ObjectiveC)
    public func allTests() -> [XCTestCaseEntry] {
        return [
            testCase(AWSXRaySegmentTests.allTests),
            testCase(AWSXRayRecorderTests.allTests),
        ]
    }
#endif
