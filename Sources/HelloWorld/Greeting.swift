//
//  Greeting.swift
//  
//
//  Created by Michał A on 2020/6/11.
//

import Foundation

public enum GreetingError: Error {
    case invalidTimeZone(secondsFromGMT: Int)
    case invalidHour(Int)
    case failedToResolveHour
}

extension GreetingError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidTimeZone(let secondsFromGMT):
            return "Invalid TimeZone with secondsFromGMT: \(secondsFromGMT)"
        case .invalidHour(let hour):
            return "Invalid hour: \(hour)"
        case .failedToResolveHour:
            return "Failed to resolve hour"
        }
    }
}

public enum Greeting: String, Encodable {
    case morning = "Good morning"
    case afternoon = "Good afternoon"
    case evening = "Good evening"
    case night = "Good night"
    case `default` = "Good day"
}

public func hour(onDate date: Date = Date(), inTimeZone timeZone: TimeZone) throws
    -> Int
{
    var calendar = Calendar.current
    calendar.timeZone = timeZone
    let components = calendar.dateComponents([.hour], from: date)
    guard let hour = components.hour else {
        throw GreetingError.failedToResolveHour
    }
    return hour
}

public func hour(
    onDate date: Date = Date(), inTimeZoneWithSecondsFromGMT secondsFromGMT: Int
) throws -> Int {
    guard let timeZone = TimeZone(secondsFromGMT: secondsFromGMT) else {
        throw GreetingError.invalidTimeZone(secondsFromGMT: secondsFromGMT)
    }
    return try hour(onDate: date, inTimeZone: timeZone)
}

public func greeting(atHour hour: Int) throws -> Greeting {
    switch hour {
    case 0..<6:
        return .night
    case 6..<12:
        return .morning
    case 12..<18:
        return .afternoon
    case 18..<24:
        return .evening
    default:
        throw GreetingError.invalidHour(hour)
    }
}
