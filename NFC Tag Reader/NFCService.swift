import SwiftUI

#if canImport(CoreNFC)
  import CoreNFC
#endif

// MARK: - Enum for NFC session types

enum NFCSessionType {
  case ndef  // Only read NDEF-formatted tags
  case tag  // Read any NFC tag
  case universal  // Tries the most universal method first
}

// MARK: - Protocol for common NFC operations

protocol NFCReaderProtocol: ObservableObject {
  var message: String { get set }
  var tagUID: String { get set }
  var tagContent: String { get set }
  var tagTechnology: String { get set }
  var isScanning: Bool { get set }

  func scanTag()
  func stopScan()
  func setSessionType(_ type: NFCSessionType)
}

// MARK: - Real NFC Reader (on device)

class NFCService: NSObject, NFCReaderProtocol, ObservableObject {

  // Published properties to update SwiftUI
  @Published var message: String = "Ready to scan"
  @Published var tagUID: String = ""
  @Published var tagContent: String = ""
  @Published var tagTechnology: String = ""
  @Published var isScanning: Bool = false

  // Keep track of session type
  private(set) var sessionType: NFCSessionType = .universal

  #if canImport(CoreNFC) && !targetEnvironment(simulator)
    // Because we’re on a real device with CoreNFC

    // We store references to NFC session objects
    private var ndefSession: NFCNDEFReaderSession?
    private var tagSession: NFCTagReaderSession?

    // Separate helpers for the two session approaches
    private var ndefDelegate: NFCNDEFReaderSessionDelegateHelper?
    private var tagDelegate: NFCTagReaderSessionDelegateHelper?

    override init() {
      super.init()
      self.message = "Ready to scan any NFC tag"

      // Prepare delegate helpers
      self.ndefDelegate = NFCNDEFReaderSessionDelegateHelper(service: self)
      self.tagDelegate = NFCTagReaderSessionDelegateHelper(service: self)
    }

    func setSessionType(_ type: NFCSessionType) {
      self.sessionType = type
      switch type {
      case .ndef:
        self.message = "Ready to scan NDEF tags"
      case .tag:
        self.message = "Ready to scan any NFC tags"
      case .universal:
        self.message = "Ready to scan any NFC tag"
      }
    }

    func scanTag() {
      // If device does not support either reading method, bail out
      if !NFCNDEFReaderSession.readingAvailable && !NFCTagReaderSession.readingAvailable {
        self.message = "This device does not support NFC"
        return
      }

      // Clear old readings
      self.tagUID = ""
      self.tagContent = ""
      self.tagTechnology = ""

      // Update UI
      self.isScanning = true
      self.message = "Hold your iPhone near an NFC tag"

      // Decide which session to start
      switch sessionType {
      case .ndef:
        startNDEFSession()
      case .tag:
        startTagSession()
      case .universal:
        // Try Tag Session first for broader support
        if NFCTagReaderSession.readingAvailable {
          startTagSession()
        } else if NFCNDEFReaderSession.readingAvailable {
          startNDEFSession()
        }
      }
    }

    func stopScan() {
      // Invalidate sessions if they exist
      ndefSession?.invalidate()
      tagSession?.invalidate()
      ndefSession = nil
      tagSession = nil

      self.isScanning = false
      self.message = "Scan stopped"
    }

    // Start an NDEF session
    private func startNDEFSession() {
      guard let delegate = self.ndefDelegate else { return }

      let session = NFCNDEFReaderSession(
        delegate: delegate,
        queue: nil,
        invalidateAfterFirstRead: false
      )
      session.alertMessage = "Hold your iPhone near an NDEF tag"
      session.begin()

      self.ndefSession = session
    }

    // Start a Tag session
    private func startTagSession() {
      guard let delegate = self.tagDelegate else { return }

      let session = NFCTagReaderSession(
        pollingOption: [.iso14443, .iso15693, .iso18092],
        delegate: delegate,
        queue: nil
      )
      session?.alertMessage = "Hold your iPhone near an NFC tag"
      session?.begin()

      self.tagSession = session
    }

