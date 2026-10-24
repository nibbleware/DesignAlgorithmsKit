//
//  FallbackTextDecoder.swift
//  DesignAlgorithmsKit
//
//  Decode bytes of unknown encoding by trying a list of text decoding strategies in order.
//

import Foundation

// MARK: - Strategy

/// One way of turning bytes into text, for use with ``FallbackTextDecoder``.
///
/// Conform to add a character set that `String.Encoding` does not cover. Return `nil`
/// when the data is not valid in, or not recognized as, this character set, so that the
/// next strategy is tried.
public protocol TextDecodingStrategy: Sendable {
    /// A unique, human-readable name (for example `"utf-8"`); used as the registry key.
    var name: String { get }

    /// Decodes `data`, or returns `nil` when the data cannot be decoded by this strategy.
    func decode(_ data: Data) -> String?
}

/// A ``TextDecodingStrategy`` backed by a Foundation `String.Encoding`.
public struct StringEncodingStrategy: TextDecodingStrategy {
    public let name: String
    public let encoding: String.Encoding

    /// - Parameters:
    ///   - encoding: The Foundation encoding to decode with.
    ///   - name: The strategy name; defaults to the encoding's IANA charset name.
    public init(_ encoding: String.Encoding, name: String? = nil) {
        self.encoding = encoding
        self.name = name ?? StringEncodingStrategy.ianaName(for: encoding)
    }

    public func decode(_ data: Data) -> String? {
        String(data: data, encoding: encoding)
    }

    /// 7-bit US-ASCII (fails on any byte above 0x7F).
    public static let ascii = StringEncodingStrategy(.ascii, name: "us-ascii")
    /// UTF-8.
    public static let utf8 = StringEncodingStrategy(.utf8, name: "utf-8")
    /// Mac OS Roman.
    public static let macOSRoman = StringEncodingStrategy(.macOSRoman, name: "macintosh")
    /// Windows code page 1252.
    public static let windowsCP1252 = StringEncodingStrategy(.windowsCP1252, name: "windows-1252")

    private static func ianaName(for encoding: String.Encoding) -> String {
        let cfEncoding = CFStringConvertNSStringEncodingToEncoding(encoding.rawValue)
        if let iana = CFStringConvertEncodingToIANACharSetName(cfEncoding) {
            return iana as String
        }
        return "encoding-\(encoding.rawValue)"
    }
}

// MARK: - Result

/// Text produced by ``FallbackTextDecoder`` together with the strategy that produced it.
public struct DecodedText: Sendable, Equatable {
    /// The decoded text (control characters removed when the decoder strips them).
    public let text: String
    /// ``TextDecodingStrategy/name`` of the strategy that succeeded.
    public let strategyName: String

    public init(text: String, strategyName: String) {
        self.text = text
        self.strategyName = strategyName
    }
}

// MARK: - Decoder

/// Decodes bytes of unknown encoding by trying strategies in order.
///
/// Each strategy is tried in turn. When control-character stripping is on (the default),
/// control characters other than newlines and tabs are removed from the strategy's output.
/// The first strategy whose (stripped) output is non-empty wins. If none succeeds, the
/// result is `nil`.
///
/// The default order is US-ASCII, UTF-8, Mac OS Roman, Windows-1252. Because the last two
/// accept any byte sequence, strategies that must get a chance should go before them:
///
/// ```swift
/// let decoder = FallbackTextDecoder(before: [MyCharsetStrategy()])
/// let text = decoder.decode(bytes)
/// ```
public struct FallbackTextDecoder: Sendable {

    /// US-ASCII, UTF-8, Mac OS Roman, Windows-1252.
    public static let defaultStrategies: [any TextDecodingStrategy] = [
        StringEncodingStrategy.ascii,
        StringEncodingStrategy.utf8,
        StringEncodingStrategy.macOSRoman,
        StringEncodingStrategy.windowsCP1252,
    ]

    /// A decoder with the ``defaultStrategies`` and control-character stripping.
    public static let standard = FallbackTextDecoder()

    /// The strategies, in the order they are tried.
    public let strategies: [any TextDecodingStrategy]

    /// Whether control characters other than newlines and tabs are removed.
    public let stripsControlCharacters: Bool

    /// Creates a decoder that tries exactly `strategies`, in order.
    public init(strategies: [any TextDecodingStrategy] = FallbackTextDecoder.defaultStrategies,
                stripsControlCharacters: Bool = true) {
        self.strategies = strategies
        self.stripsControlCharacters = stripsControlCharacters
    }

