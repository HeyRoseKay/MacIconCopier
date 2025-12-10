//
//  􀏃 ContentView.swift
//  MacIconCopier
//
//  Created by Rose Kay on 7/11/25.
//

import SwiftUI

struct ContentView: View {
    let size: CGFloat = 420

    var body: some View {
        VStack {
            DropToCopyIconView()
        }
        .frame(width: size, height: size)
        .navigationTitle("Icon Copier")
    }
}

#Preview {
    ContentView()
}
