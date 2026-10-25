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
    public static func extractStrings(
        from data: Data,
        minLength: Int = minimumStringLength,
        maxLength: Int = maximumStringLength
    ) -> [String] {
        var strings: [String] = []
        var current = ""

        func flush() {
            let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count >= minLength {
                strings.append(trimmed)
            }
            current = ""
        }

        for byte in data {
            if (32...126).contains(byte) || byte >= 160 || byte == 9 || byte == 10 || byte == 13 {
                if current.count < maxLength {
                    current.append(Character(UnicodeScalar(byte)))
                }
            } else {
                flush()
            }
        }
        flush()
        return strings
    }
}
