# NFC Tag Reader para MIFARE

Esta aplicación permite la lectura de etiquetas NFC MIFARE utilizando SwiftUI y CoreNFC.

## Configuración del Proyecto

Para usar esta aplicación, necesitas realizar los siguientes pasos:

1. **Configurar la Capacidad NFC en Xcode**:

   - Abre el proyecto en Xcode
   - Selecciona el target de la aplicación
   - Ve a la pestaña "Signing & Capabilities"
   - Haz clic en "+ Capability" y añade "Near Field Communication Tag Reading"

2. **Asegúrate de tener un perfil de aprovisionamiento válido**:

   - Necesitarás un perfil de aprovisionamiento con la capacidad NFC habilitada
   - Esto requiere una cuenta de Apple Developer pagada

3. **Los archivos de configuración ya incluyen**:
   - `Info.plist` con la clave `NFCReaderUsageDescription`
   - Archivo de entitlements con la clave `com.apple.developer.nfc.readersession.formats` configurada para `TAG`

## Requisitos

- iOS 13.0+
- Un dispositivo físico con capacidad NFC (no funciona en el simulador)

## Uso

1. Ejecuta la aplicación en un dispositivo físico compatible
2. Pulsa el botón "Escanear Etiqueta NFC"
3. Acerca una etiqueta MIFARE al dispositivo
4. La información de la etiqueta se mostrará en la pantalla

## Tipos de Etiquetas Soportadas

- MIFARE (Plus, DESFire, Ultralight)
- ISO-7816
- ISO-15693
- FeliCa
