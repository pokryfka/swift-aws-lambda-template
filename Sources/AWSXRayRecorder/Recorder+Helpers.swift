extension XRayRecorder {
    @inlinable
    public func segment<T>(name: String, parentId: String? = nil, body: (Segment) throws -> T)
        rethrows -> T
    {
        let segment = beginSegment(name: name, parentId: parentId)
        defer {
            segment.end()
        }
        do {
            return try body(segment)
        } catch {
            segment.setError(error)
            throw error
        }
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
        do {
            return try body(segment)
        } catch {
            segment.setError(error)
            throw error
        }
    }
}

extension XRayRecorder.Segment {
    @inlinable
    public func subsegment<T>(name: String, body: (XRayRecorder.Segment) throws -> T) rethrows -> T
    {
        let segment = beginSubsegment(name: name)
        defer {
            segment.end()
        }
        do {
            return try body(segment)
        } catch {
            segment.setError(error)
            throw error
        }
    }
}
