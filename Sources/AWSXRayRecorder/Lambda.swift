import AWSLambdaRuntime
import AWSXRay
import AsyncHTTPClient
import NIO

public class XRayLambdaHandler<In: Decodable, Handler: EventLoopLambdaHandler>:
    EventLoopLambdaHandler
where Handler.In == In, Handler.Out == Void {
    public typealias In = In
    public typealias Out = Void

    private let emmiter: Emmiter

    private let lambdaHandler: Handler

    public init(eventLoop: EventLoop, lambdaHandler: Handler) {
        emmiter = XRayEmmiter(eventLoop: eventLoop)
        self.lambdaHandler = lambdaHandler
    }

    public func handle(context: Lambda.Context, payload: In) -> EventLoopFuture<Void> {
        do {
            let traceIdHeaderValue = try TracingHeaderValue(string: context.traceID)
            let recorder = XRayRecorder()  // TODO: pass Lambda.Context in ctor?
            recorder.beginSubSegment(
                name: "XRayLambdaHandler", traceId: traceIdHeaderValue.root,
                parentId: traceIdHeaderValue.parentId)
            return lambdaHandler.handle(context: context, payload: payload)
                .flatMap { _ in recorder.sendSegments(emmiter: self.emmiter) }
                .map { result in
                    context.logger.info("XRayRecorder.sendSegments result: \(result)")
                    return
                }
        } catch {
            context.logger.error("XRayLambdaHandler failed: \(error)")
            return context.eventLoop.makeFailedFuture(error)
        }
    }
}
