import AWSLambdaEvents
import AWSLambdaRuntime
import AWSXRayRecorder
import Backtrace
import HelloWorld
import NIO

Backtrace.install()

private struct HelloWorldScheduledHandler: EventLoopLambdaHandler {
    typealias In = Cloudwatch.ScheduledEvent
    typealias Out = Void

    func handle(context: Lambda.Context, payload: In) -> EventLoopFuture<Void> {
        do {
            let greetingHour = try hour()
            let greetingMessage = try greeting(atHour: greetingHour)
            context.logger.info("\(greetingMessage)")
            return context.eventLoop.makeSucceededFuture(())
        } catch {
            return context.eventLoop.makeFailedFuture(error)
        }
    }
}

#if DEBUG
    try Lambda.withLocalServer {
        Lambda.run {
            XRayLambdaHandler(
                eventLoop: $0,
                lambdaHandler: HelloWorldScheduledHandler())
        }
    }
#else
    Lambda.run {
        XRayLambdaHandler(
            eventLoop: $0,
            lambdaHandler: HelloWorldScheduledHandler())
    }
#endif
