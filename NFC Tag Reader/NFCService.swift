import CoreNFC
import Foundation
import SwiftUI

// Real NFC implementation using CoreNFC
// This will replace RealNFCReader at runtime
class NFCService: NFCReaderBase, NFCNDEFReaderSessionDelegate {
  // We don't need to redeclare properties that are already in the base class
  // Just use the ones from NFCReaderBase

  // NFC session
  private var nfcSession: NFCNDEFReaderSession?

  // Initialize with a better message
  override init() {
    super.init()
    message = "Ready to scan a real NFC tag"
  }

  // Start scanning for real NFC tags
  override func scanTag() {
    guard NFCNDEFReaderSession.readingAvailable else {
      self.message = "This device doesn't support NFC tag reading"
      return
    }

    // Clear previous data
    self.tagUID = ""
    self.tagContent = ""
    self.tagTechnology = ""

    // Update status
    self.isScanning = true
    self.message = "Hold your iPhone near an NFC tag"

    // Create and begin NFC session
    nfcSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
    nfcSession?.alertMessage = "Hold your iPhone near an NFC tag"
    nfcSession?.begin()
  }

  // Stop scanning
  override func stopScan() {
    nfcSession?.invalidate()
    self.isScanning = false
    self.message = "Scan stopped"
  }

  // MARK: - NFCNDEFReaderSessionDelegate Methods

