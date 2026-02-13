import Foundation
import AVFoundation

/// Converte o sample baixado do streaming para um arquivo aceito pela API (prioridade: WAV PCM).
enum AudioNormalizer {
    enum NormalizeError: Error {
        case noAudioTrack
        case exportFailed
    }

    static func normalizeToWavIfPossible(inputURL: URL) async throws -> URL {
        // Tentativa 1: WAV (PCM)
        do {
            return try await transcodeToWav(inputURL: inputURL)
        } catch {
            print("[Recognizer] WAV transcode failed: \(error.localizedDescription). Falling back to M4A(AAC).")
            // Tentativa 2: M4A (AAC) — tenta via ExportSession primeiro (mais tolerante)
            do {
                return try await exportToM4A(inputURL: inputURL)
            } catch {
                print("[Recognizer] M4A export failed: \(error.localizedDescription). Falling back to M4A via reader/writer.")
                return try await transcodeToM4A(inputURL: inputURL)
            }
        }
    }

    // Alguns SDKs não expõem `AVLinearPCMIsNonInterleavedKey` como símbolo Swift,
    // mas o AVFoundation exige essa chave no dicionário de outputSettings.
    private static let linearPCMIsNonInterleavedKey = "AVLinearPCMIsNonInterleaved"

    private static func transcodeToWav(inputURL: URL) async throws -> URL {
        let asset = AVURLAsset(url: inputURL, options: assetOptions(for: inputURL))
        guard let track = asset.tracks(withMediaType: .audio).first else { throw NormalizeError.noAudioTrack }

        let outURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("snippet_\(UUID().uuidString).wav")
        try? FileManager.default.removeItem(at: outURL)

        let reader = try AVAssetReader(asset: asset)
        let readerOutput = AVAssetReaderTrackOutput(
            track: track,
            outputSettings: [
                AVFormatIDKey: kAudioFormatLinearPCM,
                linearPCMIsNonInterleavedKey: false,
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMBitDepthKey: 16
            ]
        )
        readerOutput.alwaysCopiesSampleData = false
        reader.add(readerOutput)

        let writer = try AVAssetWriter(outputURL: outURL, fileType: .wav)
        let writerInput = AVAssetWriterInput(
            mediaType: .audio,
            outputSettings: [
                AVFormatIDKey: kAudioFormatLinearPCM,
                linearPCMIsNonInterleavedKey: false,
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMBitDepthKey: 16,
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1
            ]
        )
        writerInput.expectsMediaDataInRealTime = false
        writer.add(writerInput)

        guard reader.startReading() else {
            print("[Recognizer] WAV reader.startReading failed: \(reader.error?.localizedDescription ?? "nil")")
            throw reader.error ?? NormalizeError.exportFailed
        }
        guard writer.startWriting() else {
            print("[Recognizer] WAV writer.startWriting failed: \(writer.error?.localizedDescription ?? "nil")")
            throw writer.error ?? NormalizeError.exportFailed
        }
        writer.startSession(atSourceTime: .zero)

        let q = DispatchQueue(label: "audio.wav.transcode")
        return try await withCheckedThrowingContinuation { cont in
            writerInput.requestMediaDataWhenReady(on: q) {
                while writerInput.isReadyForMoreMediaData {
                    if let sbuf = readerOutput.copyNextSampleBuffer() {
                        _ = writerInput.append(sbuf)
                    } else {
                        writerInput.markAsFinished()
                        writer.finishWriting {
                            if writer.status == .completed {
                                print("[Recognizer] WAV written \(outURL.lastPathComponent)")
                                cont.resume(returning: outURL)
                            } else {
                                cont.resume(throwing: writer.error ?? NormalizeError.exportFailed)
                            }
                        }
                        break
                    }
                }
            }
        }
    }

