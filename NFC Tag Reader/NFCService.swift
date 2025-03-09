import CoreNFC
import Foundation

// Clase para gestionar las operaciones de NFC
class NFCService: NSObject, ObservableObject, NFCNDEFReaderSessionDelegate {

  // Esta variable publicada permitirá actualizar la UI cuando se lea una etiqueta
  @Published var message: String = "Escanea una etiqueta NFC"
  @Published var tagUID: String = ""
  @Published var tagContent: String = ""
  @Published var isScanning: Bool = false

  // Sesión de lectura NFC
  private var nfcSession: NFCNDEFReaderSession?

  // Función para iniciar el escaneo de etiquetas NFC
  func scanTag() {
    guard NFCNDEFReaderSession.readingAvailable else {
      self.message = "Este dispositivo no soporta la lectura de etiquetas NFC"
      return
    }

    self.isScanning = true
    self.message = "Acerca tu dispositivo a una etiqueta NFC"

    // Inicializar sesión NFC
    nfcSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
    nfcSession?.alertMessage = "Acerca tu iPhone a una etiqueta NFC"
    nfcSession?.begin()
  }

  // Detener el escaneo de NFC
  func stopScan() {
    nfcSession?.invalidate()
    self.isScanning = false
  }

  // MARK: - NFCNDEFReaderSessionDelegate Methods

  // Se llama cuando se produce un error
  func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
    DispatchQueue.main.async {
      self.isScanning = false
      self.message = "Error de lectura: \(error.localizedDescription)"
    }
  }

  // Se llama cuando se detecta una etiqueta NDEF
  func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
    // Procesar mensajes NDEF
    var resultText = ""

    for message in messages {
      for record in message.records {
        if let recordText = String(data: record.payload, encoding: .utf8) {
          resultText += recordText + "\n"
        }
      }
    }

    DispatchQueue.main.async {
      self.tagContent = resultText.isEmpty ? "No hay contenido legible" : resultText
      self.message = "Etiqueta leída correctamente"
      self.isScanning = false
    }
  }

  // Se llama cuando se detecta una etiqueta
  func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
    // Conectar con la primera etiqueta encontrada
    if let tag = tags.first {
      session.connect(to: tag) { error in
        if let error = error {
          session.invalidate(errorMessage: "Error de conexión: \(error.localizedDescription)")
          return
        }

        // Usar el adaptador para obtener el ID de la etiqueta
        let tagAdapter = NFCTagAdapter(tag: tag)
        let uid = tagAdapter.identifier.map { String(format: "%02X", $0) }.joined()
        DispatchQueue.main.async {
          self.tagUID = uid
        }

        // Leer el contenido NDEF de la etiqueta
        tag.queryNDEFStatus { status, capacity, error in
          if let error = error {
            session.invalidate(errorMessage: "Error al leer NDEF: \(error.localizedDescription)")
            return
          }

          switch status {
          case .notSupported:
            session.invalidate(errorMessage: "Etiqueta no compatible con NDEF")
          case .readOnly, .readWrite:
            tag.readNDEF { message, error in
              if let error = error {
                session.invalidate(
                  errorMessage: "Error al leer NDEF: \(error.localizedDescription)")
                return
              }
              if let message = message {
                // Procesar el mensaje
                self.readerSession(session, didDetectNDEFs: [message])
                session.alertMessage = "Etiqueta leída correctamente"
                // Mantenemos la sesión activa para hacer más lecturas
              } else {
                session.invalidate(errorMessage: "No se encontró contenido NDEF")
              }
            }
          @unknown default:
            session.invalidate(errorMessage: "Estado NDEF desconocido")
          }
        }
      }
    } else {
      session.invalidate(errorMessage: "No se encontró una etiqueta compatible")
    }
  }
}

// Extensión para NFCTag para obtener el identificador
protocol NFCTagType {
  var identifier: Data { get }
}

// En lugar de extender el protocolo, creamos una clase adaptadora
class NFCTagAdapter: NFCTagType {
  private let tag: NFCNDEFTag

  init(tag: NFCNDEFTag) {
    self.tag = tag
  }

  var identifier: Data {
    // Intentamos obtener el identificador real del tag
    // Esta implementación funcionará mejor en un dispositivo real
    if let iso7816Tag = tag as? NFCISO7816Tag {
      return iso7816Tag.identifier
    } else if let iso15693Tag = tag as? NFCISO15693Tag {
      return iso15693Tag.identifier
    } else if let miFareTag = tag as? NFCMiFareTag {
      return miFareTag.identifier
    } else if let feliCaTag = tag as? NFCFeliCaTag {
      return feliCaTag.currentIDm
    }

    // Si no podemos determinar el tipo específico, devolvemos un ID genérico o vacío
    return Data([0x00, 0x00, 0x00, 0x00])
  }
}

// Función auxiliar para obtener un adaptador para cualquier tag
func getTagAdapter(for tag: NFCNDEFTag) -> NFCTagType {
  return NFCTagAdapter(tag: tag)
}
