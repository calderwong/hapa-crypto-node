import Foundation
import Hummingbird
import Logging
import ArgumentParser
import CryptoKit
import HapaCrypto

@main
struct HapaCryptoNode: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "hapa-crypto",
        abstract: "Hapa Crypto Node — Swift-native cryptography service",
        subcommands: [Serve.self, Encrypt.self, Decrypt.self, Sign.self, Verify.self, Identity.self, Hash.self, Exchange.self],
        defaultSubcommand: Serve.self
    )
}

extension HapaCryptoNode {
    struct Serve: AsyncParsableCommand {
        @Option(name: .shortAndLong, help: "Port to bind to")
        var port: Int = 8736

        @Option(name: .shortAndLong, help: "Working directory")
        var cwd: String = FileManager.default.currentDirectoryPath

        func run() async throws {
            let logger = Logger(label: "hapa-crypto-node")
            let token = TokenManager.resolveToken(rootPath: cwd)
            let router = Router(context: HapaRequestContext.self)
            
            router.get("/") { _, _ in
                let htmlPath = URL(fileURLWithPath: cwd).appendingPathComponent("web/index.html")
                let htmlData = try Data(contentsOf: htmlPath)
                return Response(
                    status: .ok,
                    headers: [.contentType: "text/html"],
                    body: .init(byteBuffer: .init(data: htmlData))
                )
            }
            
            router.get("/health") { _, _ in
                return HealthResponse(ok: true, service: "hapa-crypto-node")
            }
            
            let authGroup = router.group()
                .add(middleware: HapaAuthMiddleware(token: token))
            
            authGroup.get("/v1/capabilities") { _, _ in
                return CapabilitiesResponse(
                    api_version: "v1",
                    service: "hapa-crypto-node",
                    capabilities: [
                        "symmetric": ["aes-gcm"],
                        "signatures": ["ed25519"],
                        "key_exchange": ["p256"],
                        "identity": ["generate"],
                        "hashing": ["sha256", "sha512"]
                    ]
                )
            }
            
            authGroup.post("/v1/identity/generate") { request, context in
                let type = (try? await request.decode(as: [String: String].self, context: context)["type"]) ?? "ed25519"
                if type.lowercased() == "p256" {
                    let keyPair = CryptoCore.generateP256KeyPair()
                    return IdentityResponse(
                        private_key_base64: keyPair.privateKey.rawRepresentation.base64EncodedString(),
                        public_key_base64: keyPair.publicKey.rawRepresentation.base64EncodedString(),
                        type: "p256"
                    )
                } else {
                    let keyPair = CryptoCore.generateEd25519KeyPair()
                    return IdentityResponse(
                        private_key_base64: keyPair.privateKey.rawRepresentation.base64EncodedString(),
                        public_key_base64: keyPair.publicKey.rawRepresentation.base64EncodedString(),
                        type: "ed25519"
                    )
                }
            }

            authGroup.post("/v1/encrypt") { request, context in
                let payload = try await request.decode(as: EncryptionRequest.self, context: context)
                guard let data = Data(base64Encoded: payload.plaintext_base64),
                      let keyData = Data(base64Encoded: payload.key_base64) else {
                    throw HTTPError(.badRequest, message: "Invalid base64 data")
                }
                let key = SymmetricKey(data: keyData)
                let result = try CryptoCore.encryptSymmetric(data: data, key: key)
                return EncryptionResponse(
                    ciphertext_base64: result.ciphertext.base64EncodedString(),
                    nonce_base64: Data(result.nonce).base64EncodedString(),
                    tag_base64: result.tag.base64EncodedString()
                )
            }

            authGroup.post("/v1/decrypt") { request, context in
                let payload = try await request.decode(as: DecryptionRequest.self, context: context)
                guard let ciphertext = Data(base64Encoded: payload.ciphertext_base64),
                      let keyData = Data(base64Encoded: payload.key_base64),
                      let nonceData = Data(base64Encoded: payload.nonce_base64),
                      let tag = Data(base64Encoded: payload.tag_base64) else {
                    throw HTTPError(.badRequest, message: "Invalid base64 data")
                }
                let key = SymmetricKey(data: keyData)
                let nonce = try AES.GCM.Nonce(data: nonceData)
                let plaintext = try CryptoCore.decryptSymmetric(ciphertext: ciphertext, key: key, nonce: nonce, tag: tag)
                return DecryptionResponse(plaintext_base64: plaintext.base64EncodedString())
            }

            authGroup.post("/v1/sign") { request, context in
                let payload = try await request.decode(as: SigningRequest.self, context: context)
                guard let data = Data(base64Encoded: payload.data_base64),
                      let privKeyData = Data(base64Encoded: payload.private_key_base64) else {
                    throw HTTPError(.badRequest, message: "Invalid base64 data")
                }
                let privKey = try Curve25519.Signing.PrivateKey(rawRepresentation: privKeyData)
                let signature = try CryptoCore.signEd25519(data: data, privateKey: privKey)
                return SigningResponse(signature_base64: signature.base64EncodedString())
            }

            authGroup.post("/v1/verify") { request, context in
                let payload = try await request.decode(as: VerificationRequest.self, context: context)
                guard let data = Data(base64Encoded: payload.data_base64),
                      let sigData = Data(base64Encoded: payload.signature_base64),
                      let pubKeyData = Data(base64Encoded: payload.public_key_base64) else {
                    throw HTTPError(.badRequest, message: "Invalid base64 data")
                }
                let pubKey = try Curve25519.Signing.PublicKey(rawRepresentation: pubKeyData)
                let isValid = CryptoCore.verifyEd25519(data: data, signature: sigData, publicKey: pubKey)
                return VerificationResponse(valid: isValid)
            }

            authGroup.post("/v1/hash") { request, context in
                let payload = try await request.decode(as: HashRequest.self, context: context)
                guard let data = Data(base64Encoded: payload.data_base64) else {
                    throw HTTPError(.badRequest, message: "Invalid base64 data")
                }
                let hashData: Data
                switch payload.algorithm.lowercased() {
                case "sha256":
                    hashData = CryptoCore.sha256(data: data)
                case "sha512":
                    hashData = CryptoCore.sha512(data: data)
                default:
                    throw HTTPError(.badRequest, message: "Unsupported algorithm: \(payload.algorithm)")
                }
                return HashResponse(hash_base64: hashData.base64EncodedString())
            }

            authGroup.post("/v1/exchange") { request, context in
                let payload = try await request.decode(as: KeyExchangeRequest.self, context: context)
                guard let privKeyData = Data(base64Encoded: payload.private_key_base64),
                      let pubKeyData = Data(base64Encoded: payload.other_public_key_base64) else {
                    throw HTTPError(.badRequest, message: "Invalid base64 data")
                }
                let privKey = try P256.KeyAgreement.PrivateKey(rawRepresentation: privKeyData)
                let pubKey = try P256.KeyAgreement.PublicKey(rawRepresentation: pubKeyData)
                let secret = try CryptoCore.sharedSecretP256(privateKey: privKey, publicKey: pubKey)
                let sharedSecretData = secret.withUnsafeBytes { Data($0) }
                return KeyExchangeResponse(shared_secret_base64: sharedSecretData.base64EncodedString())
            }

            let app = Application(
                router: router,
                configuration: .init(address: .hostname("127.0.0.1", port: port)),
                logger: logger
            )
            print("Hapa Crypto Node starting on 127.0.0.1:\(port)")
            try await app.runService()
        }
    }

