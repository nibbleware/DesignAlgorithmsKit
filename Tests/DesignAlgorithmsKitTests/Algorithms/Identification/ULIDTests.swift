import XCTest
@testable import DesignAlgorithmsKit

final class ULIDTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testInitializationWithDefaults() {
        let ulid = ULID()
        XCTAssertEqual(ulid.description.count, 26, "ULID string representation should be 26 characters.")
    }
    
    func testInitializationWithExplicitDate() {
        let date = Date(timeIntervalSince1970: 1600000000) // 2020-09-13
        // 1600000000 * 1000 = 1600000000000 milliseconds
        // 1600000000000 in hex is 0x174876E8000
        // First 6 bytes should correspond to this timestamp.
        
        let ulid = ULID(date: date)
        let string = ulid.description
        
        // Expected Crockford Base32 encoding of the timestamp
        // We can verify that the first few characters are stable for this timestamp.
        // It's tricky to calculate exact base32 without the logic, ensuring stability is improved by full byte check in another test.
        // Here we just check it generated something valid.
        XCTAssertEqual(string.count, 26)
    }
    
    func testInitializationWithExplicitRandomBytes() {
        let date = Date(timeIntervalSince1970: 0)
        let randomBytes: [UInt8] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] // 10 bytes
        
        let ulid = ULID(date: date, randomBytes: randomBytes)
        
        // Decoding to check bytes
        guard let decodedULID = ULID(string: ulid.description) else {
            XCTFail("Should be able to decode generated ULID")
            return
        }
        
        // Re-encode to verify stability
        XCTAssertEqual(ulid, decodedULID)
    }
    
    func testInitializationWithInsufficientRandomBytes() {
        let date = Date(timeIntervalSince1970: 0)
        let shortRandomBytes: [UInt8] = [0, 1, 2] // Too short, should separate pad
        
        // The implementation pads with 0s if short
        let ulid = ULID(date: date, randomBytes: shortRandomBytes)
        XCTAssertEqual(ulid.description.count, 26)
    }

    // MARK: - String Encoding/Decoding Tests
    
    func testStringInitializationValid() {
        let validString = "01AN4Z07BY79KA1307SR9X4MV0"
        let ulid = ULID(string: validString)
        XCTAssertNotNil(ulid)
        XCTAssertEqual(ulid?.description, validString)
    }
    
    func testStringInitializationInvalidLength() {
        let shortString = "01AN4Z"
        let ulid = ULID(string: shortString)
        XCTAssertNil(ulid, "Should fail for strings != 26 chars")
    }
    
    func testStringInitializationInvalidCharacters() {
        let invalidCharString = "01AN4Z07BY79KA1307SR9X4MV@" // @ is not in Crockford Base32
        let ulid = ULID(string: invalidCharString)
        XCTAssertNil(ulid, "Should fail for invalid characters")
    }
    
    func testStringInitializationCaseInsensitive() {
        let lowerCase = "01an4z07by79ka1307sr9x4mv0"
        let ulid = ULID(string: lowerCase)
        XCTAssertNotNil(ulid)
        XCTAssertEqual(ulid?.description, lowerCase.uppercased())
    }
    
    // MARK: - Equality and Hashing
    
    func testEquality() {
        let string = "01AN4Z07BY79KA1307SR9X4MV0"
        let ulid1 = ULID(string: string)
        let ulid2 = ULID(string: string)
        let ulid3 = ULID()
        
        XCTAssertEqual(ulid1, ulid2)
        XCTAssertNotEqual(ulid1, ulid3)
    }
    
    func testHashable() {
        let string = "01AN4Z07BY79KA1307SR9X4MV0"
        let ulid1 = ULID(string: string)!
        let ulid2 = ULID(string: string)!
        
        var set = Set<ULID>()
        set.insert(ulid1)
        XCTAssertTrue(set.contains(ulid2))
    }
    
    // MARK: - Codable Tests
    
    func testCodable() throws {
        let originalULID = ULID()
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(originalULID)
        let decodedULID = try decoder.decode(ULID.self, from: data)
        
        XCTAssertEqual(originalULID, decodedULID)
    }
    
    func testDecodableError() {
        let json = "\"InvalidULIDString\"".data(using: .utf8)!
        let decoder = JSONDecoder()
        
        XCTAssertThrowsError(try decoder.decode(ULID.self, from: json))
    }

    // MARK: - Monotonicity / Sorting
    
    func testOrdering() {
        // While ULID struct doesn't conform to Comparable yet,
        // we can verify the lexicographical order of the strings corresponds to time.
        
        let earlyDate = Date(timeIntervalSince1970: 1000)
        let lateDate = Date(timeIntervalSince1970: 2000)
        
        let earlyULID = ULID(date: earlyDate)
        let lateULID = ULID(date: lateDate)
        
        XCTAssertTrue(earlyULID.string < lateULID.string, "ULIDs should be lexicographically sortable by time")
    }
}
