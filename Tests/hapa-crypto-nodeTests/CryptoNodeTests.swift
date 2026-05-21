import XCTest
import CryptoKit
import HapaCrypto

final class CryptoNodeTests: XCTestCase {
    func testSymmetricEncryption() throws {
        let plaintext = "Hapa Truth Invariant".data(using: .utf8)!
        let key = SymmetricKey(size: .bits256)
        
        let result = try CryptoCore.encryptSymmetric(data: plaintext, key: key)
        let decrypted = try CryptoCore.decryptSymmetric(
            ciphertext: result.ciphertext,
            key: key,
            nonce: result.nonce,
            tag: result.tag
        )
        
        XCTAssertEqual(plaintext, decrypted)
    }
    
    func testEd25519Signing() throws {
        let message = "Provenance Seal".data(using: .utf8)!
        let keyPair = CryptoCore.generateEd25519KeyPair()
        
        let signature = try CryptoCore.signEd25519(data: message, privateKey: keyPair.privateKey)
        let isValid = CryptoCore.verifyEd25519(data: message, signature: signature, publicKey: keyPair.publicKey)
        
        XCTAssertTrue(isValid)
    }
    
    func testIdentityGeneration() throws {
        let keyPair = CryptoCore.generateEd25519KeyPair()
        XCTAssertNotNil(keyPair.privateKey.rawRepresentation)
        XCTAssertNotNil(keyPair.publicKey.rawRepresentation)
    }
}
