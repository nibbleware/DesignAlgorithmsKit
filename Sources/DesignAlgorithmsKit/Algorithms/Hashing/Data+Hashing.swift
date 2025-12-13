
// Extensions for Data to provide convenient hashing properties
public extension Data {
    /// SHA256 hash of the data
    var sha256: Data {
        return SHA256Strategy().compute(data: self)
    }
    
    /// SHA256 hash of the data as a hex string
    var sha256Hex: String {
        return sha256.map { String(format: "%02x", $0) }.joined()
    }
}
