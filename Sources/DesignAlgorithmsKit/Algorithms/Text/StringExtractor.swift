import Foundation

/// Finds printable text runs in binary data, like the Unix `strings` command.
public enum StringExtractor {
    /// Default minimum run length kept by ``extractStrings(from:minLength:maxLength:)``.
    public static let minimumStringLength = 4

    /// Default maximum length of each returned run.
    public static let maximumStringLength = 256

    /// Returns each run of printable bytes, in order.
    ///
    /// A run is a sequence of bytes in 32...126 or 160...255 (read as Latin-1), tab, line feed
    /// or carriage return. Each run is truncated to `maxLength` characters, trimmed of
    /// surrounding whitespace and newlines, and kept when at least `minLength` characters remain.
    ///
    /// Runs are gathered as bytes and turned into a string once, so the time is linear in the
    /// data's size.
    public static func extractStrings(
        from data: Data,
        minLength: Int = minimumStringLength,
        maxLength: Int = maximumStringLength
    ) -> [String] {
        var strings: [String] = []
        var run: [UInt8] = []
        run.reserveCapacity(maxLength)
        // Characters in `run`: a carriage return and the line feed after it are one Character.
        var characters = 0

        func flush() {
            defer { run.removeAll(keepingCapacity: true); characters = 0 }
            var trimmed = ""
            if let first = run.firstIndex(where: { !isWhitespaceOrNewline($0) }),
               let last = run.lastIndex(where: { !isWhitespaceOrNewline($0) }) {
                trimmed = String(String.UnicodeScalarView(run[first...last].map { Unicode.Scalar($0) }))
            }
            if trimmed.count >= minLength {
                strings.append(trimmed)
            }
        }

        for byte in data {
            if (32...126).contains(byte) || byte >= 160 || byte == 9 || byte == 10 || byte == 13 {
                guard characters < maxLength else { continue }
                run.append(byte)
                if !(byte == 10 && run.dropLast().last == 13) {
                    characters += 1  // a line feed after a carriage return joins its Character
                }
            } else {
                flush()
            }
        }
        flush()
        return strings
    }

    /// Latin-1 bytes in `CharacterSet.whitespacesAndNewlines`: tab, line feed, carriage return,
    /// space and no-break space (the printable set has no other).
    private static func isWhitespaceOrNewline(_ byte: UInt8) -> Bool {
        byte == 32 || byte == 9 || byte == 10 || byte == 13 || byte == 0xA0
    }
}
