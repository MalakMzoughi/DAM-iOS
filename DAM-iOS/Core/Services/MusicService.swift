//
//  MusicService.swift
//  DAM-iOS
//
//  Backend API service for note validation and music recognition
//

import Foundation
import AVFoundation

struct ValidateNoteRequest: Codable {
    let frequency: Double
    let expectedNote: String
}

struct ValidateNoteResponse: Codable {
    let isCorrect: Bool
    let detectedNote: String
    let expectedNote: String
    let frequency: Double
    let centsOff: Int?
    let message: String?
}

class MusicService {
    
    static let shared = MusicService()
    private init() {}
    
    private let baseURL = "http://192.168.100.52:3000"
    
    /// Validate note using backend API
    func validateNote(frequency: Double, expectedNote: String) async throws -> ValidateNoteResponse {
        guard let url = URL(string: "\(baseURL)/music/validate-note") else {
            throw NSError(domain: "Invalid URL", code: 0)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ValidateNoteRequest(frequency: frequency, expectedNote: expectedNote)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw NSError(domain: "Invalid response", code: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        let result = try JSONDecoder().decode(ValidateNoteResponse.self, from: data)
        return result
    }
    
    // MARK: - Music Recognition (ACRCloud)
    
    /// Recognize song from audio file using ACRCloud backend
    func recognizeSong(audioFileURL: URL) async throws -> MusicRecognitionResponse {
        guard let url = URL(string: "\(baseURL)/music/recognize") else {
            throw NSError(domain: "MusicService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL configuration"])
        }
        
        print("🎵 Starting song recognition...")
        print("📁 Audio file: \(audioFileURL.lastPathComponent)")
        print("📂 Full path: \(audioFileURL.path)")
        
        // Verify file exists and has data
        guard FileManager.default.fileExists(atPath: audioFileURL.path) else {
            throw NSError(domain: "MusicService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Audio file not found"])
        }
        
        // Read audio file data
        let audioData = try Data(contentsOf: audioFileURL)
        print("📦 Audio data size: \(audioData.count) bytes (\(Double(audioData.count) / 1024.0 / 1024.0) MB)")
        
        guard audioData.count > 100 else {
            throw NSError(domain: "MusicService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Audio file is too small (\(audioData.count) bytes). Please record again."])
        }
        
        // Get file attributes for additional debugging
        if let attributes = try? FileManager.default.attributesOfItem(atPath: audioFileURL.path) {
            print("📊 File size from attributes: \(attributes[.size] ?? 0) bytes")
        }
        
        // Create multipart form data
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30 // 30 second timeout
        
        // Build multipart body
        var body = Data()
        
        // Add audio file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"\(audioFileURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
        
        // Determine content type based on file extension
        let contentType: String
        if audioFileURL.pathExtension.lowercased() == "wav" {
            contentType = "audio/wav"
        } else if audioFileURL.pathExtension.lowercased() == "m4a" {
            contentType = "audio/m4a"
        } else {
            contentType = "audio/*"
        }
        
        body.append("Content-Type: \(contentType)\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        // End boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        print("📤 Sending request to \(url.absoluteString)")
        print("📦 Request body size: \(body.count) bytes")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "MusicService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid server response"])
            }
            
            print("📥 Response status: \(httpResponse.statusCode)")
            
            // Always print response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("📥 Response body: \(responseString)")
            }
            
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                do {
                    let result = try JSONDecoder().decode(MusicRecognitionResponse.self, from: data)
                    print("✅ Song recognized: \(result.title) by \(result.artist) (confidence: \(result.confidence)%)")
                    return result
                } catch {
                    print("❌ Failed to decode response: \(error)")
                    print("❌ Raw response data: \(String(data: data, encoding: .utf8) ?? "unable to decode")")
                    throw NSError(domain: "MusicService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse server response: \(error.localizedDescription)"])
                }
            } else if httpResponse.statusCode == 400 {
                // Bad request - likely song not found or audio issue
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ Bad request (400): \(errorMessage)")
                
                // Try to parse backend error message
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = json["message"] as? String {
                    throw NSError(domain: "MusicService", code: 400, userInfo: [NSLocalizedDescriptionKey: message])
                }
                
                throw NSError(domain: "MusicService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Song not recognized. Try recording for longer (10-15 seconds) with clear audio."])
            } else if httpResponse.statusCode == 404 {
                throw NSError(domain: "MusicService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Song not found. Try recording for at least 10 seconds with clear audio."])
            } else if httpResponse.statusCode >= 500 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Server error"
                print("❌ Server error (\(httpResponse.statusCode)): \(errorMessage)")
                throw NSError(domain: "MusicService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error. Please try again later."])
            } else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ Recognition failed (\(httpResponse.statusCode)): \(errorMessage)")
                throw NSError(domain: "MusicService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Recognition failed: \(errorMessage)"])
            }
        } catch let error as NSError where error.domain == NSURLErrorDomain {
            print("❌ Network error: \(error)")
            if error.code == NSURLErrorTimedOut {
                throw NSError(domain: "MusicService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Request timed out. Check your internet connection."])
            } else if error.code == NSURLErrorCannotConnectToHost {
                throw NSError(domain: "MusicService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Cannot connect to server. Please check your connection."])
            } else {
                throw NSError(domain: "MusicService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Network error: \(error.localizedDescription)"])
            }
        }
    }
}