    struct Encrypt: AsyncParsableCommand {
        @Argument(help: "Plaintext to encrypt")
        var plaintext: String
        @Option(name: .shortAndLong, help: "Base64 key (32 bytes for AES-256)")
        var key: String

        func run() async throws {
            guard let data = plaintext.data(using: .utf8),
                  let keyData = Data(base64Encoded: key) else {
                print("Error: Invalid input or key")
                return
            }
            let result = try CryptoCore.encryptSymmetric(data: data, key: SymmetricKey(data: keyData))
            let response = EncryptionResponse(
                ciphertext_base64: result.ciphertext.base64EncodedString(),
                nonce_base64: Data(result.nonce).base64EncodedString(),
                tag_base64: result.tag.base64EncodedString()
            )
            let jsonData = try JSONEncoder().encode(response)
            print(String(data: jsonData, encoding: .utf8)!)
        }
    }

    struct Decrypt: AsyncParsableCommand {
        @Argument(help: "Base64 ciphertext")
        var ciphertext: String
        @Option(name: .shortAndLong, help: "Base64 key")
        var key: String
        @Option(name: .shortAndLong, help: "Base64 nonce")
        var nonce: String
        @Option(name: .shortAndLong, help: "Base64 tag")
        var tag: String

        func run() async throws {
            guard let cipherData = Data(base64Encoded: ciphertext),
                  let keyData = Data(base64Encoded: key),
                  let nonceData = Data(base64Encoded: nonce),
                  let tagData = Data(base64Encoded: tag) else {
                print("Error: Invalid base64 input")
                return
            }
            let n = try AES.GCM.Nonce(data: nonceData)
            let plaintext = try CryptoCore.decryptSymmetric(ciphertext: cipherData, key: SymmetricKey(data: keyData), nonce: n, tag: tagData)
            print(String(data: plaintext, encoding: .utf8) ?? "Invalid UTF8 result")
        }
    }

