//
//  PitchDetector.swift
//  DAM-iOS
//
//  Native pitch detection using AVAudioEngine and autocorrelation
//  Similar to Android's AudioRecord implementation
//

import Foundation
import AVFoundation
import Accelerate
import QuartzCore

struct PitchDetectionEvent: Identifiable, Equatable {
    let id = UUID()
    let note: String
    let frequency: Float
}

@MainActor
class PitchDetector: ObservableObject {
    
    // MARK: - Published Properties
    @Published var detectedNote: String = ""
    @Published var detectedFrequency: Float = 0.0
    @Published var detectionEvent: PitchDetectionEvent?
    @Published var isListening: Bool = false
    
    // MARK: - Audio Engine (matching Android settings)
    private var audioEngine: AVAudioEngine?
    private var sampleRate: Double = 22050.0
    private let bufferSize: AVAudioFrameCount = 4096
    
    // MARK: - Confirmation logic (mirrors Android)
    private var pendingNote: String?
    private var pendingNoteCount: Int = 0
    private var pendingFrequencySum: Float = 0
    private var pendingFrequencyCount: Int = 0
    private let requiredConfirmations = 2
    private var lastConfirmedNote: String?
    private var lastConfirmationTime: CFTimeInterval = 0
    private let repeatedNoteCooldown: CFTimeInterval = 0.5
    private let postMatchCooldown: CFTimeInterval = 0.8
    private var ignoreDetectionsUntil: CFTimeInterval = 0
    private var listeningStartTime: CFTimeInterval = 0
    
    // MARK: - Note Frequency Mapping (matching Android - 5% tolerance like Android)
    private let noteFrequencies: [(note: String, targetFreq: Float)] = {
        // Build octave-invariant lookup so any register maps to same note label
        let baseNotes: [(String, Float)] = [
            ("do", 261.63),
            ("re", 293.66),
            ("mi", 329.63),
            ("fa", 349.23),
            ("sol", 392.00),
            ("la", 440.00),
            ("si", 493.88)
        ]
        var table: [(String, Float)] = []
        let octaveMultipliers: [Float] = [0.5, 1.0, 2.0] // C3–C5 range
        for multiplier in octaveMultipliers {
            for (note, freq) in baseNotes {
                table.append((note, freq * multiplier))
            }
        }
        return table
    }()
    
    // MARK: - Initialization
    init() {
        setupAudioSession()
    }
    
    deinit {
        Task { @MainActor [weak self] in
            self?.stopListening()
        }
    }
    
