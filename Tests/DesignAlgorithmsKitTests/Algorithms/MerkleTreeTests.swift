//
//  MerkleTreeTests.swift
//  DesignAlgorithmsKitTests
//
//  Unit tests for Merkle Tree
//

import XCTest
@testable import DesignAlgorithmsKit

final class MerkleTreeTests: XCTestCase {
    func testBuildMerkleTree() {
        // Given
        let data = ["block1", "block2", "block3", "block4"].map { $0.data(using: .utf8)! }
        
        // When
        let tree = MerkleTree.build(from: data)
        
        // Then
        XCTAssertNotNil(tree.root)
        XCTAssertFalse(tree.rootHash.isEmpty)
    }
    
    func testBuildEmptyTree() {
        // When
        let tree = MerkleTree.build(from: [])
        
        // Then
        XCTAssertNotNil(tree.root)
        XCTAssertTrue(tree.root.isLeaf)
    }
    
    func testBuildSingleElement() {
        // Given
        let data = ["single"].map { $0.data(using: .utf8)! }
        
        // When
        let tree = MerkleTree.build(from: data)
        
        // Then
        XCTAssertNotNil(tree.root)
        XCTAssertTrue(tree.root.isLeaf)
    }
    
    func testGenerateProof() {
        // Given
        let data = ["block1", "block2", "block3", "block4"].map { $0.data(using: .utf8)! }
        let tree = MerkleTree.build(from: data)
        
        // When
        let proof = tree.generateProof(for: data[0])
        
        // Then
        XCTAssertNotNil(proof)
        XCTAssertEqual(proof?.leafHash, data[0].merkleHash())
    }
    
    func testGenerateProofForNonExistent() {
        // Given
        let data = ["block1", "block2"].map { $0.data(using: .utf8)! }
        let tree = MerkleTree.build(from: data)
        let nonExistent = "nonexistent".data(using: .utf8)!
        
        // When
        let proof = tree.generateProof(for: nonExistent)
        
        // Then
        XCTAssertNil(proof)
    }
    
    func testVerifyProof() {
        // Given
        let data = ["block1", "block2", "block3", "block4"].map { $0.data(using: .utf8)! }
        let tree = MerkleTree.build(from: data)
        let rootHash = tree.rootHash
        
        // When
        guard let proof = tree.generateProof(for: data[0]) else {
            XCTFail("Failed to generate proof")
            return
        }
        
        // Then
        let isValid = MerkleTree.verify(proof: proof, rootHash: rootHash)
        XCTAssertTrue(isValid)
    }
    
    func testVerifyProofWithWrongRoot() {
        // Given
        let data = ["block1", "block2"].map { $0.data(using: .utf8)! }
        let tree = MerkleTree.build(from: data)
        
        // When
        guard let proof = tree.generateProof(for: data[0]) else {
            XCTFail("Failed to generate proof")
            return
        }
        
        // Then
        let wrongRoot = Data(repeating: 0, count: 32)
        let isValid = MerkleTree.verify(proof: proof, rootHash: wrongRoot)
        XCTAssertFalse(isValid)
    }
    
    func testBuildFromHashableItems() {
        // Given
        let items: [String] = ["item1", "item2", "item3"]
        
        // When
        let tree = MerkleTree.build(from: items)
        
        // Then
        XCTAssertNotNil(tree.root)
        XCTAssertFalse(tree.rootHash.isEmpty)
    }
}

// MARK: - Unpaired nodes (fix-algorithm-edge-cases)

extension MerkleTreeTests {
    func testProofsVerifyForEveryLeafOfOddAndEvenTrees() {
        for blockCount in [1, 2, 3, 4, 5, 6, 7] {
            let blocks = (0..<blockCount).map { Data("block \($0)".utf8) }
            let tree = MerkleTree.build(from: blocks)
            for (index, block) in blocks.enumerated() {
                guard let proof = tree.generateProof(for: block) else {
                    XCTFail("No proof for block \(index) of \(blockCount)")
                    continue
                }
                XCTAssertTrue(MerkleTree.verify(proof: proof, rootHash: tree.rootHash),
                              "Proof for block \(index) of \(blockCount) does not verify")
            }
        }
    }

    func testProofForLastBlockOfThreeHasOnePathEntryPerLevel() throws {
        let blocks = (0..<3).map { Data("block \($0)".utf8) }
        let proof = try XCTUnwrap(MerkleTree.build(from: blocks).generateProof(for: blocks[2]))
        XCTAssertEqual(proof.path.count, 2)
    }
}
