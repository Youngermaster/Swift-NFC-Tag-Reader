//
//  ContentView.swift
//  NFC Tag Reader MIFARE
//
//  Created by Juan Manuel Young Hoyos on 15/03/25.
//

import CoreNFC
import SwiftUI

class NFCReader: NSObject, ObservableObject, NFCTagReaderSessionDelegate {
    @Published var message = "Presiona el botón para escanear una etiqueta NFC"
    @Published var tagInfo = ""

    var session: NFCTagReaderSession?

    func scan() {
        session = NFCTagReaderSession(pollingOption: .iso14443, delegate: self)
        session?.alertMessage = "Acerca tu dispositivo a una etiqueta NFC MIFARE"
        session?.begin()
    }

    // MARK: - NFCTagReaderSessionDelegate

    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        // Este método se llama cuando la sesión ha iniciado correctamente
        print("Sesión NFC activa")
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        // Se llama cuando la sesión termina con un error
        print("Error en la sesión NFC: \(error.localizedDescription)")

        DispatchQueue.main.async {
            self.message = "Error en la sesión: \(error.localizedDescription)"
        }
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        // Se llama cuando se detecta un tag NFC
        if tags.count > 1 {
            // Restart polling in 500ms
            let retryInterval = DispatchTimeInterval.milliseconds(500)
            session.alertMessage =
                "Más de una etiqueta detectada. Por favor acerca solo una etiqueta."
            DispatchQueue.global().asyncAfter(deadline: .now() + retryInterval) {
                session.restartPolling()
            }
            return
        }

        let tag = tags.first!

        // Conectar con la etiqueta
        session.connect(to: tag) { (error) in
            if let error = error {
                session.alertMessage = "Error: \(error.localizedDescription)"
                session.invalidate()
                return
            }

            DispatchQueue.main.async {
                self.message = "Etiqueta NFC detectada!"
                self.processTag(tag)
            }

            session.alertMessage = "Etiqueta leída correctamente"
            session.invalidate()
        }
    }

    private func processTag(_ tag: NFCTag) {
        var info = ""

        switch tag {
        case .miFare(let mifareTag):
            info += "Tipo: MIFARE\n"
            info += "Identificador: \(mifareTag.identifier.hexDescription)\n"
            info += "Tipo MIFARE: \(mifareTag.mifareFamily.description)\n"

            if let historicalBytes = mifareTag.historicalBytes {
                info += "Bytes históricos: \(historicalBytes.hexDescription)\n"
            }

        case .iso7816(let iso7816Tag):
            info += "Tipo: ISO-7816\n"
            info += "Identificador: \(iso7816Tag.identifier.hexDescription)\n"

            if let historicalBytes = iso7816Tag.historicalBytes {
                info += "Bytes históricos: \(historicalBytes.hexDescription)\n"
            }

        case .iso15693(let iso15693Tag):
            info += "Tipo: ISO-15693\n"
            info += "Identificador: \(iso15693Tag.identifier.hexDescription)\n"
            info += "Fabricante: \(iso15693Tag.icManufacturerCode)\n"

        case .feliCa(let feliCaTag):
            info += "Tipo: FeliCa\n"
            info += "Identificador: \(feliCaTag.currentIDm.hexDescription)\n"
            info += "Sistema de código: \(feliCaTag.currentSystemCode.hexDescription)\n"

        default:
            info += "Tipo de etiqueta desconocido\n"
        }

        tagInfo = info
    }
}

extension Data {
    /// Conversión hexadecimal
    var hexDescription: String {
        return self.map { String(format: "%02hhx", $0) }.joined()
    }
}

extension NFCMiFareFamily {
    var description: String {
        switch self {
        case .plus: return "MIFARE Plus"
        case .desfire: return "MIFARE DESFire"
        case .ultralight: return "MIFARE Ultralight"
        case .unknown: return "MIFARE desconocido"
        @unknown default: return "MIFARE tipo nuevo desconocido"
        }
    }
}

struct ContentView: View {
    @StateObject private var nfcReader = NFCReader()

    var body: some View {
        VStack(spacing: 20) {
            Text("Lector de Etiquetas NFC MIFARE")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding()

            Spacer()

            Text(nfcReader.message)
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding()

            if !nfcReader.tagInfo.isEmpty {
                ScrollView {
                    VStack(alignment: .leading) {
                        Text("Información de la etiqueta:")
                            .font(.headline)

                        Text(nfcReader.tagInfo)
                            .font(.body)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    .padding()
                }
                .frame(maxHeight: 300)
            }

            Spacer()

            Button(action: {
                nfcReader.scan()
            }) {
                HStack {
                    Image(systemName: "wave.3.right")
                    Text("Escanear Etiqueta NFC")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            }
            .padding(.bottom, 30)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