    // MARK: - Setup Audio Session
    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            // Use .playAndRecord to allow microphone input AND sound playback simultaneously
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
            print("✅ PitchDetector: Audio session configured for playAndRecord")
        } catch {
            print("❌ PitchDetector: Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Start Listening
    func startListening() {
        guard !isListening else { return }
        
        audioEngine = AVAudioEngine()
        guard let engine = audioEngine else { return }
        
        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        sampleRate = Double(inputFormat.sampleRate)
        
        // Install tap to capture audio with weak self to prevent retain cycle
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: inputFormat) { [weak self] buffer, _ in
            guard let self = self else { return }
            self.processAudioBuffer(buffer)
        }
        
        do {
            resetDetectionState(resetStartTime: false)
            try engine.start()
            listeningStartTime = CACurrentMediaTime()
            Task { @MainActor [weak self] in
                self?.isListening = true
                print("🎤 PitchDetector: Started listening")
            }
        } catch {
            print("❌ PitchDetector: Failed to start audio engine: \(error)")
        }
    }
    
    // MARK: - Stop Listening
    func stopListening() {
        guard let engine = audioEngine, isListening else { return }
        
        // CRITICAL: Remove tap BEFORE stopping to prevent retain cycle
        let inputNode = engine.inputNode
        if inputNode.numberOfInputs > 0 {
            inputNode.removeTap(onBus: 0)
        }
        
        engine.stop()
        audioEngine = nil
        
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        } catch {
            print("⚠️ PitchDetector: Failed to deactivate audio session: \(error)")
        }
        
        resetDetectionState()
        Task { @MainActor [weak self] in
            self?.isListening = false
            print("🛑 PitchDetector: Stopped listening")
        }
    }
    
    // MARK: - Process Audio Buffer (local detection)
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        
        let frameLength = Int(buffer.frameLength)
        var samples = Array(UnsafeBufferPointer(start: channelData[0], count: frameLength))

        // Remove DC offset to keep correlation from latching on ambient hum
        if frameLength > 0 {
            let mean = samples.reduce(0, +) / Float(frameLength)
            if abs(mean) > 0.0001 {
                for idx in 0..<frameLength {
                    samples[idx] -= mean
                }
            }
        }
        
        // Detect frequency using autocorrelation
        if let frequency = detectFrequency(samples: samples) {
            handlePotentialNote(frequency: frequency)
        } else {
            resetPendingNote()
        }
    }

    private func handlePotentialNote(frequency: Float) {
        // Ignore first 500ms so audio stabilizes like Android implementation
        let now = CACurrentMediaTime()
        if listeningStartTime > 0 && (now - listeningStartTime) < 0.5 {
            return
        }
        if now < ignoreDetectionsUntil {
            return
        }
        
        guard let candidateNote = frequencyToNote(frequency: frequency) else {
            resetPendingNote()
            return
        }
        
        if pendingNote == candidateNote {
            pendingNoteCount += 1
            pendingFrequencySum += frequency
            pendingFrequencyCount += 1
        } else {
            pendingNote = candidateNote
            pendingNoteCount = 1
            pendingFrequencySum = frequency
            pendingFrequencyCount = 1
        }
        
        guard pendingNoteCount >= requiredConfirmations else { return }
        
        let canRepeat = candidateNote != lastConfirmedNote || (now - lastConfirmationTime) > repeatedNoteCooldown
        if canRepeat {
            let averagedFrequency = pendingFrequencyCount > 0 ? (pendingFrequencySum / Float(pendingFrequencyCount)) : frequency
            publishDetection(note: candidateNote, frequency: averagedFrequency)
            lastConfirmedNote = candidateNote
            lastConfirmationTime = now
            ignoreDetectionsUntil = now + postMatchCooldown
        }
        
        resetPendingNote()
    }
    
    private func publishDetection(note: String, frequency: Float) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.detectedFrequency = frequency
            self.detectedNote = note
            self.detectionEvent = PitchDetectionEvent(note: note, frequency: frequency)
            print("✅ Confirmed note: \(note.uppercased()) @ \(String(format: "%.1f", frequency)) Hz")
        }
    }
    
    private func resetPendingNote() {
        pendingNote = nil
        pendingNoteCount = 0
        pendingFrequencySum = 0
        pendingFrequencyCount = 0
    }
    
    // MARK: - Autocorrelation Algorithm (matching Android approach)
    private func detectFrequency(samples: [Float]) -> Float? {
        let sampleCount = samples.count
        guard sampleCount > 0 else { return nil }
        
        // Calculate RMS (lower threshold for better sensitivity)
        let rms = sqrt(samples.map { $0 * $0 }.reduce(0, +) / Float(sampleCount))
        
        if rms > 0.002 {
            print("🔊 RMS: \(String(format: "%.4f", rms))")
        }
        
        guard rms > 0.005 else { return nil }
        
        // Autocorrelation - simplified approach for better reliability
        let halfSize = sampleCount / 2
        let minLag = max(4, Int(sampleRate / 1000.0))  // allow up to ~1000 Hz but ignore aliasing
        let maxLag = Int(sampleRate / 140.0)  // down to ~140 Hz fundamentals
        let lagUpperBound = min(maxLag, halfSize - 2)

        guard lagUpperBound > minLag else { return nil }

        var bestLag: Int = 0
        var bestCorrelation: Float = -Float.infinity
        var bestScore: Float = -Float.infinity
        var correlations = Array(repeating: Float.zero, count: lagUpperBound + 2)
        let lagSpan = max(lagUpperBound - minLag, 1)

        // Search for the lag with maximum normalized correlation, biasing slightly toward larger lags (fundamentals)
        for lag in minLag...lagUpperBound {
            var crossSum: Float = 0
            var sumSquaresA: Float = 0
            var sumSquaresB: Float = 0
            let correlationSize = min(halfSize, sampleCount - lag)

            for i in 0..<correlationSize {
                let sampleA = samples[i]
                let sampleB = samples[i + lag]
                crossSum += sampleA * sampleB
                sumSquaresA += sampleA * sampleA
                sumSquaresB += sampleB * sampleB
            }

            let denominator = sqrtf(sumSquaresA * sumSquaresB)
            let normalizedCorrelation = denominator > 0 ? (crossSum / denominator) : 0
            correlations[lag] = normalizedCorrelation

            let lagBias = 0.65 + 0.35 * (Float(lag - minLag) / Float(lagSpan))
            let score = normalizedCorrelation * lagBias

            if score > bestScore {
                bestScore = score
                bestCorrelation = normalizedCorrelation
                bestLag = lag
            }
        }

        print("🔍 Max correlation: \(bestCorrelation), Best lag: \(bestLag)")

        guard bestLag > 0 else {
            print("⚠️ No valid lag found")
            return nil
        }

        // Prefer the fundamental (larger lag) instead of latching onto high harmonics
        var selectedLag = bestLag
        let peakThreshold = max(bestCorrelation * 0.7, 0.35)

        if bestLag < lagUpperBound {
            for lag in bestLag...lagUpperBound {
                let value = correlations[lag]
                let prev = lag > minLag ? correlations[lag - 1] : value
                let next = lag + 1 <= lagUpperBound ? correlations[lag + 1] : value

                if value >= peakThreshold && value >= prev && value >= next {
                    selectedLag = lag
                }
            }
        }

        // If we still landed on a high harmonic (>500 Hz), walk down its multiples to retrieve the fundamental.
        let maxPlayableFrequency: Float = 520
        var fundamentalLag = selectedLag
        var fundamentalCorrelation = correlations[selectedLag]

        var harmonicFrequency = Float(sampleRate) / Float(selectedLag)
        if harmonicFrequency > maxPlayableFrequency {
            for multiple in 2...4 {
                let candidateLag = selectedLag * multiple
                guard candidateLag <= lagUpperBound else { break }

                let candidateCorrelation = correlations[candidateLag]
                if candidateCorrelation >= fundamentalCorrelation * 0.55 {
                    fundamentalLag = candidateLag
                    fundamentalCorrelation = candidateCorrelation
                    harmonicFrequency = Float(sampleRate) / Float(candidateLag)
                }
            }
        }

        // Parabolic interpolation for finer precision
        var lagForFrequency = Float(fundamentalLag)
        if fundamentalLag > minLag && fundamentalLag + 1 <= lagUpperBound {
            let c0 = correlations[fundamentalLag - 1]
            let c1 = correlations[fundamentalLag]
            let c2 = correlations[fundamentalLag + 1]
            let denominator = (c0 - 2 * c1 + c2)
            if abs(denominator) > Float.leastNonzeroMagnitude {
                let delta = 0.5 * (c0 - c2) / denominator
                lagForFrequency = Float(fundamentalLag) + delta
            }
        }

        let frequency = Float(sampleRate) / lagForFrequency

        print("🎯 Raw frequency detected: \(String(format: "%.1f", frequency)) Hz (lag: \(lagForFrequency))")
        
        // Filter to expanded piano range (C3–C5)
        guard frequency >= 150 && frequency <= 800 else {
            print("⚠️ Frequency \(String(format: "%.1f", frequency)) Hz out of range")
            return nil
        }
        
        return frequency
    }
    
    // MARK: - Frequency to Note Mapping (matching Android - 5% tolerance)
    private func frequencyToNote(frequency: Float) -> String? {
        guard frequency >= 150 && frequency <= 800 else { return nil }
        
        var closestNote: String?
        var minDistance: Float = Float.infinity
        
        for (note, targetFreq) in noteFrequencies {
            let distance = abs(frequency - targetFreq)
            let tolerance = max(targetFreq * 0.07, 8)  // 7% tolerance with floor
            
            if distance < minDistance && distance <= tolerance {
                minDistance = distance
                closestNote = note
            }
        }
        
        return closestNote
    }
    
    // MARK: - Request Microphone Permission
    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    private func resetDetectionState(resetStartTime: Bool = true) {
        resetPendingNote()
        lastConfirmedNote = nil
        lastConfirmationTime = 0
        ignoreDetectionsUntil = 0
        if resetStartTime {
            listeningStartTime = 0
        }
        Task { @MainActor in
            self.detectionEvent = nil
            self.detectedNote = ""
            self.detectedFrequency = 0.0
        }
    }
}
