import XCTest

#if !canImport(ObjectiveC)
    public func allTests() -> [XCTestCaseEntry] {
        return [
            testCase(swift_aws_lambda_templateTests.allTests)
        ]
    }
#endif
