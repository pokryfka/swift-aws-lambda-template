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

    private let recorder = XRayRecorder()
    private let emmiter: XRayEmmiter

    init(eventLoop: EventLoop) {
        emmiter = XRayEmmiter(eventLoop: eventLoop, endpoint: Lambda.env("XRAY_ENDPOINT"))
    }

    private func sendXRaySegments() -> EventLoopFuture<Void> {
        emmiter.send(segments: recorder.segments)
    }

    func shutdown(context: Lambda.ShutdownContext) -> EventLoopFuture<Void> {
        return context.eventLoop.makeSucceededFuture(())
    }

    func handle(context: Lambda.Context, event: In) -> EventLoopFuture<Void> {
        do {
            let traceHeader = try? XRayRecorder.TraceHeader(string: context.traceID)
            try recorder.segment(
                name: "HelloWorldScheduledHandler",
                traceHeader: traceHeader
            ) { segment in
                let greetingHour = try segment.subSegment(name: "Greeting Hour") { _ in
                    try hour()
                }
                segment.subSegment(name: "Subsegment A") { segment in
                    segment.subSegment(name: "Subsegment A.1") { _ in }
                    segment.subSegment(name: "Subsegment A.2") { _ in }
                }
                let greetingMessage = try segment.subSegment(name: "Greeting Message") { _ in
                    try greeting(atHour: greetingHour)
                }
                context.logger.info("\(greetingMessage)")
            }
            return context.eventLoop.makeSucceededFuture(())
                .flatMap { self.sendXRaySegments() }
        } catch {
            return context.eventLoop.makeFailedFuture(error)
        }
    }
}

Lambda.run { context in HelloWorldScheduledHandler(eventLoop: context.eventLoop) }
