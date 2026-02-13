import Foundation

enum ShazamAPIClient {
    struct Result {
        let title: String
        let artist: String
        let rawJSON: Any?
        let rawText: String?
    }

    enum ClientError: Error {
        case badStatus(Int)
        case invalidResponse
        case parseFailed
        case upstreamFailed(Int)
        case noMatch(retryMs: Int?)
    }

    static func recognize(audioFileURL: URL, session: URLSession = .shared) async throws -> Result {
        let endpoint = URL(string: "https://virtues.now/shazam/")!
        let boundary = "Boundary-\(UUID().uuidString)"

        var req = URLRequest(url: endpoint, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 35)
        req.httpMethod = "POST"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")

        let fileData = try Data(contentsOf: audioFileURL)
        let fileName = audioFileURL.lastPathComponent
        let mime = mimeType(for: audioFileURL)

        var body = Data()
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"audio\"; filename=\"\(fileName)\"\r\n")
        body.appendString("Content-Type: \(mime)\r\n\r\n")
        body.append(fileData)
        body.appendString("\r\n--\(boundary)--\r\n")

        let start = Date()
        print("[Recognizer] Uploading \(fileName) bytes=\(fileData.count) mime=\(mime)")
        let (respData, resp) = try await session.upload(for: req, from: body)
        let dt = Date().timeIntervalSince(start)

        guard let http = resp as? HTTPURLResponse else { throw ClientError.invalidResponse }
        print("[Recognizer] shazam status=\(http.statusCode) time=\(String(format: "%.2f", dt))s bytes=\(respData.count)")

        guard (200..<300).contains(http.statusCode) else {
            let errorText = String(data: respData, encoding: .utf8) ?? "N/A"
            print("[Recognizer] shazam error_body: \(errorText)")
            throw ClientError.badStatus(http.statusCode)
        }

        let text = String(data: respData, encoding: .utf8)
        if let text {
            let prefix = String(text.prefix(2000))
            print("[Recognizer] shazam body_prefix=\n\(prefix)")
        }

        // 1) Tenta parsear JSON direto (estrutura do backend pode variar)
        if let json = try? JSONSerialization.jsonObject(with: respData, options: [.fragmentsAllowed]),
           let extracted = extractTitleArtist(from: json) {
            return Result(title: extracted.title, artist: extracted.artist, rawJSON: json, rawText: text)
        }

        // 2) Alguns backends retornam um "curl ..." (texto) com a chamada para o endpoint do Shazam.
        if let text, let curl = parseCurlLikeResponse(text) {
            let (upData, upResp) = try await session.data(for: curl.request)
            guard let upHTTP = upResp as? HTTPURLResponse else { throw ClientError.invalidResponse }
            print("[Recognizer] shazam-upstream status=\(upHTTP.statusCode) bytes=\(upData.count)")

            let upText = String(data: upData, encoding: .utf8)
            if let upText {
                let prefix = String(upText.prefix(2000))
                print("[Recognizer] shazam-upstream body_prefix=\n\(prefix)")
            }

            guard (200..<300).contains(upHTTP.statusCode) else { throw ClientError.upstreamFailed(upHTTP.statusCode) }

            if let upJSON = try? JSONSerialization.jsonObject(with: upData, options: [.fragmentsAllowed]) {
                if let extracted = extractTitleArtist(from: upJSON) {
                    return Result(title: extracted.title, artist: extracted.artist, rawJSON: upJSON, rawText: upText)
                }

                // Caso comum: {"matches":[],"tagid":"...","retryms":7000}
                if let dict = upJSON as? [String: Any],
                   let matches = dict["matches"] as? [Any],
                   matches.isEmpty {
                    let retry = dict["retryms"] as? Int
                    throw ClientError.noMatch(retryMs: retry)
                }
            }
        }