    /// Creates a decoder that tries `before`, then the ``defaultStrategies``, then `after`.
    public init(before: [any TextDecodingStrategy],
                after: [any TextDecodingStrategy] = [],
                stripsControlCharacters: Bool = true) {
        self.init(strategies: before + FallbackTextDecoder.defaultStrategies + after,
                  stripsControlCharacters: stripsControlCharacters)
    }

    /// Returns the decoded text, or `nil` when no strategy yields non-empty text.
    public func decode(_ data: Data) -> String? {
        decodeWithStrategy(data)?.text
    }

    /// Returns the decoded text and the name of the strategy that produced it,
    /// or `nil` when no strategy yields non-empty text.
    public func decodeWithStrategy(_ data: Data) -> DecodedText? {
        for strategy in strategies {
            guard let decoded = strategy.decode(data) else { continue }
            let text = stripsControlCharacters
                ? FallbackTextDecoder.removingControlCharacters(from: decoded)
                : decoded
            if !text.isEmpty {
                return DecodedText(text: text, strategyName: strategy.name)
            }
        }
        return nil
    }

    /// Removes characters containing a Unicode control or format scalar
    /// (`CharacterSet.controlCharacters`), keeping newlines and tabs.
    public static func removingControlCharacters(from string: String) -> String {
        string.filter { character in
            if character.isNewline || character == "\t" { return true }
            return !character.unicodeScalars.contains { CharacterSet.controlCharacters.contains($0) }
        }
    }
}

// MARK: - Registry

/// A thread-safe set of named text decoding strategies that libraries can add to at
/// start-up, and from which callers build a ``FallbackTextDecoder``.
///
/// Registered strategies go before or after the ``FallbackTextDecoder/defaultStrategies``.
/// Within a placement, a higher `priority` is tried first; equal priorities are ordered by
/// name. Registering a strategy whose name is already registered replaces it.
///
/// ```swift
/// TextDecoderRegistry.shared.register(MyCharsetStrategy(), placement: .beforeDefaults)
/// let text = TextDecoderRegistry.shared.decode(bytes)
/// ```
public final class TextDecoderRegistry: Registry<String, TextDecoderRegistry.Entry>, @unchecked Sendable {

    /// Where a registered strategy sits relative to the default strategies.
    public enum Placement: Sendable, Equatable {
        case beforeDefaults
        case afterDefaults
    }

    /// A registered strategy and its ordering.
    public struct Entry: Sendable {
        public let strategy: any TextDecodingStrategy
        public let placement: Placement
        public let priority: Int

        public init(strategy: any TextDecodingStrategy, placement: Placement, priority: Int = 0) {
            self.strategy = strategy
            self.placement = placement
            self.priority = priority
        }
    }

    /// Process-wide registry for composition roots. Prefer passing a registry or a
    /// ``FallbackTextDecoder`` explicitly where possible.
    public static let shared = TextDecoderRegistry()

    public override init() {
        super.init()
    }

    /// Registers `strategy` under its ``TextDecodingStrategy/name``, replacing any entry with that name.
    public func register(_ strategy: any TextDecodingStrategy,
                         placement: Placement = .beforeDefaults,
                         priority: Int = 0) {
        register(Entry(strategy: strategy, placement: placement, priority: priority), for: strategy.name)
    }

    /// The registered strategies for `placement`, in the order they are tried.
    public func strategies(placement: Placement) -> [any TextDecodingStrategy] {
        all()
            .filter { $0.placement == placement }
            .sorted { lhs, rhs in
                lhs.priority != rhs.priority ? lhs.priority > rhs.priority : lhs.strategy.name < rhs.strategy.name
            }
            .map(\.strategy)
    }

    /// Builds a decoder: registered `.beforeDefaults`, the defaults, registered `.afterDefaults`.
    public func makeDecoder(stripsControlCharacters: Bool = true) -> FallbackTextDecoder {
        FallbackTextDecoder(before: strategies(placement: .beforeDefaults),
                            after: strategies(placement: .afterDefaults),
                            stripsControlCharacters: stripsControlCharacters)
    }

    /// Decodes `data` with ``makeDecoder(stripsControlCharacters:)``.
    public func decode(_ data: Data) -> String? {
        makeDecoder().decode(data)
    }
}

// MARK: - Data convenience

extension Data {
    /// Decodes these bytes as text with `decoder` (by default ``FallbackTextDecoder/standard``:
    /// US-ASCII, UTF-8, Mac OS Roman, Windows-1252, control characters stripped).
    /// - Returns: The text, or `nil` when no strategy yields non-empty text.
    public func decodedText(using decoder: FallbackTextDecoder = .standard) -> String? {
        decoder.decode(self)
    }
}
