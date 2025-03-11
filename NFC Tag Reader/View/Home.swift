import SwiftUI

struct Home: View {
  // Pick real or mock based on environment:
  #if targetEnvironment(simulator)
    @StateObject private var reader = MockNFCReader()
  #else
    @StateObject private var reader = NFCService()
  #endif

  @State private var selectedMode = 2  // universal by default
  private let modes = ["NDEF Only", "Tag Mode", "Universal"]

  var body: some View {
    VStack(spacing: 20) {
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

      // Optional scanning animation
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
              ? Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)
              : .default,
            value: reader.isScanning
          )
      }
      .padding()

      // Tag info
      ScrollView {
        VStack(alignment: .leading, spacing: 10) {
          if !reader.tagUID.isEmpty {
            HStack {
              Text("UID:")
                .fontWeight(.bold)
              Text(reader.tagUID)
                .font(.system(.body, design: .monospaced))
            }
          }
          if !reader.tagTechnology.isEmpty {
            HStack {
              Text("Technology:")
                .fontWeight(.bold)
              Text(reader.tagTechnology)
                .font(.system(.body, design: .monospaced))
            }
          }
          if !reader.tagContent.isEmpty {
            VStack(alignment: .leading) {
              Text("Content:")
                .fontWeight(.bold)
              Text(reader.tagContent)
                .font(.system(.body, design: .monospaced))
                .padding(8)
                .background(
                  RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.15))
                )
            }
          }
        }
        .padding()
        .background(
          RoundedRectangle(cornerRadius: 10)
            .fill(Color.gray.opacity(0.2))
        )
        .padding(.horizontal)
      }
      .frame(maxHeight: 220)

      // Mode selector
      VStack(alignment: .leading) {
        Text("Select NFC Reader Mode:")
          .font(.headline)
          .padding(.horizontal)

        Picker("NFC Mode", selection: $selectedMode) {
          Text("NDEF Only").tag(0)
          Text("Tag Mode").tag(1)
          Text("Universal").tag(2)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
        .onChange(of: selectedMode) { newValue in
          let sessionType: NFCSessionType
          switch newValue {
          case 0: sessionType = .ndef
          case 1: sessionType = .tag
          default: sessionType = .universal
          }
          reader.setSessionType(sessionType)
        }

        Text("Use Tag Mode for non-NDEF cards like MIFARE, FeliCa, etc.")
          .font(.caption)
          .foregroundColor(.secondary)
          .padding(.horizontal)
      }

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

#Preview {
  Home()
}
