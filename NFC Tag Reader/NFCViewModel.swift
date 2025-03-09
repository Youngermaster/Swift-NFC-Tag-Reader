import Combine
import SwiftUI

// ViewModel para conectar la UI con el servicio NFC
class NFCViewModel: ObservableObject {
  // Propiedades publicadas que actualizarán la UI
  @Published var message: String = "Listo para escanear"
  @Published var tagUID: String = ""
  @Published var tagContent: String = ""
  @Published var isScanning: Bool = false

  // Referencia al servicio NFC
  private var nfcService: NFCService?
  private var cancellables = Set<AnyCancellable>()

  init() {
    #if !targetEnvironment(simulator)
      // Solo inicializamos el servicio NFC en dispositivos reales
      setupNFCService()
    #endif
  }

  private func setupNFCService() {
    // Esto se encapsulará en un bloque try-catch cuando se implemente realmente
    do {
      nfcService = NFCService()

      // Suscripciones para actualizar el ViewModel cuando cambie el servicio
      nfcService?.$message
        .receive(on: RunLoop.main)
        .sink { [weak self] newValue in
          self?.message = newValue
        }
        .store(in: &cancellables)

      nfcService?.$tagUID
        .receive(on: RunLoop.main)
        .sink { [weak self] newValue in
          self?.tagUID = newValue
        }
        .store(in: &cancellables)

      nfcService?.$tagContent
        .receive(on: RunLoop.main)
        .sink { [weak self] newValue in
          self?.tagContent = newValue
        }
        .store(in: &cancellables)

      nfcService?.$isScanning
        .receive(on: RunLoop.main)
        .sink { [weak self] newValue in
          self?.isScanning = newValue
        }
        .store(in: &cancellables)
    } catch {
      message = "Error al inicializar el servicio NFC: \(error.localizedDescription)"
    }
  }

  // Métodos que interactúan con el servicio NFC
  func startScan() {
    #if targetEnvironment(simulator)
      // Simulación para el simulador
      isScanning = true
      message = "Simulando escaneo (Simulador)"
      DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
        self?.isScanning = false
        self?.tagUID = "04:A2:E2:49:93:12:02"
        self?.tagContent = "https://example.com\nHola desde NFC"
        self?.message = "Etiqueta simulada leída"
      }
    #else
      nfcService?.scanTag()
    #endif
  }

  func stopScan() {
    #if targetEnvironment(simulator)
      isScanning = false
      message = "Escaneo simulado detenido"
    #else
      nfcService?.stopScan()
    #endif
  }

  // Método conveniente que alterna entre iniciar y detener
  func toggleScan() {
    if isScanning {
      stopScan()
    } else {
      startScan()
    }
  }
}
