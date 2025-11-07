//
//  EncryptionHelper.swift
//  TheHotelMedia
//
//  Created by MAC on 29/10/24.
//


import Foundation
import CommonCrypto

struct EncryptionHelper {
    private static let keyString = "1234567890123456"
    private static let ivString = "1234567890123456"
    private static let algorithm = CCAlgorithm(kCCAlgorithmAES)
    private static let options = CCOptions(kCCOptionPKCS7Padding)
    
    static func encrypt(_ input: String) -> String? {
        guard let data = input.data(using: .utf8),
              let key = keyString.data(using: .utf8),
              let iv = ivString.data(using: .utf8) else { return nil }
        
        let bufferSize = data.count + kCCBlockSizeAES128
        var buffer = Data(count: bufferSize)
        var numBytesEncrypted: size_t = 0
        
        let status = buffer.withUnsafeMutableBytes { bufferBytes in
            data.withUnsafeBytes { dataBytes in
                iv.withUnsafeBytes { ivBytes in
                    key.withUnsafeBytes { keyBytes in
                        CCCrypt(CCOperation(kCCEncrypt),
                                algorithm,
                                options,
                                keyBytes.baseAddress, kCCKeySizeAES128,
                                ivBytes.baseAddress,
                                dataBytes.baseAddress, data.count,
                                bufferBytes.baseAddress, bufferSize,
                                &numBytesEncrypted)
                    }
                }
            }
        }
        
        guard status == kCCSuccess else {
            print("Encryption failed with status: \(status)")
            return nil
        }
        
        buffer.removeSubrange(numBytesEncrypted..<buffer.count)
        return buffer.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
    
    static func decrypt(_ input: String) -> String? {
        var base64 = input.replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let paddingLength = 4 - (base64.count % 4)
        if paddingLength < 4 { base64.append(String(repeating: "=", count: paddingLength)) }
        
        guard let data = Data(base64Encoded: base64),
              let key = keyString.data(using: .utf8),
              let iv = ivString.data(using: .utf8) else { return nil }
        
        let bufferSize = data.count + kCCBlockSizeAES128
        var buffer = Data(count: bufferSize)
        var numBytesDecrypted: size_t = 0
        
        let status = buffer.withUnsafeMutableBytes { bufferBytes in
            data.withUnsafeBytes { dataBytes in
                iv.withUnsafeBytes { ivBytes in
                    key.withUnsafeBytes { keyBytes in
                        CCCrypt(CCOperation(kCCDecrypt),
                                algorithm,
                                options,
                                keyBytes.baseAddress, kCCKeySizeAES128,
                                ivBytes.baseAddress,
                                dataBytes.baseAddress, data.count,
                                bufferBytes.baseAddress, bufferSize,
                                &numBytesDecrypted)
                    }
                }
            }
        }
        
        guard status == kCCSuccess else {
            print("Decryption failed with status: \(status)")
            return nil
        }
        
        buffer.removeSubrange(numBytesDecrypted..<buffer.count)
        return String(data: buffer, encoding: .utf8)
    }
}


//struct EncryptionHelper {
//    private static let keyString = "1234567890123456" // 16 bytes for AES-128
//    private static let ivString = "1234567890123456"  // 16 bytes for AES-128
//    private static let algorithm = CCAlgorithm(kCCAlgorithmAES)
//    private static let options = CCOptions(kCCOptionPKCS7Padding)
//
//    // Encrypt the given string using AES
//    static func encrypt(_ input: String) -> String? {
//        guard let data = input.data(using: .utf8),
//              let key = keyString.data(using: .utf8),
//              let iv = ivString.data(using: .utf8) else {
//            return nil
//        }
//
//        let bufferSize = data.count + kCCBlockSizeAES128
//        var buffer = Data(count: bufferSize)
//        var numBytesEncrypted: size_t = 0
//
//        let status = buffer.withUnsafeMutableBytes { bufferBytes in
//            data.withUnsafeBytes { dataBytes in
//                iv.withUnsafeBytes { ivBytes in
//                    key.withUnsafeBytes { keyBytes in
//                        CCCrypt(CCOperation(kCCEncrypt),
//                                algorithm,
//                                options,
//                                keyBytes.baseAddress, kCCKeySizeAES128,
//                                ivBytes.baseAddress,
//                                dataBytes.baseAddress, data.count,
//                                bufferBytes.baseAddress, bufferSize,
//                                &numBytesEncrypted)
//                    }
//                }
//            }
//        }
//
//        guard status == kCCSuccess else {
//            return nil
//        }
//
//        buffer.removeSubrange(numBytesEncrypted..<buffer.count)
//        let encryptedData = buffer.base64EncodedString()
//        // URL-safe Base64 encoding
//        return encryptedData.replacingOccurrences(of: "+", with: "-")
//                            .replacingOccurrences(of: "/", with: "_")
//                            .replacingOccurrences(of: "=", with: "")
//    }
//
//    // Decrypt the given URL-safe Base64 string using AES
//    static func decrypt(_ input: String) -> String? {
//        let base64 = input.replacingOccurrences(of: "-", with: "+")
//                          .replacingOccurrences(of: "_", with: "/")
//        guard let data = Data(base64Encoded: base64),
//              let key = keyString.data(using: .utf8),
//              let iv = ivString.data(using: .utf8) else {
//            return nil
//        }
//
//        let bufferSize = data.count + kCCBlockSizeAES128
//        var buffer = Data(count: bufferSize)
//        var numBytesDecrypted: size_t = 0
//
//        let status = buffer.withUnsafeMutableBytes { bufferBytes in
//            data.withUnsafeBytes { dataBytes in
//                iv.withUnsafeBytes { ivBytes in
//                    key.withUnsafeBytes { keyBytes in
//                        CCCrypt(CCOperation(kCCDecrypt),
//                                algorithm,
//                                options,
//                                keyBytes.baseAddress, kCCKeySizeAES128,
//                                ivBytes.baseAddress,
//                                dataBytes.baseAddress, data.count,
//                                bufferBytes.baseAddress, bufferSize,
//                                &numBytesDecrypted)
//                    }
//                }
//            }
//        }
//
//        guard status == kCCSuccess else {
//            return nil
//        }
//
//        buffer.removeSubrange(numBytesDecrypted..<buffer.count)
//        return String(data: buffer, encoding: .utf8)
//    }
//}