    private static func transcodeToM4A(inputURL: URL) async throws -> URL {
        let asset = AVURLAsset(url: inputURL, options: assetOptions(for: inputURL))
        guard let track = asset.tracks(withMediaType: .audio).first else { throw NormalizeError.noAudioTrack }

        let outURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("snippet_\(UUID().uuidString).m4a")
        try? FileManager.default.removeItem(at: outURL)

        let reader = try AVAssetReader(asset: asset)
        let readerOutput = AVAssetReaderTrackOutput(
            track: track,
            outputSettings: [
                AVFormatIDKey: kAudioFormatLinearPCM,
                linearPCMIsNonInterleavedKey: false,
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMBitDepthKey: 16
            ]
        )
        readerOutput.alwaysCopiesSampleData = false
        reader.add(readerOutput)

        let writer = try AVAssetWriter(outputURL: outURL, fileType: .m4a)
        let writerInput = AVAssetWriterInput(
            mediaType: .audio,
            outputSettings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderBitRateKey: 64_000
            ]
        )
        writerInput.expectsMediaDataInRealTime = false
        writer.add(writerInput)

        guard reader.startReading() else {
            print("[Recognizer] M4A reader.startReading failed: \(reader.error?.localizedDescription ?? "nil")")
            throw reader.error ?? NormalizeError.exportFailed
        }
        guard writer.startWriting() else {
            print("[Recognizer] M4A writer.startWriting failed: \(writer.error?.localizedDescription ?? "nil")")
            throw writer.error ?? NormalizeError.exportFailed
        }
        writer.startSession(atSourceTime: .zero)

        let q = DispatchQueue(label: "audio.m4a.transcode")
        return try await withCheckedThrowingContinuation { cont in
            writerInput.requestMediaDataWhenReady(on: q) {
                while writerInput.isReadyForMoreMediaData {
                    if let sbuf = readerOutput.copyNextSampleBuffer() {
                        _ = writerInput.append(sbuf)
                    } else {
                        writerInput.markAsFinished()
                        writer.finishWriting {
                            if writer.status == .completed {
                                print("[Recognizer] M4A written \(outURL.lastPathComponent)")
                                cont.resume(returning: outURL)
                            } else {
                                cont.resume(throwing: writer.error ?? NormalizeError.exportFailed)
                            }
                        }
                        break
                    }
                }
            }
        }
    }

    private static func exportToM4A(inputURL: URL) async throws -> URL {
        let asset = AVURLAsset(url: inputURL, options: assetOptions(for: inputURL))
        let outURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("snippet_\(UUID().uuidString).m4a")
        try? FileManager.default.removeItem(at: outURL)

        guard let export = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw NormalizeError.exportFailed
        }
        export.outputURL = outURL
        export.outputFileType = .m4a
        export.timeRange = CMTimeRange(start: .zero, duration: asset.duration)

        return try await withCheckedThrowingContinuation { cont in
            export.exportAsynchronously {
                switch export.status {
                case .completed:
                    print("[Recognizer] M4A(export) written \(outURL.lastPathComponent)")
                    cont.resume(returning: outURL)
                case .failed, .cancelled:
                    cont.resume(throwing: export.error ?? NormalizeError.exportFailed)
                default:
                    cont.resume(throwing: export.error ?? NormalizeError.exportFailed)
                }
            }
        }
    }

    private static func assetOptions(for url: URL) -> [String: Any] {
        // Ajuda o AVURLAsset a reconhecer formatos “raw” como AAC+ (ADTS) quando a extensão não é suficiente.
        let ext = url.pathExtension.lowercased()
        let mime: String? = {
            switch ext {
            case "aac": return "audio/aac"
            case "mp3": return "audio/mpeg"
            case "m4a": return "audio/mp4"
            case "ts": return "video/mp2t"
            case "wav": return "audio/wav"
            default: return nil
            }
        }()
        if let mime {
            return ["AVURLAssetOutOfBandMIMETypeKey": mime]
        }
        return [:]
    }
}

