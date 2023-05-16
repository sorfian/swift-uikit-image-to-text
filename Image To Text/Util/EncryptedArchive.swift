//
//  EncryptedArchive.swift
//  Image To Text
//
//  Created by Sorfian on 15/05/23.
//

import Foundation
import System
import AppleArchive
import CryptoKit

struct EncryptedArchive {
    
    public enum Error: Swift.Error {
        case unableToCreateDecodeStream
        case unableToGetHeaderField
        case zeroDataSize
        case unableToCreateFileStream
        case unableToCreateEncryptionStream
        case unableToCreateDecryptionContext
    }
    
    // MARK: File Demo
    
    static func file(encrypt: Bool = false, decrypt: Bool = false) {
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let sourceFileURL = documentsUrl?.appending(path: "filedatatext.txt") else {return}
        guard let encryptedFileURL = documentsUrl?.appending(path: "filedatatext.encrypted") else {return}
        
        guard let sourceFilePath = FilePath(sourceFileURL) else {return}
        guard let encryptedFilePath = FilePath(encryptedFileURL) else {return}
        
        let key = SymmetricKey(size: SymmetricKeySize.bits256)
        let savedKey = key.withUnsafeBytes {
            Data(Array($0)).base64EncodedString()
        }
        
        // Access Shared Defaults Object
        let userDefaults = UserDefaults.standard
        var myKey = ""
        
        if let saveKey = userDefaults.string(forKey: "savedKey") {
            myKey = saveKey
        } else {
            userDefaults.set(savedKey, forKey: "savedKey")
            
            guard let saveKey = userDefaults.string(forKey: "savedKey") else { return }
            myKey = saveKey
        }
        
        
        if encrypt {
            // Encrypt file.
            do {
                if let keyData = Data(base64Encoded: myKey) {
                    let retrievedKey = SymmetricKey(data: keyData)
                    try encryptFile(key: retrievedKey,
                                    sourceFilePath: sourceFilePath,
                                    destinationFilePath: encryptedFilePath)
                }
            } catch {
                print("Encryption failed:", error)
            }
        }
        
        if decrypt {
            // Decrypt file.
            do {
                if let keyData = Data(base64Encoded: myKey) {
                    let retrievedKey = SymmetricKey(data: keyData)
                    try decryptFile(key: retrievedKey,
                                    sourceFilePath: encryptedFilePath,
                                    destinationFilePath: sourceFilePath)
                }
            } catch {
                print("Decryption failed:", error)
            }
        }
        
    }
    
    static func encryptFile(key: SymmetricKey,
                            sourceFilePath: FilePath,
                            destinationFilePath: FilePath) throws {
        
        // Create the encryption context.
        let context = ArchiveEncryptionContext(profile: .hkdf_sha256_aesctr_hmac__symmetric__none,
                                               compressionAlgorithm: .lzfse)
        try context.setSymmetricKey(key)
        
        // Create a file stream to open the source file and a file stream for
        // the encrypted file destination.
        guard let sourceFileStream = ArchiveByteStream.fileStream(
                path: sourceFilePath,
                mode: .readOnly,
                options: [ ],
                permissions: FilePermissions(rawValue: 0o644)),
              let destinationFileStream = ArchiveByteStream.fileStream(
                path: destinationFilePath,
                mode: .writeOnly,
                options: [ .create, .truncate ],
                permissions: FilePermissions(rawValue: 0o644)) else {
            throw Error.unableToCreateFileStream
        }
        
        // Create the encryption output stream.
        guard let encryptionStream = ArchiveByteStream.encryptionStream(
                writingTo: destinationFileStream,
                encryptionContext: context) else {
            throw Error.unableToCreateEncryptionStream
        }
        
        // Process the source file stream, resulting in the encryption stream
        // writing an encrypted version of the source to the destination.
        _ = try ArchiveByteStream.process(readingFrom: sourceFileStream,
                                          writingTo: encryptionStream)
        
        // Close the file streams.
        try encryptionStream.close()
        try sourceFileStream.close()
        try destinationFileStream.close()
    }
 
    static func decryptFile(key: SymmetricKey,
                            sourceFilePath: FilePath,
                            destinationFilePath: FilePath) throws {
        
        // Create a file stream to open the encrypted source file.
        guard let sourceFileStream = ArchiveByteStream.fileStream(
                path: sourceFilePath,
                mode: .readOnly,
                options: [ ],
                permissions: FilePermissions(rawValue: 0o644)) else {
            throw Error.unableToCreateFileStream
        }
        
        // Create the decryption context from the encrypted file. The compression
        // algorithm and block size are derived from the encrypted source file.
        guard let decryptionContext = ArchiveEncryptionContext(from: sourceFileStream) else {
            throw Error.unableToCreateDecryptionContext
        }
        
        // Set the key on the context.
        try decryptionContext.setSymmetricKey(key)
        
        // Create the decryption output stream.
        guard let decryptionStream = ArchiveByteStream.decryptionStream(
            readingFrom: sourceFileStream,
            encryptionContext: decryptionContext) else {
            throw Error.unableToCreateFileStream
        }
        
        // Create the destination file stream. Define the options as `[ .create, .truncate ]`.
        // The `.create` option specifies that the byte stream creates the file
        // if it doesn’t already exist. The `.truncate` option specifies that if
        // the file exists, the byte stream truncates it to zero bytes before it
        // performs any operations.
        guard let decryptedFileStream = ArchiveByteStream.fileStream(
            path: destinationFilePath,
            mode: .writeOnly,
            options: [ .create, .truncate ],
            permissions: FilePermissions(rawValue: 0o644)) else {
            throw Error.unableToCreateFileStream
        }
        
        // Process the encrypted source file stream, resulting in the decryption
        // stream writing a decrypted version of the source to the destination.
        _ = try ArchiveByteStream.process(readingFrom: decryptionStream,
                                          writingTo: decryptedFileStream)
        
        // Close the file streams.
        try decryptedFileStream.close()
        try sourceFileStream.close()
        try decryptedFileStream.close()
    }
}
