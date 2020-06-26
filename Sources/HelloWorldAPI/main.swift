import AWSLambdaEvents
import AWSLambdaRuntime
import Backtrace
import HelloWorld

import struct Foundation.Data
import struct Foundation.Date
import class Foundation.JSONDecoder
import class Foundation.JSONEncoder

Backtrace.install()

// TODO: simplify, see also https://github.com/swift-server/swift-aws-lambda-runtime/pull/129

extension JSONDecoder {
    fileprivate func decode<T: Decodable>(type: T.Type, from string: String) throws -> T {
        try decode(type, from: Data(string.utf8))
    }
}

extension JSONEncoder {
    fileprivate func encode<T: Encodable>(value: T) throws -> String {
        String(decoding: try encode(value), as: UTF8.self)
    }
}

private let jsonDecoder = JSONDecoder()

private let jsonEncoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    encoder.dateEncodingStrategy = .iso8601
    return encoder
}()

private struct HelloWorldIn: Decodable {
    let secondsFromGMT: Int
}

private struct HelloWorldOut: Encodable {
    let now: Date
    let secondsFromGMT: Int
    let hour: Int
    let message: Greeting
}

// MARK: Using Closures

#if false

private let handler: Lambda.CodableClosure<APIGateway.Request, APIGateway.Response> = { context, request, callback in
    do {
        let now = Date()
        let secondsFromGMT: Int
        if let body = request.body {
            let input = try jsonDecoder.decode(type: HelloWorldIn.self, from: body)
            secondsFromGMT = input.secondsFromGMT
        } else {
            secondsFromGMT = 0
        }
        let greetingHour = try hour(onDate: now, inTimeZoneWithSecondsFromGMT: secondsFromGMT)
        let greetingMessage = try greeting(atHour: greetingHour)
        let output = HelloWorldOut(
            now: now,
            secondsFromGMT: secondsFromGMT,
            hour: greetingHour,
            message: greetingMessage
        )
        let body: String? = try jsonEncoder.encode(value: output)
        let response = APIGateway.Response(
            statusCode: HTTPResponseStatus.ok,
            headers: ["Content-Type": "application/json"],
            body: body
        )
        callback(.success(response))
    } catch let error as DecodingError {
        context.logger.error("DecodingError: \(error)")
        let response = APIGateway.Response(statusCode: HTTPResponseStatus.badRequest)
        callback(.success(response))
    } catch {
        context.logger.error("AnError: \(error)")
        let response = APIGateway.Response(statusCode: HTTPResponseStatus.internalServerError)
        callback(.success(response))
    }
}

Lambda.run(handler)

#else

import NIO

private struct HelloWorldAPIHandler: EventLoopLambdaHandler {
    typealias In = APIGateway.Request
    typealias Out = APIGateway.Response

    func handle(context: Lambda.Context, event: In) -> EventLoopFuture<Out> {
        do {
            let now = Date()
            let secondsFromGMT: Int
            if let body = event.body {
                let input = try jsonDecoder.decode(type: HelloWorldIn.self, from: body)
                secondsFromGMT = input.secondsFromGMT
            } else {
                secondsFromGMT = 0
            }
            let greetingHour = try hour(onDate: now, inTimeZoneWithSecondsFromGMT: secondsFromGMT)
            let greetingMessage = try greeting(atHour: greetingHour)
            let output = HelloWorldOut(
                now: now,
                secondsFromGMT: secondsFromGMT,
                hour: greetingHour,
                message: greetingMessage
            )
            let body: String? = try jsonEncoder.encode(value: output)
            let response = APIGateway.Response(
                statusCode: HTTPResponseStatus.ok,
                headers: ["Content-Type": "application/json"],
                body: body
            )
            return context.eventLoop.makeSucceededFuture(response)
        } catch let error as DecodingError {
            context.logger.error("DecodingError: \(error)")
            let response = APIGateway.Response(statusCode: HTTPResponseStatus.badRequest)
            return context.eventLoop.makeSucceededFuture(response)
        } catch {
            context.logger.error("AnError: \(error)")
            let response = APIGateway.Response(statusCode: HTTPResponseStatus.internalServerError)
            return context.eventLoop.makeSucceededFuture(response)
        }
    }
}

Lambda.run(HelloWorldAPIHandler())

#endif
