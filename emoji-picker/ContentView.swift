//
//  ContentView.swift
//  emoji-picker
//
//  Created by Salman Fatahillah on 05/06/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "face.smiling")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Emoji Picker")
                .font(.title)
            Text("This app runs in the menu bar")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 300, height: 200)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
