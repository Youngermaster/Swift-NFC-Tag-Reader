import SwiftUI

struct Home: View {
  // Utilizamos el ViewModel para gestionar el estado y la lógica
  @State private var message: String = "Listo para escanear"
  @State private var tagUID: String = ""
  @State private var tagContent: String = ""
  @State private var isScanning: Bool = false

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
            .fill(Color.gray.opacity(0.2))
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
          .opacity(tagUID.isEmpty && tagContent.isEmpty ? 0 : 1)
      )
      .padding(.horizontal)
      .opacity(tagUID.isEmpty && tagContent.isEmpty ? 0 : 1)

      Spacer()

      // Botón para iniciar o detener el escaneo
      Button(action: {
        // En una implementación real, aquí llamaríamos al servicio NFC
        isScanning.toggle()
        message = isScanning ? "Acerca tu dispositivo a una etiqueta NFC" : "Escaneo detenido"

        // Simulación para demostración
        if isScanning {
          DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if self.isScanning {
              self.isScanning = false
              self.tagUID = "04:A2:E2:49:93:12:02"
              self.tagContent = "https://example.com\nHola desde NFC"
              self.message = "Etiqueta simulada leída"
            }
          }
        }
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
