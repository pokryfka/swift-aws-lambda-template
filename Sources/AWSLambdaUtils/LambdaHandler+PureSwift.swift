import AWSLambdaRuntimeCore
import NIO
import PureSwiftJSON

/// Implementation of  a`ByteBuffer` to `In` decoding
public extension EventLoopLambdaHandler where In: Decodable {
    func decode(buffer: ByteBuffer) throws -> In {
        try decoder.decode(In.self, from: buffer)
    }
}

/// Implementation of  `Out` to `ByteBuffer` encoding
public extension EventLoopLambdaHandler where Out: Encodable {
    func encode(allocator: ByteBufferAllocator, value: Out) throws -> ByteBuffer? {
        try encoder.encode(value, using: allocator)
    }
}

/// Default `ByteBuffer` to `In` decoder using Foundation's JSONDecoder
/// Advanced users that want to inject their own codec can do it by overriding these functions.
public extension EventLoopLambdaHandler where In: Decodable {
    var decoder: PSJSONDecoder {
        Lambda.defaultJSONDecoder
    }
}

/// Default `Out` to `ByteBuffer` encoder using Foundation's JSONEncoder
/// Advanced users that want to inject their own codec can do it by overriding these functions.
public extension EventLoopLambdaHandler where Out: Encodable {
    var encoder: PSJSONEncoder {
        Lambda.defaultJSONEncoder
    }
}

public protocol LambdaCodableDecoder {
    func decode<T: Decodable>(_ type: T.Type, from buffer: ByteBuffer) throws -> T
}

public protocol LambdaCodableEncoder {
    func encode<T: Encodable>(_ value: T, using allocator: ByteBufferAllocator) throws -> ByteBuffer
}

private extension Lambda {
    static let defaultJSONDecoder = PSJSONDecoder()
    static let defaultJSONEncoder = PSJSONEncoder()
}

extension PSJSONDecoder: LambdaCodableDecoder {
    public func decode<T>(_ type: T.Type, from buffer: ByteBuffer) throws -> T where T: Decodable {
        let bytes = buffer.getBytes(at: 0, length: buffer.readableBytes)!
        return try decode(type, from: bytes)
    }
}

extension PSJSONEncoder: LambdaCodableEncoder {
    public func encode<T>(_ value: T, using allocator: ByteBufferAllocator) throws -> ByteBuffer where T: Encodable {
        // nio will resize the buffer if necessary

        let bytes = try encode(value)
        var buffer = allocator.buffer(capacity: bytes.count)
        buffer.writeBytes(bytes)
        return buffer
    }
}
