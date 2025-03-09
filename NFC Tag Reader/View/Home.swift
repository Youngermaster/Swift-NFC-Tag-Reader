import SwiftUI

// A simple protocol for our NFC readers
protocol NFCReaderProtocol: ObservableObject {
  var message: String { get set }
  var tagUID: String { get set }
  var tagContent: String { get set }
  var tagTechnology: String { get set }
  var isScanning: Bool { get set }

  func scanTag()
  func stopScan()
}

// Common base class for both real and mock implementations
class NFCReaderBase: NSObject, NFCReaderProtocol {
  @Published var message: String = "Ready to scan"
  @Published var tagUID: String = ""
  @Published var tagContent: String = ""
  @Published var tagTechnology: String = ""
  @Published var isScanning: Bool = false

  func scanTag() {
    // Override in subclasses
  }

  func stopScan() {
    // Override in subclasses
  }
}

// For preview and simulator, use this mock class
class MockNFCReader: NFCReaderBase {
  override init() {
    super.init()
    message = "Ready to scan (Preview)"
  }

  override func scanTag() {
    isScanning = true
    message = "Simulating a scan (Preview only)"

    // For previews, show simulated data after a delay
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
      self?.isScanning = false
      self?.message = "Scan complete (Preview)"
      self?.tagUID = "AB:CD:EF:12:34:56"
      self?.tagTechnology = "PREVIEW"
      self?.tagContent = "This is preview data only\nReal NFC tags will be read on device."
    }
  }

  override func stopScan() {
    isScanning = false
    message = "Ready to scan (Preview)"
  }
}

struct Home: View {
  // Use the appropriate reader based on environment
  // #if targetEnvironment(simulator)
  //   @StateObject private var reader = MockNFCReader()
  // #else
  @StateObject private var reader = RealNFCReader()
  // #endif

  var body: some View {
    VStack(spacing: 20) {
      // Header
      Text("NFC Tag Reader")
        .font(.largeTitle)
        .fontWeight(.bold)
        .padding(.top)

      // Current status
      Text(reader.message)
        .font(.headline)
        .foregroundColor(reader.isScanning ? .blue : .primary)
        .padding()
        .frame(maxWidth: .infinity)
        .background(
          RoundedRectangle(cornerRadius: 10)
            .fill(Color.gray.opacity(0.2))
        )
        .padding(.horizontal)

      // Scanning animation
      ZStack {
        Circle()
          .fill(Color.blue.opacity(0.1))
          .frame(width: 200, height: 200)

        Image(systemName: "radiowaves.left")
          .font(.system(size: 80))
          .foregroundColor(.blue)
          .opacity(reader.isScanning ? 1.0 : 0.5)
          .scaleEffect(reader.isScanning ? 1.2 : 1.0)
          .animation(
            reader.isScanning
              ? Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true) : .default,
            value: reader.isScanning)
      }
      .padding()

      // Tag information section
      ScrollView {
        VStack(alignment: .leading, spacing: 10) {
          if !reader.tagUID.isEmpty {
            HStack {
              Text("UID:").fontWeight(.bold)
              Text(reader.tagUID)
                .font(.system(.body, design: .monospaced))
            }
            .padding(.horizontal)
          }

          if !reader.tagTechnology.isEmpty {
            HStack {
              Text("Technology:").fontWeight(.bold)
              Text(reader.tagTechnology)
                .font(.system(.body, design: .monospaced))
            }
            .padding(.horizontal)
          }

          if !reader.tagContent.isEmpty {
            VStack(alignment: .leading) {
              Text("Content:").fontWeight(.bold)
              Text(reader.tagContent)
                .font(.system(.body, design: .monospaced))
                .padding(8)
                .background(
                  RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.15))
                )
            }
            .padding(.horizontal)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
          RoundedRectangle(cornerRadius: 10)
            .fill(Color.gray.opacity(0.2))
            .opacity(reader.tagUID.isEmpty && reader.tagContent.isEmpty ? 0 : 1)
        )
        .padding(.horizontal)
        .opacity(reader.tagUID.isEmpty && reader.tagContent.isEmpty ? 0 : 1)
      }
      .frame(maxHeight: 250)

      Spacer()

      // Scan button
      Button(action: {
        if reader.isScanning {
          reader.stopScan()
        } else {
          reader.scanTag()
        }
      }) {
        HStack {
          Image(systemName: reader.isScanning ? "xmark.circle" : "wave.3.right")
          Text(reader.isScanning ? "Stop" : "Scan NFC Tag")
        }
        .font(.headline)
        .foregroundColor(.white)
        .padding()
        .frame(maxWidth: .infinity)
        .background(
          RoundedRectangle(cornerRadius: 10)
            .fill(reader.isScanning ? Color.red : Color.blue)
        )
        .padding(.horizontal)
      }
      .padding(.bottom)
    }
    .padding()
  }
}

// Dummy class that will be dynamically replaced at runtime
class RealNFCReader: NFCReaderBase {
  override init() {
    super.init()
    // This is replaced at runtime with the real NFCService from NFCService.swift
    message = "Ready to scan a real tag"
  }

  override func scanTag() {
    message = "NFC service not available - reinstall app"
  }
}

#Preview {
  Home()
}
