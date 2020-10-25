import Foundation
import CCryptoBoringSSL

class BigNumber {
    let c: UnsafeMutablePointer<BIGNUM>?;

    public init() {
        self.c = CCryptoBoringSSL_BN_new();
    }

    init(_ ptr: OpaquePointer) {
        self.c = UnsafeMutablePointer<BIGNUM>(ptr);
    }

    deinit {
        CCryptoBoringSSL_BN_free(self.c);
    }

    public static func convert(_ bnBase64: String) -> BigNumber? {
        guard let data = Data(base64Encoded: bnBase64) else {
            return nil
        }

        let c = data.withUnsafeBytes { (p: UnsafeRawBufferPointer) -> OpaquePointer in
            return OpaquePointer(CCryptoBoringSSL_BN_bin2bn(p.baseAddress?.assumingMemoryBound(to: UInt8.self), p.count, nil))
        }
        return BigNumber(c)
    }

    public func toBase64(_ size: Int = 1000) -> String {
        let pBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
        defer { pBuffer.deallocate() }

        let actualBytes = Int(CCryptoBoringSSL_BN_bn2bin(self.c, pBuffer))
        let data = Data(bytes: pBuffer, count: actualBytes)
        return data.base64EncodedString()
    }
}
