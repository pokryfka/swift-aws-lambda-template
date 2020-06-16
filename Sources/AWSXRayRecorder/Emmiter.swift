import NIO

protocol Emmiter {
    var eventLoop: EventLoop { get }
    func send(segments: [Segment]) -> EventLoopFuture<Void>
}