  #else
    // MARK: - Fallback for Simulator or macOS Catalyst (no CoreNFC)

    override init() {
      super.init()
      self.message = "NFC is not available in Simulator"
    }

    func setSessionType(_ type: NFCSessionType) {
      self.sessionType = type
      self.message = "NFC unavailable in simulator"
    }

    func scanTag() {
      self.message = "NFC reading not available in simulator"
      // No real scanning — could simulate if you want
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
        self.tagUID = "SIMULATED:12:34:56"
        self.tagTechnology = "Simulator"
        self.tagContent = "Simulated tag data"
        self.message = "Simulated scan complete"
        self.isScanning = false
      }
      self.isScanning = true
    }

    func stopScan() {
      self.isScanning = false
      self.message = "Ready to scan (sim)"
    }
  #endif
}

// MARK: - Optional Mock for SwiftUI Previews or if you prefer a simpler simulator approach

class MockNFCReader: NFCReaderProtocol, ObservableObject {
  @Published var message: String = "Ready to scan (Preview)"
  @Published var tagUID: String = ""
  @Published var tagContent: String = ""
  @Published var tagTechnology: String = ""
  @Published var isScanning: Bool = false

  private(set) var sessionType: NFCSessionType = .ndef

  func setSessionType(_ type: NFCSessionType) {
    self.sessionType = type
  }

  func scanTag() {
    isScanning = true
    message = "Simulating NFC scan in Preview…"

    // Show fake results after delay
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      self.isScanning = false
      self.message = "Mock scan complete"
      self.tagUID = "AB:CD:EF:12:34:56"
      self.tagTechnology = "PREVIEW"
      self.tagContent = "Preview data only"
    }
  }

  func stopScan() {
    isScanning = false
    message = "Ready to scan (Preview)"
  }
}

