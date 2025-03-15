//
//  NFC_Tag_ReaderApp.swift
//  NFC Tag Reader
//
//  Created by Juan Manuel Young Hoyos on 9/03/25.
//

import SwiftUI

#if canImport(CoreNFC)
    import CoreNFC
#endif

@main
struct NFC_Tag_ReaderApp: App {
    var body: some Scene {
        WindowGroup {
            Home()
        }
    }
}
