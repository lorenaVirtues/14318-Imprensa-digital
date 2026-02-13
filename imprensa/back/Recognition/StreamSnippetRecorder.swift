import Foundation

/// Captura um trecho curto do áudio do streaming (re-baixando do stream).
/// Observação: não “grava” o áudio do sistema; apenas baixa alguns segundos do stream.
enum StreamSnippetRecorder {
    struct Snippet {
        let sourceURL: URL
        let fileURL: URL
        let contentType: String?
        let isHLS: Bool
    }

    enum RecorderError: Error {
        case invalidResponse
        case emptySnippet
        case hlsNoSegments
    }

    static func capture(
        from url: URL,
        durationSeconds: TimeInterval = 10,
        userAgent: String,
        session: URLSession = .shared
    ) async throws -> Snippet {
        print("[Recognizer] capture start url=\(url.absoluteString) duration=\(durationSeconds)s")

        var req = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: max(20, durationSeconds + 15))
        req.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        req.setValue("*/*", forHTTPHeaderField: "Accept")
        req.setValue("no-cache", forHTTPHeaderField: "Cache-Control")

        // Faz o primeiro fetch em modo streaming, para detectar HLS vs stream contínuo.
        let (bytes, resp) = try await session.bytes(for: req)
        
        let http = resp as? HTTPURLResponse
        let contentType = http?.value(forHTTPHeaderField: "Content-Type")
        if let http { print("[Recognizer] capture status=\(http.statusCode) contentType=\(contentType ?? "nil")") }

        let tmpDir = FileManager.default.temporaryDirectory
        let ext = preferredExtension(forContentType: contentType)
        let rawURL = tmpDir.appendingPathComponent("snippet_raw_\(UUID().uuidString).\(ext)")
        
        var buffer = Data()
        let deadline = Date().addingTimeInterval(durationSeconds)
        let headerLimit = 4096
        
        do {
            for try await b in bytes {
                buffer.append(b)
                if Date() > deadline { break }
            }
        } catch {
            print("[Recognizer] streaming collection interrupted: \(error.localizedDescription)")
        }

        if buffer.isEmpty { throw RecorderError.emptySnippet }
        let totalBytes = buffer.count

        let headerData = buffer.prefix(headerLimit)
        let headerText = String(data: headerData, encoding: .utf8) ?? ""
        let isHLS = (contentType?.lowercased().contains("mpegurl") == true) || headerText.contains("#EXTM3U")

        if isHLS {
            print("[Recognizer] capture detected HLS, switching to segments")
            return try await captureHLSSegments(from: url, userAgent: userAgent, session: session)
        }
        
        try buffer.write(to: rawURL)
        print("[Recognizer] capture raw bytes=\(totalBytes) saved=\(rawURL.lastPathComponent)")
        return Snippet(sourceURL: url, fileURL: rawURL, contentType: contentType, isHLS: false)
    }

    // MARK: - HLS

    private static func captureHLSSegments(
        from playlistURL: URL,
        userAgent: String,
        session: URLSession
    ) async throws -> Snippet {
        var req = URLRequest(url: playlistURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 25)
        req.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        req.setValue("*/*", forHTTPHeaderField: "Accept")
        req.setValue("no-cache", forHTTPHeaderField: "Cache-Control")

        let (data, resp) = try await session.data(for: req)
        let http = resp as? HTTPURLResponse
        let contentType = http?.value(forHTTPHeaderField: "Content-Type")
        if let http { print("[Recognizer] HLS playlist status=\(http.statusCode) bytes=\(data.count)") }

        let text = String(data: data, encoding: .utf8) ?? ""
        let lines = text
            .split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        // Pega as últimas URLs de segmentos (ignora comentários)
        let segmentLines = lines.filter { !$0.hasPrefix("#") }
        let lastSegments = segmentLines.suffix(4) // pega algumas para aumentar chance de áudio decodável
        guard !lastSegments.isEmpty else { throw RecorderError.hlsNoSegments }

        let tmpDir = FileManager.default.temporaryDirectory
        let outURL = tmpDir.appendingPathComponent("snippet_hls_\(UUID().uuidString).ts")
        FileManager.default.createFile(atPath: outURL.path, contents: nil)
        let handle = try FileHandle(forWritingTo: outURL)
        defer { try? handle.close() }

        for seg in lastSegments {
            guard let segURL = URL(string: seg, relativeTo: playlistURL)?.absoluteURL else { continue }
            var segReq = URLRequest(url: segURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 25)
            segReq.setValue(userAgent, forHTTPHeaderField: "User-Agent")
            let (segData, segResp) = try await session.data(for: segReq)
            let segHttp = segResp as? HTTPURLResponse
            if let segHttp { print("[Recognizer] HLS segment status=\(segHttp.statusCode) bytes=\(segData.count) url=\(segURL.lastPathComponent)") }
            if !segData.isEmpty { try handle.write(contentsOf: segData) }
        }

        let attrs = try FileManager.default.attributesOfItem(atPath: outURL.path)
        let size = (attrs[.size] as? NSNumber)?.intValue ?? 0
        if size <= 0 { throw RecorderError.emptySnippet }

        print("[Recognizer] HLS snippet saved=\(outURL.lastPathComponent) bytes=\(size)")
        return Snippet(sourceURL: playlistURL, fileURL: outURL, contentType: contentType, isHLS: true)
    }

    private static func preferredExtension(forContentType contentType: String?) -> String {
        let ct = contentType?.lowercased() ?? ""
        if ct.contains("aac") { return "aac" }          // audio/aacp, audio/aac
        if ct.contains("mpeg") { return "mp3" }         // audio/mpeg
        if ct.contains("mp4") { return "m4a" }          // audio/mp4
        if ct.contains("wav") { return "wav" }          // audio/wav
        return "bin"
    }
}

