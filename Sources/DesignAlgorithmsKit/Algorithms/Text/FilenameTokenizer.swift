import Foundation

public struct FilenameTokenizer {
    
    /// Tokenizes a filename into constituent words.
    /// Handles camelCase, snake_case, kebab-case, and alphanumeric transitions.
    ///
    /// Examples:
    /// - "PDFExtractor.swift" -> ["PDF", "Extractor", "swift"]
    /// - "disk_ii_controller" -> ["disk", "ii", "controller"]
    /// - "iPhone12Pro" -> ["iPhone", "12", "Pro"]
    public static func tokenize(_ filename: String) -> [String] {
        // 1. Replace common separators with spaces
        let separators = CharacterSet(charactersIn: "_-.")
        let clean = filename.components(separatedBy: separators).joined(separator: " ")
        
        // 2. Regex for CamelCase and Number transitions
        // ([a-z])([A-Z]) -> Lower followed by Upper (e.g. fooBar)
        let pattern1 = "([a-z])([A-Z])"
        
        // ([A-Z])([A-Z][a-z]) -> Upper followed by Upper+Lower (e.g. PDFExtractor)
        let pattern2 = "([A-Z])([A-Z][a-z])"
        
        // ([a-zA-Z])([0-9]) -> Letter followed by Number (e.g. file123)
        let pattern3 = "([a-zA-Z])([0-9])"
        
        // ([0-9])([a-zA-Z]) -> Number followed by Letter (e.g. 123file)
        let pattern4 = "([0-9])([a-zA-Z])"
        
        var result = clean
        
        func applyRegex(_ pattern: String) {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(location: 0, length: result.utf16.count)
                result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "$1 $2")
            }
        }
        
        applyRegex(pattern1)
        applyRegex(pattern2)
        applyRegex(pattern3)
        applyRegex(pattern4)
        
        return result.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
    }
}