        // Se não conseguimos extrair, devolve parseFailed (logs já mostram o corpo)
        throw ClientError.parseFailed
    }

    private static func extractTitleArtist(from json: Any) -> (title: String, artist: String)? {
        // 1) { "title": "...", "artist": "..." }
        if let dict = json as? [String: Any] {
            if let title = dict["title"] as? String,
               let artist = dict["artist"] as? String,
               !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               !artist.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return (title, artist)
            }

            // 2) { "track": { "title": "...", "subtitle": "..." } }
            if let track = dict["track"] as? [String: Any],
               let title = track["title"] as? String {
                let artist = (track["subtitle"] as? String)
                    ?? (track["artist"] as? String)
                    ?? ""
                if !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                   !artist.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return (title, artist)
                }
            }

            // 3) Shazam discovery: { "matches": [ { "track": { ... } } ] } ou { "matches": [ ... ] }
            if let matches = dict["matches"] as? [Any] {
                for m in matches {
                    if let found = extractTitleArtist(from: m) { return found }
                }
            }

            // Busca recursiva em dicionários/listas
            for (_, v) in dict {
                if let found = extractTitleArtist(from: v) { return found }
            }
        } else if let arr = json as? [Any] {
            for v in arr {
                if let found = extractTitleArtist(from: v) { return found }
            }
        }
        return nil
    }

    private struct CurlParsed {
        let request: URLRequest
    }

    private static func parseCurlLikeResponse(_ text: String) -> CurlParsed? {
        // Exemplo esperado (simplificado):
        // curl 'https://amp.shazam.com/...' -H 'Content-Type: application/json' ... --data-raw '{...json...}'
        guard text.contains("curl "), text.contains("--data-raw") else { return nil }

        guard let url = extractSingleQuotedValue(after: "curl ", in: text) else { return nil }
        guard let endpoint = URL(string: url) else { return nil }

        var headers: [String: String] = [:]
        // percorre todas ocorrências de -H 'Key: Value'
        var searchRange = text.startIndex..<text.endIndex
        while let r = text.range(of: "-H '", range: searchRange) {
            let after = r.upperBound
            guard let end = text[after...].firstIndex(of: "'") else { break }
            let hv = String(text[after..<end])
            if let sep = hv.firstIndex(of: ":") {
                let k = hv[..<sep].trimmingCharacters(in: .whitespacesAndNewlines)
                let v = hv[hv.index(after: sep)...].trimmingCharacters(in: .whitespacesAndNewlines)
                if !k.isEmpty { headers[String(k)] = String(v) }
            }
            searchRange = end..<text.endIndex
        }

        guard let jsonBody = extractSingleQuotedValue(after: "--data-raw ", in: text),
              let bodyData = jsonBody.data(using: .utf8) else { return nil }

        var req = URLRequest(url: endpoint, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 25)
        req.httpMethod = "POST"
        req.httpBody = bodyData
        for (k, v) in headers {
            req.setValue(v, forHTTPHeaderField: k)
        }
        // garante content-type
        if req.value(forHTTPHeaderField: "Content-Type") == nil {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        req.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")

        print("[Recognizer] shazam-upstream url=\(endpoint.absoluteString)")
        return CurlParsed(request: req)
    }

    private static func extractSingleQuotedValue(after needle: String, in text: String) -> String? {
        guard let r = text.range(of: needle) else { return nil }
        let s = text[r.upperBound...]
        guard let first = s.firstIndex(of: "'") else { return nil }
        let rest = s[text.index(after: first)...]
        guard let second = rest.firstIndex(of: "'") else { return nil }
        return String(rest[..<second])
    }

    private static func mimeType(for url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "wav": return "audio/wav"
        case "m4a": return "audio/mp4"
        case "mp3": return "audio/mpeg"
        case "ts": return "video/mp2t"
        default: return "application/octet-stream"
        }
    }
}

private extension Data {
    mutating func appendString(_ s: String) {
        if let d = s.data(using: .utf8) { append(d) }
    }
}

