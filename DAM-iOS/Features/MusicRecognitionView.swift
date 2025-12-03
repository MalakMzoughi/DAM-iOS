//
//  MusicRecognitionView.swift
//  DAM-iOS
//
//  Music recognition screen with recording and results
//

import SwiftUI

struct MusicRecognitionView: View {
    @StateObject private var viewModel = MusicRecognitionViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.3),
                    Color.blue.opacity(0.2),
                    Color.white
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        viewModel.stopRecording()
                        dismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.blue)
                            .frame(width: 48, height: 48)
                            .background(Color.white.opacity(0.9))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("🎵 Song Recognition")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.purple)
                    
                    Spacer()
                    
                    // Invisible spacer for alignment
                    Color.clear.frame(width: 48, height: 48)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 32)
                
                // Main Content Card
                VStack {
                    Spacer()
                    
                    if let result = viewModel.recognitionResult {
                        RecognitionResultView(result: result) {
                            viewModel.clearResult()
                        }
                    } else if let error = viewModel.error {
                        ErrorView(error: error) {
                            viewModel.clearError()
                        }
                    } else if viewModel.isRecording {
                        RecordingView(viewModel: viewModel) {
                            viewModel.stopRecordingAndRecognize()
                        }
                    } else if viewModel.isRecognizing {
                        RecognizingView()
                    } else {
                        StartRecordingView {
                            viewModel.startRecording()
                        }
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white.opacity(0.95))
                .cornerRadius(24)
                .shadow(color: .black.opacity(0.1), radius: 8)
                .padding(.horizontal, 16)
                
                // Instructions
                if viewModel.recognitionResult == nil && viewModel.error == nil && !viewModel.isRecording && !viewModel.isRecognizing {
                    InstructionCard()
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                }
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Start Recording View
struct StartRecordingView: View {
    let onStart: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Text("🎸")
                .font(.system(size: 80))
            
            Text("Ready to Recognize")
                .font(.system(size: 28, weight: .bold))
            
            Text("Play a song or hum a melody")
                .font(.system(size: 18))
                .foregroundColor(.gray)
            
            Spacer().frame(height: 24)
            
            Button(action: onStart) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.white)
                    .frame(width: 120, height: 120)
                    .background(Color.red)
                    .clipShape(Circle())
                    .shadow(color: .red.opacity(0.3), radius: 8)
            }
            
            Text("Tap to Start")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.red)
        }
        .padding()
    }
}

// MARK: - Recording View
struct RecordingView: View {
    @ObservedObject var viewModel: MusicRecognitionViewModel
    let onStop: () -> Void
    
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 32) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.red.opacity(0.8), Color.orange.opacity(0.6)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(scale)
                    .onAppear {
                        withAnimation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                        ) {
                            scale = 1.2
                        }
                    }
                
                Image(systemName: "mic.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                Text("🔴 Recording...")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.red)
                
                Text(formatDuration(viewModel.recordingDuration))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.gray)
                    .monospacedDigit()
            }
            
            Text(viewModel.recordingDuration < 10.0 ? "Keep recording (minimum 10 seconds)" : "Listening to the music")
                .font(.system(size: 18))
                .foregroundColor(viewModel.recordingDuration < 10.0 ? .orange : .gray)
            
            Spacer().frame(height: 24)
            
            Button(action: onStop) {
                HStack {
                    Image(systemName: "stop.fill")
                    Text("Stop & Recognize")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(width: 200, height: 56)
                .background(viewModel.recordingDuration >= 10.0 ? Color.blue : Color.gray)
                .cornerRadius(28)
            }
            .disabled(viewModel.recordingDuration < 10.0)
        }
        .padding()
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let milliseconds = Int((duration.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%01d", minutes, seconds, milliseconds)
    }
}

// MARK: - Recognizing View
struct RecognizingView: View {
    var body: some View {
        VStack(spacing: 32) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                .scaleEffect(3)
            
            Text("🔍 Recognizing...")
                .font(.system(size: 28, weight: .bold))
            
            Text("Finding your song")
                .font(.system(size: 18))
                .foregroundColor(.gray)
        }
        .padding()
    }
}

// MARK: - Recognition Result View
struct RecognitionResultView: View {
    let result: MusicRecognitionResponse
    let onTryAgain: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Text("✨")
                .font(.system(size: 80))
            
            Text("Song Found!")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.green)
            
            Spacer().frame(height: 16)
            
            // Song details card
            VStack(spacing: 12) {
                ResultRow(label: "🎵 Title", value: result.title)
                Divider()
                ResultRow(label: "👤 Artist", value: result.artist)
                Divider()
                ResultRow(label: "💿 Album", value: result.album)
                Divider()
                ResultRow(label: "🎯 Confidence", value: "\(Int(result.confidence))%")
            }
            .padding(20)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(16)
            
            Spacer().frame(height: 16)
            
            Button(action: onTryAgain) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Another Song")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.purple)
                .cornerRadius(28)
            }
        }
        .padding()
    }
}

struct ResultRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Error View
struct ErrorView: View {
    let error: String
    let onTryAgain: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Text("😕")
                .font(.system(size: 80))
            
            Text("Oops!")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.orange)
            
            Text(error)
                .font(.system(size: 18))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
            
            Spacer().frame(height: 16)
            
            Button(action: onTryAgain) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.blue)
                .cornerRadius(28)
            }
        }
        .padding()
    }
}

// MARK: - Instruction Card
struct InstructionCard: View {
    var body: some View {
        HStack {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(.orange)
            
            Text("Play a song for at least 10 seconds for best results")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: 0x333333))
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.yellow.opacity(0.2) as Color)
        .cornerRadius(16)
    }
}
