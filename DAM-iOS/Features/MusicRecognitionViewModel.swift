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
    @Published var recordingDuration: TimeInterval = 0
    
    private let musicService = MusicService.shared
    private var audioRecorder: AVAudioRecorder?
    private var audioFileURL: URL?
    private var recordingStartTime: Date?
    private var recordingTimer: Timer?
    
    private let minimumRecordingDuration: TimeInterval = 10.0 // 10 seconds minimum for better recognition
    
    // MARK: - Audio Recording
    
    func startRecording() {
        Task {
            do {
                // Request microphone permission
                let permission = await withCheckedContinuation { continuation in
                    AVAudioSession.sharedInstance().requestRecordPermission { granted in
                        continuation.resume(returning: granted)
                    }
                }
                
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
                audioFileURL = tempDir.appendingPathComponent("audio_recording_\(UUID().uuidString).wav")
                
                guard let url = audioFileURL else {
                    error = "Failed to create audio file"
                    return
                }
                
                // Configure recorder settings - using Linear PCM (WAV) for better compatibility
                let settings: [String: Any] = [
                    AVFormatIDKey: Int(kAudioFormatLinearPCM),
                    AVSampleRateKey: 44100.0,
                    AVNumberOfChannelsKey: 1,
                    AVLinearPCMBitDepthKey: 16,
                    AVLinearPCMIsBigEndianKey: false,
                    AVLinearPCMIsFloatKey: false,
                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                ]
                
                // Create and start recorder
                audioRecorder = try AVAudioRecorder(url: url, settings: settings)
                audioRecorder?.prepareToRecord()
                audioRecorder?.record()
                
                isRecording = true
                error = nil
                recognitionResult = nil
                recordingStartTime = Date()
                recordingDuration = 0
                
                // Start timer to update recording duration
                recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                    guard let self = self, let startTime = self.recordingStartTime else { return }
                    Task { @MainActor in
                        self.recordingDuration = Date().timeIntervalSince(startTime)
                    }
                }
                
                print("🎤 Recording started")
                
            } catch {
                self.error = "Failed to start recording: \(error.localizedDescription)"
                print("❌ Recording error: \(error)")
            }
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        recordingTimer?.invalidate()
        recordingTimer = nil
        recordingStartTime = nil
        
        // Properly stop and finalize the recording
        audioRecorder?.stop()
        
        // Give the recorder a moment to finalize the file
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            await MainActor.run {
                audioRecorder = nil
                isRecording = false
                
                // Verify file was created successfully
                if let url = audioFileURL, FileManager.default.fileExists(atPath: url.path) {
                    if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                       let fileSize = attributes[.size] as? Int64 {
                        print("🛑 Recording stopped successfully")
                        print("📊 Final file size: \(fileSize) bytes (\(Double(fileSize) / 1024.0 / 1024.0) MB)")
                        print("⏱️ Recording duration: \(String(format: "%.1f", recordingDuration))s")
                    }
                } else {
                    print("⚠️ Warning: Audio file not found after recording")
                }
                
                // Deactivate audio session
                try? AVAudioSession.sharedInstance().setActive(false)
            }
        }
    }
    
    func stopRecordingAndRecognize() {
        let duration = recordingDuration
        stopRecording()
        
        // Check minimum duration
        if duration < minimumRecordingDuration {
            error = "Recording too short. Please record for at least \(Int(minimumRecordingDuration)) seconds."
            return
        }
        
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
                print("❌ Error details: \(error)")
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
        // Clean up audio file
        // Note: We can't call stopRecording() here since deinit is nonisolated
        // and stopRecording() is @MainActor isolated. The audio recorder will
        // be cleaned up automatically when the view model is deallocated.
        if let url = audioFileURL {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
