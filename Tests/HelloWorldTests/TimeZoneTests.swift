import XCTest

@testable import HelloWorld

import struct Foundation.TimeZone

final class TimeZoneTests: XCTestCase {
    // TODO: expose in HelloWorld?
    static let knownTimeZones: [String] = {
        TimeZone.knownTimeZoneIdentifiers
            .compactMap(TimeZone.init(identifier:))
            .map { "\($0.identifier) (\($0.abbreviation() ?? "?"))" }
            .sorted()
    }()

    func addKnownTimeZonesAttachment() {
        // TODO: does not work when running commandline:
        // "Internal error: Attachments cannot be added to the test because activities are disabled."
        #if false
        let attachment = XCTAttachment(string: Self.knownTimeZones.joined(separator: "\n"))
        attachment.name = "Known Time Zones"
        attachment.lifetime = .deleteOnSuccess
        add(attachment)
//        #else
//        print("Known Time Zones:", Self.knownTimeZones.joined(separator: "\n"))
        #endif
    }

    func testTimeZoneIdentifiersValid() {
        addKnownTimeZonesAttachment()
        let validIdentifiers = [
            "UTC",
            "GMT",
            "Europe/Warsaw",
            "Asia/Taipei",
            "CST",
//            "UTC+2",
//            "UTC-1"
        ]
        for tz in validIdentifiers {
            XCTAssertNoThrow(try hour(inTimeZone: tz))
        }
    }

    func testTimeZoneIdentifiersInvalid() {
        addKnownTimeZonesAttachment()
        let invalidIdentifiers = [
            "utc",
            "UTC+24",
            "UTC-24",
        ]
        for tz in invalidIdentifiers {
            XCTAssertThrowsError(try hour(inTimeZone: tz)) { error in
                if case DateError.invalidTimeZone(let invalidIdentifier) = error {
                    XCTAssertEqual(invalidIdentifier, tz)
                } else {
                    XCTFail()
                }
            }
        }
    }
}
