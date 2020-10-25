import CCryptoBoringSSL
import struct Foundation.Data

internal struct RSASigner: JWTAlgorithm, OpenSSLSigner {
    let key: RSAKey
    let algorithm: OpaquePointer
    let name: String

    func sign<Plaintext>(_ plaintext: Plaintext) throws -> [UInt8]
        where Plaintext: DataProtocol
    {
        guard case .private = self.key.type else {
            throw JWTError.signingAlgorithmFailure(RSAError.privateKeyRequired)
        }
        var signatureLength: UInt32 = 0
        var signature = [UInt8](
            repeating: 0,
            count: Int(CCryptoBoringSSL_RSA_size(key.c))
        )

        let digest = try self.digest(plaintext)
        guard CCryptoBoringSSL_RSA_sign(
            CCryptoBoringSSL_EVP_MD_type(self.algorithm),
            digest,
            numericCast(digest.count),
            &signature,
            &signatureLength,
            self.key.c
        ) == 1 else {
            throw JWTError.signingAlgorithmFailure(RSAError.signFailure)
        }

        return .init(signature[0..<numericCast(signatureLength)])
    }

    func verify<Signature, Plaintext>(
        _ signature: Signature,
        signs plaintext: Plaintext
    ) throws -> Bool
        where Signature: DataProtocol, Plaintext: DataProtocol
    {
        let digest = try self.digest(plaintext)
        let signature = signature.copyBytes()
        return CCryptoBoringSSL_RSA_verify(
            CCryptoBoringSSL_EVP_MD_type(self.algorithm),
            digest,
            numericCast(digest.count),
            signature,
            numericCast(signature.count),
            self.key.c
        ) == 1
    }
}
