import struct Foundation.Calendar
import struct Foundation.Date
import protocol Foundation.LocalizedError
import struct Foundation.TimeZone

public enum DateError: Error {
    case invalidTimeZone(identifier: String)
    case failedToResolveHour
}

extension DateError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidTimeZone(let identifier):
            return "Invalid TimeZone identifier: \(identifier)"
        case .failedToResolveHour:
            return "Failed to resolve hour"
        }
    }
}

public func hour(on date: Date = Date(), inTimeZone timeZoneIdentifier: String? = nil) throws
    -> Int
{
    let timeZoneIdentifier = timeZoneIdentifier ?? "UTC"
    guard let timeZone = TimeZone(identifier: timeZoneIdentifier) else {
        throw DateError.invalidTimeZone(identifier: timeZoneIdentifier)
    }
    var calendar = Calendar.current
    calendar.timeZone = timeZone
    let components = calendar.dateComponents([.hour], from: date)
    guard let hour = components.hour else {
        throw DateError.failedToResolveHour
    }
    return hour
}
