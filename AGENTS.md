# Hapa Crypto Node Agent Guide

## Node Role

`hapa-crypto-node` is the local trust and cryptography boundary for Hapa. It provides loopback HTTP and Swift CLI surfaces for hashing, signing, verification, key generation, encryption, decryption, and key agreement so higher-level nodes do not each reimplement crypto primitives.

## Source Of Truth

- `Package.swift` defines the SwiftPM package, executable, library, and dependency graph.
- `Sources/HapaCrypto/` contains reusable CryptoKit-backed primitives.
- `Sources/hapa-crypto-node/` owns the CLI and Hummingbird server.
- `Tests/hapa-crypto-nodeTests/` covers core crypto behavior.
- `web/index.html` is the local dashboard and should stay static and dependency-light.
- `README.md` and `SECURITY.md` define operator-facing usage and publication safety.

## Safe Edit Boundaries

- Keep the default bind host on `127.0.0.1` and keep `/v1/*` bearer-token gated.
- Never commit `.node_token`, real private keys, symmetric keys, signatures tied to private material, `.env` files, or generated secret fixtures.
- Prefer adding endpoint tests before changing request/response shapes.
- Keep browser UI examples placeholder-only; do not paste live keys or tokens into docs.
- Treat command output containing private keys as sensitive even when it is generated locally for testing.

## Hapa Connectivity

- Reads requests from local Hapa nodes that need trust, identity, provenance, or payload protection.
- Produces signatures, hashes, encrypted payloads, public keys, and verification responses for downstream nodes.
- Related nodes: `hapa-keys-node`, `hapa-telemetry-node`, `hapa-lance-node`, `hapa_second_brain`, and the Hapa wiki node notes.
- Heavy or durable relation records belong in `hapa-vault`; this repo should keep only source, tests, docs, and tiny fixtures.

## Verification

```bash
swift build
swift test
swift run hapa-crypto-node serve --port 8736 --cwd ${HAPA_NODE_ROOT}
curl http://127.0.0.1:8736/health
```

Before publication, run a repo-level secret and size scan, then verify no tracked runtime token or generated build artifact is present.