    struct Sign: AsyncParsableCommand {
        @Argument(help: "Data to sign")
        var data: String
        @Option(name: .shortAndLong, help: "Base64 private key")
        var key: String

        func run() async throws {
            guard let inputData = data.data(using: .utf8),
                  let privKeyData = Data(base64Encoded: key) else {
                print("Error: Invalid input or key")
                return
            }
            let privKey = try Curve25519.Signing.PrivateKey(rawRepresentation: privKeyData)
            let sig = try CryptoCore.signEd25519(data: inputData, privateKey: privKey)
            print(sig.base64EncodedString())
        }
    }

    struct Verify: AsyncParsableCommand {
        @Argument(help: "Data to verify")
        var data: String
        @Option(name: .shortAndLong, help: "Base64 signature")
        var signature: String
        @Option(name: .shortAndLong, help: "Base64 public key")
        var key: String

        func run() async throws {
            guard let inputData = data.data(using: .utf8),
                  let sigData = Data(base64Encoded: signature),
                  let pubKeyData = Data(base64Encoded: key) else {
                print("Error: Invalid base64 input")
                return
            }
            let pubKey = try Curve25519.Signing.PublicKey(rawRepresentation: pubKeyData)
            let isValid = CryptoCore.verifyEd25519(data: inputData, signature: sigData, publicKey: pubKey)
            print(isValid ? "VALID" : "INVALID")
        }
    }

    struct Identity: AsyncParsableCommand {
        @Option(name: .shortAndLong, help: "Key type (ed25519|p256)")
        var type: String = "ed25519"

        func run() async throws {
            if type.lowercased() == "p256" {
                let keyPair = CryptoCore.generateP256KeyPair()
                print("Type: P256 (KeyAgreement)")
                print("Public Key (Base64): \(keyPair.publicKey.rawRepresentation.base64EncodedString())")
                print("Private Key (Base64): \(keyPair.privateKey.rawRepresentation.base64EncodedString())")
            } else {
                let keyPair = CryptoCore.generateEd25519KeyPair()
                print("Type: Ed25519 (Signing)")
                print("Public Key (Base64): \(keyPair.publicKey.rawRepresentation.base64EncodedString())")
                print("Private Key (Base64): \(keyPair.privateKey.rawRepresentation.base64EncodedString())")
            }
        }
    }

    struct Hash: AsyncParsableCommand {
        @Argument(help: "Data to hash")
        var data: String
        @Option(name: .shortAndLong, help: "Algorithm (sha256|sha512)")
        var algo: String = "sha256"

        func run() async throws {
            guard let inputData = data.data(using: .utf8) else {
                print("Error: Invalid input")
                return
            }
            let hash: Data
            if algo.lowercased() == "sha512" {
                hash = CryptoCore.sha512(data: inputData)
            } else {
                hash = CryptoCore.sha256(data: inputData)
            }
            print(hash.base64EncodedString())
        }
    }

