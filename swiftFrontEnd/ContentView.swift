//
//  ContentView.swift
//  swiftFrontEnd
//
//  Created by Ryan Dickerson on 9/17/24.
//

import SwiftUI
import AVKit

struct ContentView: View {
    @State private var showVideoPicker = false
    @State private var videoURL: URL?

    var body: some View {
        VStack {
            if let videoURL = videoURL {
                VideoPlayer(player: AVPlayer(url: videoURL))
                    .frame(height: 300)
            } else {
                Image(systemName: "video")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .foregroundStyle(.tint)
            }

            Button(action: {
                showVideoPicker = true
            }) {
                Text("Record Video")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            .sheet(isPresented: $showVideoPicker) {
                VideoPicker(videoURL: $videoURL)
            }
        }
    }
}

#Preview {
    ContentView()
}
