import Foundation
import CryptoKit

public struct CryptoCore {
    public enum CryptoError: Error {
        case encryptionFailed
        case decryptionFailed
        case invalidKey
        case invalidData
        case signatureVerificationFailed
    }

    // MARK: - Symmetric (AES-GCM)
    public static func encryptSymmetric(data: Data, key: SymmetricKey) throws -> (ciphertext: Data, nonce: AES.GCM.Nonce, tag: Data) {
        let sealedBox = try AES.GCM.seal(data, using: key)
        return (sealedBox.ciphertext, sealedBox.nonce, sealedBox.tag)
    }

    public static func decryptSymmetric(ciphertext: Data, key: SymmetricKey, nonce: AES.GCM.Nonce, tag: Data) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: tag)
        return try AES.GCM.open(sealedBox, using: key)
    }

    // MARK: - Signatures (Ed25519)
    public static func generateEd25519KeyPair() -> (privateKey: Curve25519.Signing.PrivateKey, publicKey: Curve25519.Signing.PublicKey) {
        let privateKey = Curve25519.Signing.PrivateKey()
        return (privateKey, privateKey.publicKey)
    }

    public static func signEd25519(data: Data, privateKey: Curve25519.Signing.PrivateKey) throws -> Data {
        return try privateKey.signature(for: data)
    }

    public static func verifyEd25519(data: Data, signature: Data, publicKey: Curve25519.Signing.PublicKey) -> Bool {
        return publicKey.isValidSignature(signature, for: data)
    }

    // MARK: - Key Exchange (P256)
    public static func generateP256KeyPair() -> (privateKey: P256.KeyAgreement.PrivateKey, publicKey: P256.KeyAgreement.PublicKey) {
        let privateKey = P256.KeyAgreement.PrivateKey()
        return (privateKey, privateKey.publicKey)
    }

    public static func sharedSecretP256(privateKey: P256.KeyAgreement.PrivateKey, publicKey: P256.KeyAgreement.PublicKey) throws -> SharedSecret {
        return try privateKey.sharedSecretFromKeyAgreement(with: publicKey)
    }

    // MARK: - Hashing
    public static func sha256(data: Data) -> Data {
        let digest = SHA256.hash(data: data)
        return Data(digest)
    }

    public static func sha512(data: Data) -> Data {
        let digest = SHA512.hash(data: data)
        return Data(digest)
    }
}
