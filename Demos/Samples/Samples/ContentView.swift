//
//  ContentView.swift
//  Samples
//
//  Created by Douglas McNamara on 8/22/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            GameControl()
                .navigationTitle("Samples - down arrow (next sample), space (run sample), esc (quit sample)")
        }
    }
}
