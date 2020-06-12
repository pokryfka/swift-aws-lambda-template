//
//  Date.swift
//  
//
//  Created by Michał A on 2020/6/12.
//

import struct Foundation.Calendar
import struct Foundation.Date
import protocol Foundation.LocalizedError
import struct Foundation.TimeZone

public enum DateError: Error {
    case invalidTimeZone(secondsFromGMT: Int)
    case failedToResolveHour
}

extension DateError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidTimeZone(let secondsFromGMT):
            return "Invalid TimeZone with secondsFromGMT: \(secondsFromGMT)"
        case .failedToResolveHour:
            return "Failed to resolve hour"
        }
    }
}

public func hour(onDate date: Date = Date(), inTimeZone timeZone: TimeZone) throws
    -> Int
{
    var calendar = Calendar.current
    calendar.timeZone = timeZone
    let components = calendar.dateComponents([.hour], from: date)
    guard let hour = components.hour else {
        throw DateError.failedToResolveHour
    }
    return hour
}

public func hour(
    onDate date: Date = Date(), inTimeZoneWithSecondsFromGMT secondsFromGMT: Int
) throws -> Int {
    guard let timeZone = TimeZone(secondsFromGMT: secondsFromGMT) else {
        throw DateError.invalidTimeZone(secondsFromGMT: secondsFromGMT)
    }
    return try hour(onDate: date, inTimeZone: timeZone)
}
