import Foundation

public struct EncryptionRequest: Codable {
    public let plaintext_base64: String
    public let key_base64: String
    public init(plaintext_base64: String, key_base64: String) {
        self.plaintext_base64 = plaintext_base64
        self.key_base64 = key_base64
    }
}

public struct EncryptionResponse: Codable {
    public let ciphertext_base64: String
    public let nonce_base64: String
    public let tag_base64: String
    public init(ciphertext_base64: String, nonce_base64: String, tag_base64: String) {
        self.ciphertext_base64 = ciphertext_base64
        self.nonce_base64 = nonce_base64
        self.tag_base64 = tag_base64
    }
}

public struct DecryptionRequest: Codable {
    public let ciphertext_base64: String
    public let key_base64: String
    public let nonce_base64: String
    public let tag_base64: String
    public init(ciphertext_base64: String, key_base64: String, nonce_base64: String, tag_base64: String) {
        self.ciphertext_base64 = ciphertext_base64
        self.key_base64 = key_base64
        self.nonce_base64 = nonce_base64
        self.tag_base64 = tag_base64
    }
}

public struct DecryptionResponse: Codable {
    public let plaintext_base64: String
    public init(plaintext_base64: String) {
        self.plaintext_base64 = plaintext_base64
    }
}

public struct SigningRequest: Codable {
    public let data_base64: String
    public let private_key_base64: String
    public init(data_base64: String, private_key_base64: String) {
        self.data_base64 = data_base64
        self.private_key_base64 = private_key_base64
    }
}

public struct SigningResponse: Codable {
    public let signature_base64: String
    public init(signature_base64: String) {
        self.signature_base64 = signature_base64
    }
}

public struct VerificationRequest: Codable {
    public let data_base64: String
    public let signature_base64: String
    public let public_key_base64: String
    public init(data_base64: String, signature_base64: String, public_key_base64: String) {
        self.data_base64 = data_base64
        self.signature_base64 = signature_base64
        self.public_key_base64 = public_key_base64
    }
}

public struct VerificationResponse: Codable {
    public let valid: Bool
    public init(valid: Bool) {
        self.valid = valid
    }
}

public struct IdentityResponse: Codable {
    public let private_key_base64: String
    public let public_key_base64: String
    public let type: String
    public init(private_key_base64: String, public_key_base64: String, type: String) {
        self.private_key_base64 = private_key_base64
        self.public_key_base64 = public_key_base64
        self.type = type
    }
}

public struct KeyExchangeRequest: Codable {
    public let private_key_base64: String
    public let other_public_key_base64: String
    public init(private_key_base64: String, other_public_key_base64: String) {
        self.private_key_base64 = private_key_base64
        self.other_public_key_base64 = other_public_key_base64
    }
}

public struct KeyExchangeResponse: Codable {
    public let shared_secret_base64: String
    public init(shared_secret_base64: String) {
        self.shared_secret_base64 = shared_secret_base64
    }
}

public struct HashRequest: Codable {
    public let data_base64: String
    public let algorithm: String // "sha256" | "sha512"
    public init(data_base64: String, algorithm: String) {
        self.data_base64 = data_base64
        self.algorithm = algorithm
    }
}

public struct HashResponse: Codable {
    public let hash_base64: String
    public init(hash_base64: String) {
        self.hash_base64 = hash_base64
    }
}
