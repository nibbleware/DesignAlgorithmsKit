//
//  HybridEncryptionTests.swift
//  DesignAlgorithmsKitTests
//

import XCTest
import CryptoKit
@testable import DesignAlgorithmsKit

final class HybridEncryptionTests: XCTestCase {
    func testRoundTrip() throws {
        let recipient = Curve25519.KeyAgreement.PrivateKey()
        let message = Data("hybrid encryption round trip".utf8)
        let packet = try HybridEncryption.encrypt(message, to: recipient.publicKey)
        XCTAssertEqual(try HybridEncryption.decrypt(packet, with: recipient), message)
    }

    func testEmptyMessageRoundTrip() throws {
        let recipient = Curve25519.KeyAgreement.PrivateKey()
        let packet = try HybridEncryption.encrypt(Data(), to: recipient.publicKey)
        XCTAssertEqual(try HybridEncryption.decrypt(packet, with: recipient), Data())
    }

    func testPacketLayout() throws {
        let recipient = Curve25519.KeyAgreement.PrivateKey()
        let message = Data(repeating: 0x42, count: 100)
        let packet = try HybridEncryption.encrypt(message, to: recipient.publicKey)
        // 32-byte ephemeral key + 12-byte nonce + ciphertext + 16-byte tag
        XCTAssertEqual(packet.count, 32 + 12 + message.count + 16)
    }

    func testEachEncryptionUsesAFreshEphemeralKey() throws {
        let recipient = Curve25519.KeyAgreement.PrivateKey()
        let message = Data("same input".utf8)
        let first = try HybridEncryption.encrypt(message, to: recipient.publicKey)
        let second = try HybridEncryption.encrypt(message, to: recipient.publicKey)
        XCTAssertNotEqual(first.prefix(32), second.prefix(32))
        XCTAssertNotEqual(first, second)
    }

    func testShortPacketThrowsInvalidLength() {
        let recipient = Curve25519.KeyAgreement.PrivateKey()
        for count in [0, 1, 31, 32] {
            XCTAssertThrowsError(try HybridEncryption.decrypt(Data(count: count), with: recipient)) { error in
                guard case CryptoError.invalidDataLength = error else {
                    return XCTFail("Expected invalidDataLength for \(count) bytes, got \(error)")
                }
            }
        }
    }

    func testWrongRecipientCannotDecrypt() throws {
        let recipient = Curve25519.KeyAgreement.PrivateKey()
        let other = Curve25519.KeyAgreement.PrivateKey()
        let packet = try HybridEncryption.encrypt(Data("secret".utf8), to: recipient.publicKey)
        XCTAssertThrowsError(try HybridEncryption.decrypt(packet, with: other))
    }

    func testTamperedCiphertextIsRejected() throws {
        let recipient = Curve25519.KeyAgreement.PrivateKey()
        var packet = try HybridEncryption.encrypt(Data("secret".utf8), to: recipient.publicKey)
        packet[packet.count - 1] ^= 0x01
        XCTAssertThrowsError(try HybridEncryption.decrypt(packet, with: recipient))
    }
}