    struct Exchange: AsyncParsableCommand {
        @Option(name: .shortAndLong, help: "Base64 private key (P256)")
        var privateKey: String
        @Option(name: .shortAndLong, help: "Base64 other public key (P256)")
        var otherPublicKey: String

        func run() async throws {
            guard let privKeyData = Data(base64Encoded: privateKey),
                  let pubKeyData = Data(base64Encoded: otherPublicKey) else {
                print("Error: Invalid base64 input")
                return
            }
            let privKey = try P256.KeyAgreement.PrivateKey(rawRepresentation: privKeyData)
            let pubKey = try P256.KeyAgreement.PublicKey(rawRepresentation: pubKeyData)
            let secret = try CryptoCore.sharedSecretP256(privateKey: privKey, publicKey: pubKey)
            let sharedSecretData = secret.withUnsafeBytes { Data($0) }
            print(sharedSecretData.base64EncodedString())
        }
    }
}

/// Request context for Hapa Crypto Node
struct HapaRequestContext: RequestContext {
    var coreContext: CoreRequestContextStorage
    init(source: Source) {
        self.coreContext = .init(source: source)
    }
}

// Codable responses for Hummingbird
struct HealthResponse: ResponseGenerator, Codable {
    let ok: Bool
    let service: String
    func response(from request: Request, context: some RequestContext) throws -> Response {
        let data = try JSONEncoder().encode(self)
        return Response(status: .ok, headers: [.contentType: "application/json"], body: .init(byteBuffer: .init(data: data)))
    }
}

struct CapabilitiesResponse: ResponseGenerator, Codable {
    let api_version: String
    let service: String
    let capabilities: [String: [String]]
    func response(from request: Request, context: some RequestContext) throws -> Response {
        let data = try JSONEncoder().encode(self)
        return Response(status: .ok, headers: [.contentType: "application/json"], body: .init(byteBuffer: .init(data: data)))
    }
}

extension EncryptionResponse: ResponseGenerator {
    public func response(from request: Request, context: some RequestContext) throws -> Response {
        let data = try JSONEncoder().encode(self)
        return Response(status: .ok, headers: [.contentType: "application/json"], body: .init(byteBuffer: .init(data: data)))
    }
}

extension DecryptionResponse: ResponseGenerator {
    public func response(from request: Request, context: some RequestContext) throws -> Response {
        let data = try JSONEncoder().encode(self)
        return Response(status: .ok, headers: [.contentType: "application/json"], body: .init(byteBuffer: .init(data: data)))
    }
}

extension SigningResponse: ResponseGenerator {
    public func response(from request: Request, context: some RequestContext) throws -> Response {
        let data = try JSONEncoder().encode(self)
        return Response(status: .ok, headers: [.contentType: "application/json"], body: .init(byteBuffer: .init(data: data)))
    }
}

extension VerificationResponse: ResponseGenerator {
    public func response(from request: Request, context: some RequestContext) throws -> Response {
        let data = try JSONEncoder().encode(self)
        return Response(status: .ok, headers: [.contentType: "application/json"], body: .init(byteBuffer: .init(data: data)))
    }
}

extension IdentityResponse: ResponseGenerator {
    public func response(from request: Request, context: some RequestContext) throws -> Response {
        let data = try JSONEncoder().encode(self)
        return Response(status: .ok, headers: [.contentType: "application/json"], body: .init(byteBuffer: .init(data: data)))
    }
}

extension HashResponse: ResponseGenerator {
    public func response(from request: Request, context: some RequestContext) throws -> Response {
        let data = try JSONEncoder().encode(self)
        return Response(status: .ok, headers: [.contentType: "application/json"], body: .init(byteBuffer: .init(data: data)))
    }
}

extension KeyExchangeResponse: ResponseGenerator {
    public func response(from request: Request, context: some RequestContext) throws -> Response {
        let data = try JSONEncoder().encode(self)
        return Response(status: .ok, headers: [.contentType: "application/json"], body: .init(byteBuffer: .init(data: data)))
    }
}
