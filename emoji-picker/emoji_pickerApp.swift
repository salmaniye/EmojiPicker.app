//
//  emoji_pickerApp.swift
//  emoji-picker
//
//  Created by Salman Fatahillah on 05/06/2025.
//

import SwiftUI

@main
struct emoji_pickerApp: App {
    @NSApplicationDelegateAdaptor(SimpleAppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
