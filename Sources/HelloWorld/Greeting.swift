/// Greeting message.
public enum Greeting: String, CustomStringConvertible, Encodable {
    case morning = "Good morning"
    case afternoon = "Good afternoon"
    case evening = "Good evening"
    case night = "Good night"
    case `default` = "Good day"

    public var description: String {
        rawValue
    }
}

enum GreetingError: Error {
    case invalidHour(Int)
}

/// Returns an appropriate greeting message at specified time of the day.
///
/// - Parameter hour: hour, 0-23
/// - Throws: may throw `GreetingError.invalidHour` if the hour is not valid
/// - Returns: greeting message
public func greeting(atHour hour: Int? = nil) throws -> Greeting {
    guard let hour = hour else { return .default }
    switch hour {
    case 0 ..< 6:
        return .night
    case 6 ..< 12:
        return .morning
    case 12 ..< 18:
        return .afternoon
    case 18 ..< 24:
        return .evening
    default:
        throw GreetingError.invalidHour(hour)
    }
}
