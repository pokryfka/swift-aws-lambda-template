import Dispatch
import NIO

@testable import AWSXRayRecorder

class MockEmmiter: Emmiter {
    let eventLoop: EventLoop = DummyEventLoop()
    private(set) var documents = [[Segment]]()

    func send(segments: [Segment]) -> EventLoopFuture<Void> {
        documents.append(segments)
        return eventLoop.makeSucceededFuture(())
    }
}

private class DummyEventLoop: EventLoop {
    var inEventLoop: Bool = false

    func execute(_ task: @escaping () -> Void) {
        fatalError()
    }

    func scheduleTask<T>(deadline: NIODeadline, _ task: @escaping () throws -> T) -> Scheduled<T> {
        fatalError()
    }

    func scheduleTask<T>(in: TimeAmount, _ task: @escaping () throws -> T) -> Scheduled<T> {
        fatalError()
    }

    func shutdownGracefully(queue: DispatchQueue, _ callback: @escaping (Error?) -> Void) {
        fatalError()
    }
}
