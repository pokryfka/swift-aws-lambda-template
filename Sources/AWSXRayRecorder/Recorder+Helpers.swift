extension XRayRecorder {
    @inlinable
    public func segment<T>(name: String, parentId: String? = nil, body: (Segment) throws -> T)
        rethrows -> T
    {
        let segment = beginSegment(name: name, parentId: parentId)
        defer {
            segment.end()
        }
        return try body(segment)
    }

    @inlinable
    public func segment<T>(name: String, traceHeader: TraceHeader?, body: (Segment) throws -> T)
        rethrows
        -> T
    {
        let segment = beginSegment(name: name, traceHeader: traceHeader)
        defer {
            segment.end()
        }
        return try body(segment)
    }
}

extension XRayRecorder.Segment {
    @inlinable
    public func subSegment<T>(name: String, body: (XRayRecorder.Segment) throws -> T) rethrows -> T
    {
        let newSegment = beginSubSegment(name: name)
        defer {
            newSegment.end()
        }
        return try body(newSegment)
    }
}
