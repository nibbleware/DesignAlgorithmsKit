import Foundation

/// Errors from ``DataReader`` and the checked ``BinaryDataReader`` methods.
public enum BinaryReadError: Error, Equatable, Sendable {
    /// `count` bytes were needed at `offset`, but only `available` bytes exist past it
    /// (0 when the offset itself is outside the data).
    case outOfBounds(offset: Int, count: Int, available: Int)
}

/// Byte order of a multi-byte field.
public enum ByteOrder: Sendable {
    case big
    case little
}
