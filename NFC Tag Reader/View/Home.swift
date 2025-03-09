import SwiftUI
import UIKit

struct Home: View {
  // Estado local para la UI sin depender directamente de NFCService
  @State private var message: String = "Listo para escanear"
  @State private var tagUID: String = ""
  @State private var tagContent: String = ""
  @State private var isScanning: Bool = false

  // Referencia al servicio NFC que se inicializará desde fuera
  // En la aplicación real, esto se inicializará en la vista ContentView o en un EnvironmentObject

  var body: some View {
    VStack(spacing: 20) {
      // Cabecera
      Text("Lector de Etiquetas NFC")
        .font(.largeTitle)
        .fontWeight(.bold)
        .padding(.top)

      // Estado actual
      Text(message)
        .font(.headline)
        .foregroundColor(isScanning ? .blue : .primary)
        .padding()
        .frame(maxWidth: .infinity)
        .background(
          RoundedRectangle(cornerRadius: 10)
            .fill(Color(UIColor.systemGray6))
        )
        .padding(.horizontal)

      // Animación de escaneo
      ZStack {
        Circle()
          .fill(Color.blue.opacity(0.1))
          .frame(width: 200, height: 200)

        Image(systemName: "radiowaves.left")
          .font(.system(size: 80))
          .foregroundColor(.blue)
          .opacity(isScanning ? 1.0 : 0.5)
          .scaleEffect(isScanning ? 1.2 : 1.0)
          .animation(
            isScanning
              ? Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true) : .default,
            value: isScanning)
      }
      .padding()

      // Información de la etiqueta leída
      VStack(alignment: .leading, spacing: 10) {
        if !tagUID.isEmpty {
          HStack {
            Text("UID:").fontWeight(.bold)
            Text(tagUID)
              .font(.system(.body, design: .monospaced))
          }
          .padding(.horizontal)
        }

        if !tagContent.isEmpty {
          VStack(alignment: .leading) {
            Text("Contenido:").fontWeight(.bold)
            Text(tagContent)
              .font(.system(.body, design: .monospaced))
              .padding(8)
              .background(
                RoundedRectangle(cornerRadius: 8)
                  .fill(Color(UIColor.systemGray5))
              )
          }
          .padding(.horizontal)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 10)
          .fill(Color(UIColor.systemGray6))
          .opacity(tagUID.isEmpty && tagContent.isEmpty ? 0 : 1)
      )
      .padding(.horizontal)
      .opacity(tagUID.isEmpty && tagContent.isEmpty ? 0 : 1)

      Spacer()

      // Botón para iniciar o detener el escaneo
      Button(action: {
        // En la implementación real, aquí llamaríamos a los métodos del servicio NFC
        // Por ahora, solo actualizamos el estado local para la demo
        isScanning.toggle()
        message = isScanning ? "Acerca tu dispositivo a una etiqueta NFC" : "Escaneo detenido"
      }) {
        HStack {
          Image(systemName: isScanning ? "xmark.circle" : "wave.3.right")
          Text(isScanning ? "Detener" : "Escanear Tag NFC")
        }
        .font(.headline)
        .foregroundColor(.white)
        .padding()
        .frame(maxWidth: .infinity)
        .background(
          RoundedRectangle(cornerRadius: 10)
            .fill(isScanning ? Color.red : Color.blue)
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
