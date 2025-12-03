//
//  MusicRecognitionViewModel.swift
//  DAM-iOS
//
//  ViewModel for Music Recognition with audio recording
//

import Foundation
import AVFoundation
import Combine

@MainActor
class MusicRecognitionViewModel: ObservableObject {
    
    @Published var isRecording = false
    @Published var isRecognizing = false
    @Published var recognitionResult: MusicRecognitionResponse?
    @Published var error: String?
    
    private let musicService = MusicService.shared
    private var audioRecorder: AVAudioRecorder?
    private var audioFileURL: URL?
    
    // MARK: - Audio Recording
    
    func startRecording() {
        Task {
            do {
                // Request microphone permission
                let permission = await AVAudioSession.sharedInstance().requestRecordPermission()
                
                guard permission else {
                    error = "Microphone permission denied"
                    return
                }
                
                // Configure audio session
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.record, mode: .default)
                try audioSession.setActive(true)
                
                // Create temporary file for recording
                let tempDir = FileManager.default.temporaryDirectory
                audioFileURL = tempDir.appendingPathComponent("audio_recording_\(UUID().uuidString).m4a")
                
                guard let url = audioFileURL else {
                    error = "Failed to create audio file"
                    return
                }
                
                // Configure recorder settings
                let settings: [String: Any] = [
                    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                    AVSampleRateKey: 44100.0,
                    AVNumberOfChannelsKey: 1,
                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                ]
                
                // Create and start recorder
                audioRecorder = try AVAudioRecorder(url: url, settings: settings)
                audioRecorder?.prepareToRecord()
                audioRecorder?.record()
                
                isRecording = true
                error = nil
                recognitionResult = nil
                
                print("🎤 Recording started")
                
            } catch {
                self.error = "Failed to start recording: \(error.localizedDescription)"
                print("❌ Recording error: \(error)")
            }
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        
        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false)
        
        print("🛑 Recording stopped")
    }
    
    func stopRecordingAndRecognize() {
        stopRecording()
        
        guard let fileURL = audioFileURL else {
            error = "No audio file to process"
            return
        }
        
        recognizeSong(fileURL: fileURL)
    }
    
    // MARK: - Song Recognition
    
    private func recognizeSong(fileURL: URL) {
        Task {
            isRecognizing = true
            error = nil
            
            do {
                let result = try await musicService.recognizeSong(audioFileURL: fileURL)
                recognitionResult = result
                print("✅ Song recognized: \(result.title) by \(result.artist)")
            } catch {
                self.error = error.localizedDescription
                print("❌ Recognition failed: \(error)")
            }
            
            isRecognizing = false
            
            // Clean up temp file
            try? FileManager.default.removeItem(at: fileURL)
            audioFileURL = nil
        }
    }
    
    // MARK: - Helper Methods
    
    func clearResult() {
        recognitionResult = nil
        error = nil
    }
    
    func clearError() {
        error = nil
    }
    
    deinit {
        // Clean up
        stopRecording()
        if let url = audioFileURL {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
