# CAMPFIRE — Hapa Crypto Node

## Node intention

Hapa Crypto Node is the Hapa.ai local cryptography boundary: a small Swift service that lets other nodes ask for encryption, signatures, hashes, identity keys, and key-agreement material without embedding those primitives into UI or wallet code.

## Verified implementation facts

- Repository: `/Users/calderwong/Desktop/hapa-crypto-node`
- Package: SwiftPM, `hapa-crypto-node`
- Library target: `HapaCrypto`
- Executable target/product: `hapa-crypto-node`
- Runtime framework: Hummingbird 2
- CLI framework: Swift Argument Parser
- Crypto implementation: CryptoKit
- Default listener: `127.0.0.1:8736`
- Dashboard: `web/index.html`
- Tests: `Tests/hapa-crypto-nodeTests/CryptoNodeTests.swift`

## Current surfaces

Public:

- `GET /`
- `GET /health`

Bearer-token gated:

- `GET /v1/capabilities`
- `POST /v1/identity/generate`
- `POST /v1/encrypt`
- `POST /v1/decrypt`
- `POST /v1/sign`
- `POST /v1/verify`
- `POST /v1/hash`
- `POST /v1/exchange`

Token source order is `HAPA_CRYPTO_NODE_TOKEN`, `.node_token`, then generated `.node_token`. `.node_token` is local secret state and must stay out of git.

## Ecosystem role

Verified role: standalone service/library exposing cryptographic primitives for local Hapa workflows.

Inferred role: trust/keys/crypto substrate for future Hapa wallet, provenance, identity, and node-to-node verification flows. The repository should not yet be described as a complete wallet, NFT, or P2P product until those surfaces are implemented and smoke-tested.

## Operating commands

```bash
swift build
swift test
swift run hapa-crypto-node serve --port 8736 --cwd /Users/calderwong/Desktop/hapa-crypto-node
```

## Inputs and outputs

Inputs and outputs are JSON over HTTP or CLI arguments/stdout. Cryptographic bytes are base64-encoded. Secrets include bearer tokens, private keys, symmetric keys, and shared secrets.

## Wiki link

- `[[Nodes/Existing/hapa-crypto-node|hapa-crypto-node]]`

## License and Bananas

Project license is MIT under `Hapa.ai / Calder Wong`.

Contributors may opt into Bananas work-contribution tracking for attribution. Bananas records contribution credit; it does not alter the MIT license grant or replace third-party dependency license notices.
