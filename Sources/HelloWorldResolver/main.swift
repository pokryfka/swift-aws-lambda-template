import AWSLambdaEvents
import AWSLambdaRuntime
import Backtrace
import HelloWorld

Backtrace.install()

// private struct HelloWorldIn: Decodable {
//    let secondsFromGMT: Int
// }

private struct HelloWorldOut: Encodable {
    let hour: Int?
    let message: Greeting
}

private let handler: Lambda.CodableClosure<Amplify.Request, HelloWorldOut> = { context, request, callback in
    do {
        context.logger.debug("request: \(request)")
        let secondsFromGMT: Int
        if let value = request.arguments?["secondsFromGMT"]?.value as? Int {
            context.logger.info("secondsFromGMT: \(value)")
            secondsFromGMT = value
        } else {
            secondsFromGMT = 0
        }
        let greetingHour = try hour(inTimeZoneWithSecondsFromGMT: secondsFromGMT)
        let greetingMessage = try greeting(atHour: greetingHour)
        let output = HelloWorldOut(hour: greetingHour, message: greetingMessage)
        callback(.success(output))
    } catch {
        context.logger.error("AnError: \(error)")
        callback(.failure(error))
    }
}

Lambda.run(handler)
