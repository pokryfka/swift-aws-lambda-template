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

import AWSXRayRecorder
import AWSXRayRecorderLambda
import NIO

private struct HelloWorldScheduledHandler: EventLoopLambdaHandler {
    typealias In = Cloudwatch.ScheduledEvent
    typealias Out = Void

    private let recorder = XRayRecorder()
    private let emmiter: XRayEmmiter

    init(eventLoop: EventLoop) {
        emmiter = XRayEmmiter(eventLoop: eventLoop, endpoint: Lambda.env("XRAY_ENDPOINT"))
    }

    func handle(context: Lambda.Context, event: In) -> EventLoopFuture<Void> {
        try? recorder.segment(name: "HelloWorldScheduledHandler", context: context) { _ in
            let greetingHour = try hour()
            let greetingMessage = try greeting(atHour: greetingHour)
            context.logger.info("\(greetingMessage)")
        }
        return emmiter.send(segments: recorder.removeReady())
    }
}

Lambda.run { context in HelloWorldScheduledHandler(eventLoop: context.eventLoop) }

#endif
