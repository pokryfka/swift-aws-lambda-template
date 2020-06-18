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
        emmiter = XRayEmmiter(eventLoop: eventLoop, endpoint: Lambda.env("XRAY_ENDPOINT"))
        self.lambdaHandler = lambdaHandler
    }

    public func handle(context: Lambda.Context, payload: In) -> EventLoopFuture<Void> {
        let tracingHeader: TracingHeaderValue
        if let value = try? TracingHeaderValue(string: context.traceID) {
            tracingHeader = value
        } else {
            context.logger.error("Invalid TracingHeader: \(context.traceID)")
            tracingHeader = TracingHeaderValue()
        }
        let recorder = XRayRecorder()
        recorder.beginSubSegment(
            name: "XRayLambdaHandlerSubSegment", traceId: String(describing: tracingHeader.root),
            parentId: tracingHeader.parentId)
        return lambdaHandler.handle(context: context, payload: payload)
            .flatMap { _ in recorder.sendSegments(emmiter: self.emmiter) }
    }
}