import Foundation
import CryptoKit

/// Provides simplified Hybrid Encryption (Asymmetric Key Exchange + Symmetric Encryption).
///
/// Uses Curve25519 for Key Agreement and ChaCha20-Poly1305 for symmetric encryption.
///
/// Format: [Ephemeral Public Key (32 bytes)] + [ChaCha20-Poly1305 Sealed Box]
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public struct HybridEncryption {
    
    // MARK: - Constants
    
    private static let protocolSalt = "DesignAlgorithmsKit.HybridEncryption.v1".data(using: .utf8)!
    
    // MARK: - Encryption
    
    /// Encrypts data for a specific recipient using their public key.
    ///
    /// - Parameters:
    ///   - data: The raw data to encrypt.
    ///   - recipientPublicKey: The recipient's Curve25519 Public Key.
    /// - Returns: The encrypted data packet containing the ephemeral key and ciphertext.
    public static func encrypt(_ data: Data, to recipientPublicKey: Curve25519.KeyAgreement.PublicKey) throws -> Data {
        // 1. Generate Ephemeral Keypair
        let ephemeralPrivateKey = Curve25519.KeyAgreement.PrivateKey()
        let ephemeralPublicKey = ephemeralPrivateKey.publicKey
        
        // 2. Derive Shared Secret
        let sharedSecret = try ephemeralPrivateKey.sharedSecretFromKeyAgreement(with: recipientPublicKey)
        
        // 3. Derive Symmetric Key (HKDF)
        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: CryptoKit.SHA256.self,
            salt: protocolSalt,
            sharedInfo: Data(),
            outputByteCount: 32
        )
        
        // 4. Encrypt (ChaCha20-Poly1305)
        let sealedBox = try ChaChaPoly.seal(data, using: symmetricKey)
        
        // 5. Pack: [Ephemeral PubKey (32)] + [Sealed Box]
        return ephemeralPublicKey.rawRepresentation + sealedBox.combined
    }
    
    // MARK: - Decryption
    
    /// Decrypts a hybrid encryption packet.
    ///
    /// - Parameters:
    ///   - encryptedData: The data packet ([Diffie-Hellman Key] + [Ciphertext]).
    ///   - privateKey: The recipient's Curve25519 Private Key.
    /// - Returns: The original raw data.
    public static func decrypt(_ encryptedData: Data, with privateKey: Curve25519.KeyAgreement.PrivateKey) throws -> Data {
        guard encryptedData.count > 32 else {
            throw CryptoError.invalidDataLength
        }
        
        // 1. Extract Ephemeral Public Key (First 32 bytes)
        let ephemeralKeyData = encryptedData.prefix(32)
        let ephemeralPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: ephemeralKeyData)
        
        // 2. Extract Sealed Box (Remaining bytes)
        let sealedBoxData = encryptedData.dropFirst(32)
        let sealedBox = try ChaChaPoly.SealedBox(combined: sealedBoxData)
        
        // 3. Derive Shared Secret
        let sharedSecret = try privateKey.sharedSecretFromKeyAgreement(with: ephemeralPublicKey)
        
        // 4. Derive Symmetric Key (Must match encryption derivation)
        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: CryptoKit.SHA256.self,
            salt: protocolSalt,
            sharedInfo: Data(),
            outputByteCount: 32
        )
        
        // 5. Open Box
        return try ChaChaPoly.open(sealedBox, using: symmetricKey)
    }
}

public enum CryptoError: Error {
    case invalidDataLength
}
