import AWSLambdaEvents
import AWSLambdaRuntime
import Backtrace
import HelloWorld

Backtrace.install()

// MARK: Using Closures

#if false

private let handler: Lambda.CodableVoidClosure<Cloudwatch.ScheduledEvent> = { context, _, callback in
    do {
        let greetingHour = try hour()
        let greetingMessage = try greeting(atHour: greetingHour)
        context.logger.info("\(greetingMessage)")
        callback(.success(()))
    } catch {
        context.logger.error("AnError: \(error)")
        callback(.failure(error))
    }
}

Lambda.run(handler)

#else

// MARK: Using EventLoopLambdaHandler

import NIO

private struct HelloWorldScheduledHandler: EventLoopLambdaHandler {
    typealias In = Cloudwatch.ScheduledEvent
    typealias Out = Void

    func handle(context: Lambda.Context, event: In) -> EventLoopFuture<Out> {
        do {
            let greetingHour = try hour()
            let greetingMessage = try greeting(atHour: greetingHour)
            context.logger.info("\(greetingMessage)")
            return context.eventLoop.makeSucceededFuture(Void())
        } catch {
            context.logger.error("AnError: \(error)")
            return context.eventLoop.makeFailedFuture(error)
        }
    }
}

Lambda.run(HelloWorldScheduledHandler())

#endif
