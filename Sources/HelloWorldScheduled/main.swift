import AWSLambdaEvents
import AWSLambdaRuntime
import Backtrace
import HelloWorld

Backtrace.install()

// MARK: Using Closures

#if false

private let handler: Lambda.CodableVoidClosure<Cloudwatch.ScheduledEvent> = {
    context, _, callback in
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

import AWSXRaySDK
import NIO

private struct HelloWorldScheduledHandler: EventLoopLambdaHandler {
    typealias In = Cloudwatch.ScheduledEvent
    typealias Out = Void

    private let recorder = XRayRecorder()

    func handle(context: Lambda.Context, event: In) -> EventLoopFuture<Void> {
        let traceContext: XRayRecorder.TraceContext = (try? .init(tracingHeader: context.traceID)) ?? .init()
        try? recorder.segment(name: "HelloWorldScheduledHandler", context: traceContext) { segment in
            let greetingHour = try segment.subsegment(name: "Hour") { _ in try hour() }
            let greetingMessage = try segment.subsegment(name: "Greeting") { _ in try greeting(atHour: greetingHour) }
            context.logger.info("\(greetingMessage)")
        }
        return recorder.flush(on: context.eventLoop)
    }
}

Lambda.run(HelloWorldScheduledHandler())

#endif