#if canImport(CoreNFC) && !targetEnvironment(simulator)

  // MARK: - NDEF Delegate Helper

  private class NFCNDEFReaderSessionDelegateHelper: NSObject, NFCNDEFReaderSessionDelegate {
    weak var service: NFCService?

    init(service: NFCService) {
      self.service = service
    }

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
      DispatchQueue.main.async {
        guard let svc = self.service else { return }
        svc.isScanning = false

        // Common time‐out check
        if error.localizedDescription.contains("Session timeout") {
          svc.message = "Scanning timed out"
        } else {
          svc.message = "Error: \(error.localizedDescription)"
        }
      }
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
      // If multiple messages, process them all
      processNDEFMessages(messages)
    }

    // Some iOS versions also call this for newly detected tags:
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
      if let firstTag = tags.first {
        session.connect(to: firstTag) { [weak self] error in
          guard let self = self, let service = self.service else { return }
          if let error = error {
            session.invalidate(errorMessage: "Connection error: \(error.localizedDescription)")
            return
          }
          self.handleConnectedNDEFTag(firstTag, session: session)
        }
      } else {
        session.invalidate(errorMessage: "No NDEF tag found")
      }
    }

    private func handleConnectedNDEFTag(_ tag: NFCNDEFTag, session: NFCNDEFReaderSession) {
      let (uid, tech) = detectTagInfo(from: tag)
      DispatchQueue.main.async {
        self.service?.tagUID = uid
        self.service?.tagTechnology = tech
      }

      tag.queryNDEFStatus { status, _, error in
        if let error = error {
          session.invalidate(errorMessage: "Error reading NDEF: \(error.localizedDescription)")
          return
        }
        switch status {
        case .notSupported:
          session.invalidate(errorMessage: "Tag is not NDEF‐formatted")
        case .readOnly, .readWrite:
          tag.readNDEF { message, err in
            if let err = err {
              session.invalidate(errorMessage: "Reading error: \(err.localizedDescription)")
              return
            }
            if let message = message {
              // We got an NDEF message
              self.processNDEFMessages([message])
              session.alertMessage = "Tag read successfully."
            } else {
              session.invalidate(errorMessage: "No NDEF content found.")
            }
          }
        @unknown default:
          session.invalidate(errorMessage: "Unknown NDEF status.")
        }
      }
    }

    // Utility to parse tag info (UID, tech name, etc.)
    private func detectTagInfo(from tag: NFCNDEFTag) -> (String, String) {
      if let iso7816 = tag as? NFCISO7816Tag {
        let uidHex = iso7816.identifier.map { String(format: "%02X", $0) }.joined(separator: ":")
        return (uidHex, "ISO7816")
      } else if let iso15693 = tag as? NFCISO15693Tag {
        let uidHex = iso15693.identifier.map { String(format: "%02X", $0) }.joined(separator: ":")
        return (uidHex, "ISO15693")
      } else if let mifare = tag as? NFCMiFareTag {
        let uidHex = mifare.identifier.map { String(format: "%02X", $0) }.joined(separator: ":")
        return (uidHex, "MIFARE")
      } else if let felica = tag as? NFCFeliCaTag {
        let uidHex = felica.currentIDm.map { String(format: "%02X", $0) }.joined(separator: ":")
        return (uidHex, "FeliCa")
      }
      return ("UnknownTag", "UnknownTech")
    }

    // Read each record in the NDEF message
    private func processNDEFMessages(_ ndefMessages: [NFCNDEFMessage]) {
      var aggregate = ""
      for msg in ndefMessages {
        for record in msg.records {
          aggregate += "Type: \(String(data: record.type, encoding: .utf8) ?? "Unknown")\n"
          // Example: parse well‐known text/URI records
          if record.typeNameFormat == .nfcWellKnown {
            if let typeString = String(data: record.type, encoding: .utf8) {
              if typeString == "T" {
                aggregate += parseTextRecord(record)
              } else if typeString == "U" {
                aggregate += parseURIRecord(record)
              }
            }
          }
          // If still no meaningful parse, try normal string
          if record.payload.count > 0 {
            if let str = String(data: record.payload, encoding: .utf8), !str.isEmpty {
              aggregate += "Content: \(str)\n"
            } else {
              // Hex fallback
              let hexData = record.payload.map { String(format: "%02X", $0) }.joined()
              aggregate += "Data (hex): \(hexData)\n"
            }
          }
          aggregate += "---\n"
        }
      }
      DispatchQueue.main.async {
        self.service?.tagContent = aggregate.isEmpty ? "No readable content" : aggregate
        self.service?.message = "Tag read successfully"
        self.service?.isScanning = false
      }
    }

    private func parseTextRecord(_ record: NFCNDEFPayload) -> String {
      // Byte 0 has language code length in low 6 bits
      guard record.payload.count > 1 else { return "" }
      let langLength = Int(record.payload[0] & 0x3F)
      let langCode = record.payload.subdata(in: 1..<(1 + langLength))
      let textData = record.payload.subdata(in: (1 + langLength)..<record.payload.count)

      if let langStr = String(data: langCode, encoding: .utf8),
        let textStr = String(data: textData, encoding: .utf8)
      {
        return "Text (\(langStr)): \(textStr)\n"
      }
      return ""
    }

    private func parseURIRecord(_ record: NFCNDEFPayload) -> String {
      guard record.payload.count > 1 else { return "" }
      let prefixByte = record.payload[0]
      let uriBytes = record.payload.subdata(in: 1..<record.payload.count)
      let prefixString = uriPrefix(from: prefixByte)
      if let uriBody = String(data: uriBytes, encoding: .utf8) {
        return "URI: \(prefixString)\(uriBody)\n"
      }
      return ""
    }

    private func uriPrefix(from byte: UInt8) -> String {
      // Standard URI prefix table
      switch byte {
      case 0x01: return "http://www."
      case 0x02: return "https://www."
      case 0x03: return "http://"
      case 0x04: return "https://"
      case 0x05: return "tel:"
      case 0x06: return "mailto:"
      // ...
      // (Truncated for brevity: add the full table if you like)
      default: return ""
      }
    }
  }

  // MARK: - Tag Reader Delegate Helper (non‐NDEF or universal approach)
  #if canImport(CoreNFC) && !targetEnvironment(simulator)
    import CoreNFC

    @available(iOS 13.0, *)
    private class NFCTagReaderSessionDelegateHelper: NSObject, NFCTagReaderSessionDelegate {
      weak var service: NFCService?

      init(service: NFCService) {
        self.service = service
        super.init()  // Valid now that we inherit from NSObject
      }

      func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async {
          guard let svc = self.service else { return }
          svc.isScanning = false
          if error.localizedDescription.contains("Session timeout") {
            svc.message = "Scanning timed out"
          } else {
            svc.message = "Error: \(error.localizedDescription)"
          }
        }
      }

      func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let firstTag = tags.first else {
          session.invalidate(errorMessage: "No NFC tag found.")
          return
        }
        session.connect(to: firstTag) { [weak self] error in
          guard let self = self, let svc = self.service else { return }
          if let error = error {
            session.invalidate(errorMessage: "Connection error: \(error.localizedDescription)")
            return
          }
          self.handleConnectedTag(firstTag, session: session, service: svc)
        }
      }

      private func handleConnectedTag(
        _ tag: NFCTag,
        session: NFCTagReaderSession,
        service: NFCService
      ) {
        let (uid, tech) = detectTagType(tag)
        DispatchQueue.main.async {
          service.tagUID = uid
          service.tagTechnology = tech
        }

        var resultText = "Tag Type: \(tech)\nUID: \(uid)\n"

        // For example only:
        switch tag {
        case .miFare(let miFareTag):
          resultText += "MIFARE Family: \(miFareTag.mifareFamily)\n"
          finish(resultText, session, service)

        case .feliCa(let feliCaTag):
          let sysCodeHex = feliCaTag.currentSystemCode.map { String(format: "%02X", $0) }.joined()
          resultText += "FeliCa System Code: \(sysCodeHex)\n"
          finish(resultText, session, service)

        case .iso7816(let iso7816Tag):
          let histBytes =
            iso7816Tag.historicalBytes?.map { String(format: "%02X", $0) }.joined() ?? "None"
          resultText += "ISO7816 Historical Bytes: \(histBytes)\n"
          finish(resultText, session, service)

        case .iso15693(let iso15693Tag):
          let mfCode = String(format: "%02X", iso15693Tag.icManufacturerCode)
          resultText += "ISO15693 Manufacturer Code: \(mfCode)\n"
          iso15693Tag.readSingleBlock(requestFlags: .highDataRate, blockNumber: 0) { data, err in
            if let err = err {
              resultText += "Error reading block: \(err.localizedDescription)\n"
            } else {
              let blockHex = data.map { String(format: "%02X", $0) }.joined(separator: " ")
              resultText += "Block0: \(blockHex)\n"
            }
            self.finish(resultText, session, service)
          }

        @unknown default:
          resultText += "Unknown or unsupported tag type\n"
          finish(resultText, session, service)
        }
      }

      private func finish(
        _ text: String,
        _ session: NFCTagReaderSession,
        _ service: NFCService
      ) {
        DispatchQueue.main.async {
          service.tagContent = text
          service.message = "Tag read successfully"
          service.isScanning = false
        }
        session.alertMessage = "Tag read successfully"
        // Optionally: session.invalidate() if you only want 1 read
      }

      private func detectTagType(_ tag: NFCTag) -> (String, String) {
        switch tag {
        case .miFare(let miFareTag):
          let uid = miFareTag.identifier.map { String(format: "%02X", $0) }.joined(separator: ":")
          return (uid, "MIFARE")

        case .feliCa(let feliCaTag):
          let uid = feliCaTag.currentIDm.map { String(format: "%02X", $0) }.joined(separator: ":")
          return (uid, "FeliCa")

        case .iso7816(let iso7816Tag):
          let uid = iso7816Tag.identifier.map { String(format: "%02X", $0) }.joined(separator: ":")
          return (uid, "ISO7816")

        case .iso15693(let iso15693Tag):
          let uid = iso15693Tag.identifier.map { String(format: "%02X", $0) }.joined(separator: ":")
          return (uid, "ISO15693")

        @unknown default:
          return ("UnknownUID", "UnknownTech")
        }
      }
    }
  #endif

#endif