  // Called when the session expires or encounters an error
  func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
    DispatchQueue.main.async {
      self.isScanning = false

      // For timeout error, show a friendly message
      if error.localizedDescription.contains("Session timeout") {
        self.message = "Scanning timed out"
      } else {
        self.message = "Reading error: \(error.localizedDescription)"
      }
    }
  }

  // Called when NDEF messages are detected
  func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
    // Process NDEF messages
    var resultText = ""

    for message in messages {
      for record in message.records {
        // Add record type
        resultText += "Type: \(String(data: record.type, encoding: .utf8) ?? "Unknown")\n"

        // Process payload based on its type
        if record.typeNameFormat == .nfcWellKnown {
          // URI well-known record
          if let typeString = String(data: record.type, encoding: .utf8), typeString == "U" {
            if record.payload.count > 1 {
              // First byte indicates URI prefix
              let prefixByte = record.payload[0]
              let prefixString = getURIPrefix(from: prefixByte)

              // Rest is URI content
              let uriPayload = record.payload.subdata(in: 1..<record.payload.count)
              if let uriString = String(data: uriPayload, encoding: .utf8) {
                resultText += "URI: \(prefixString)\(uriString)\n"
              }
            }
          }
          // Text well-known record
          else if let typeString = String(data: record.type, encoding: .utf8), typeString == "T" {
            if record.payload.count > 1 {
              // First byte contains language code
              let languageCodeLength = Int(record.payload[0] & 0x3F)
              let languageCodeData = record.payload.subdata(in: 1..<(1 + languageCodeLength))
              let textData = record.payload.subdata(
                in: (1 + languageCodeLength)..<record.payload.count)

              if let languageCode = String(data: languageCodeData, encoding: .utf8),
                let text = String(data: textData, encoding: .utf8)
              {
                resultText += "Text (\(languageCode)): \(text)\n"
              }
            }
          }
        }

        // If we couldn't process specifically, show payload as text
        if resultText.isEmpty || (!resultText.contains("URI:") && !resultText.contains("Text (")) {
          if let payloadText = String(data: record.payload, encoding: .utf8) {
            resultText += "Content: \(payloadText)\n"
          } else {
            // If it can't be interpreted as text, show in hexadecimal
            let hexString = record.payload.map { String(format: "%02X", $0) }.joined()
            resultText += "Data (HEX): \(hexString)\n"
          }
        }

        resultText += "---\n"
      }
    }

    DispatchQueue.main.async {
      self.tagContent = resultText.isEmpty ? "No readable content" : resultText
      self.message = "Tag read successfully"
      self.isScanning = false
    }
  }

  // Called when a tag is detected
  func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
    // Connect to the first tag found
    if let tag = tags.first {
      session.connect(to: tag) { error in
        if let error = error {
          session.invalidate(errorMessage: "Connection error: \(error.localizedDescription)")
          return
        }

        // Get technology and UID
        let tagInfo = self.detectTagType(tag: tag)

        DispatchQueue.main.async {
          self.tagUID = tagInfo.uid
          self.tagTechnology = tagInfo.technology
        }

        // Read NDEF content from the tag
        tag.queryNDEFStatus { status, capacity, error in
          if let error = error {
            session.invalidate(errorMessage: "Error reading NDEF: \(error.localizedDescription)")
            return
          }

          switch status {
          case .notSupported:
            session.invalidate(errorMessage: "Tag doesn't support NDEF")
          case .readOnly, .readWrite:
            tag.readNDEF { message, error in
              if let error = error {
                session.invalidate(
                  errorMessage: "Error reading NDEF: \(error.localizedDescription)")
                return
              }
              if let message = message {
                // Process message
                self.readerSession(session, didDetectNDEFs: [message])
                session.alertMessage = "Tag read successfully"
                // Keep session active for more reads
              } else {
                session.invalidate(errorMessage: "No NDEF content found")
              }
            }
          @unknown default:
            session.invalidate(errorMessage: "Unknown NDEF status")
          }
        }
      }
    } else {
      session.invalidate(errorMessage: "No compatible tag found")
    }
  }

  // MARK: - Helper Methods

  // Helper function to detect technology type and get UID
  private func detectTagType(tag: NFCNDEFTag) -> (uid: String, technology: String) {
    if let iso7816Tag = tag as? NFCISO7816Tag {
      let uidString = iso7816Tag.identifier.map { String(format: "%02X", $0) }.joined(
        separator: ":")
      return (uidString, "ISO 7816")
    } else if let iso15693Tag = tag as? NFCISO15693Tag {
      let uidString = iso15693Tag.identifier.map { String(format: "%02X", $0) }.joined(
        separator: ":")
      return (uidString, "ISO 15693")
    } else if let miFareTag = tag as? NFCMiFareTag {
      let uidString = miFareTag.identifier.map { String(format: "%02X", $0) }.joined(separator: ":")
      return (uidString, "MIFARE")
    } else if let feliCaTag = tag as? NFCFeliCaTag {
      let uidString = feliCaTag.currentIDm.map { String(format: "%02X", $0) }.joined(separator: ":")
      return (uidString, "FeliCa")
    }

    // If we can't determine specific type, return unknown
    return ("Unknown Tag ID", "Unknown Technology")
  }

  // Helper function to get URI prefix from standard NFC byte
  private func getURIPrefix(from byte: UInt8) -> String {
    switch byte {
    case 0x01: return "http://www."
    case 0x02: return "https://www."
    case 0x03: return "http://"
    case 0x04: return "https://"
    case 0x05: return "tel:"
    case 0x06: return "mailto:"
    case 0x07: return "ftp://anonymous:anonymous@"
    case 0x08: return "ftp://ftp."
    case 0x09: return "ftps://"
    case 0x0A: return "sftp://"
    case 0x0B: return "smb://"
    case 0x0C: return "nfs://"
    case 0x0D: return "ftp://"
    case 0x0E: return "dav://"
    case 0x0F: return "news:"
    case 0x10: return "telnet://"
    case 0x11: return "imap:"
    case 0x12: return "rtsp://"
    case 0x13: return "urn:"
    case 0x14: return "pop:"
    case 0x15: return "sip:"
    case 0x16: return "sips:"
    case 0x17: return "tftp:"
    case 0x18: return "btspp://"
    case 0x19: return "btl2cap://"
    case 0x1A: return "btgoep://"
    case 0x1B: return "tcpobex://"
    case 0x1C: return "irdaobex://"
    case 0x1D: return "file://"
    case 0x1E: return "urn:epc:id:"
    case 0x1F: return "urn:epc:tag:"
    case 0x20: return "urn:epc:pat:"
    case 0x21: return "urn:epc:raw:"
    case 0x22: return "urn:epc:"
    case 0x23: return "urn:nfc:"
    default: return ""
    }
  }
}

// Protocol for NFCTag to get identifier
protocol NFCTagType {
  var identifier: Data { get }
}

// Adapter class instead of protocol extension
class NFCTagAdapter: NFCTagType {
  private let tag: NFCNDEFTag

  init(tag: NFCNDEFTag) {
    self.tag = tag
  }

  var identifier: Data {
    // Try to get real tag identifier
    if let iso7816Tag = tag as? NFCISO7816Tag {
      return iso7816Tag.identifier
    } else if let iso15693Tag = tag as? NFCISO15693Tag {
      return iso15693Tag.identifier
    } else if let miFareTag = tag as? NFCMiFareTag {
      return miFareTag.identifier
    } else if let feliCaTag = tag as? NFCFeliCaTag {
      return feliCaTag.currentIDm
    }

    // If we can't determine specific type, create unique ID based on timestamp
    // This ensures each read has a different ID
    let timestamp = UInt64(Date().timeIntervalSince1970 * 1000)
    var timestampData = Data()
    withUnsafeBytes(of: timestamp) { timestampData.append(contentsOf: $0) }
    return timestampData
  }
}

// Función auxiliar para obtener un adaptador para cualquier tag
func getTagAdapter(for tag: NFCNDEFTag) -> NFCTagType {
  return NFCTagAdapter(tag: tag)
}
