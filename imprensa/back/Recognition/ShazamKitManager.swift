import Foundation
import ShazamKit
import AVFoundation

/// Gerenciador que utiliza o framework oficial da Apple (ShazamKit) para identificar músicas.
@MainActor
final class ShazamKitManager: NSObject {
    
    struct RecognitionResult {
        let title: String
        let artist: String
        let artworkURL: URL?
        let appleMusicURL: URL?
    }
    
    enum ShazamError: Error {
        case noMatch
        case invalidAudio
        case recognitionFailed(Error)
    }
    
    private var session: SHSession?
    private var continuation: CheckedContinuation<RecognitionResult, Error>?
    
    override init() {
        super.init()
    }
    
    /// Identifica uma música a partir de um arquivo de áudio local.
    func recognize(audioURL: URL) async throws -> RecognitionResult {
        let session = SHSession()
        self.session = session
        session.delegate = self
        
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            
            do {
                let audioFile = try AVAudioFile(forReading: audioURL)
                print("[ShazamKit] Loaded audio file: \(audioURL.lastPathComponent) duration=\(Double(audioFile.length)/audioFile.fileFormat.sampleRate)s")
                
                let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: AVAudioFrameCount(audioFile.length))!
                try audioFile.read(into: buffer)
                
                let generator = SHSignatureGenerator()
                try generator.append(buffer, at: nil)
                let signature = generator.signature()
                
                print("[ShazamKit] Matching signature...")
                session.match(signature)
            } catch {
                print("[ShazamKit] Failed to prepare recognition: \(error.localizedDescription)")
                continuation.resume(throwing: ShazamError.recognitionFailed(error))
                self.continuation = nil
            }
        }
    }
}

extension ShazamKitManager: SHSessionDelegate {
    func session(_ session: SHSession, didFind match: SHMatch) {
        guard let mediaItem = match.mediaItems.first else {
            continuation?.resume(throwing: ShazamError.noMatch)
            continuation = nil
            return
        }
        
        let result = RecognitionResult(
            title: mediaItem.title ?? "Desconhecido",
            artist: mediaItem.artist ?? "Desconhecido",
            artworkURL: mediaItem.artworkURL,
            appleMusicURL: mediaItem.appleMusicURL
        )
        
        continuation?.resume(returning: result)
        continuation = nil
    }
    
    func session(_ session: SHSession, didNotFindMatchFor signature: SHSignature, error: Error?) {
        if let error = error {
            continuation?.resume(throwing: ShazamError.recognitionFailed(error))
        } else {
            continuation?.resume(throwing: ShazamError.noMatch)
        }
        continuation = nil
    }
}
