import SwiftUI
import AVKit
import WebKit
import UIKit
import AVFoundation
import Shimmer

enum IGVideo {
    static let userAgent =
      "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
    static let referer = "https://www.instagram.com/"

    static func headIsPlayable(_ url: URL) async -> Bool {
        var req = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10)
        req.httpMethod = "HEAD"
        req.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        req.setValue(referer, forHTTPHeaderField: "Referer")
        do {
            let (_, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else { return false }
            let headers = http.allHeaderFields
            let ct = (headers["Content-Type"] as? String) ?? (headers["content-type"] as? String) ?? ""
            return ct.lowercased().contains("video")
        } catch {
            return false
        }
    }
}
final class IGAssetResourceLoader: NSObject, AVAssetResourceLoaderDelegate, URLSessionDataDelegate {

    private let originalHTTPSURL: URL
    private lazy var session: URLSession = {
        URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }()

    // Mantém task por loadingRequest
    private var tasks: [AVAssetResourceLoadingRequest: URLSessionDataTask] = [:]
    private var responseInfo: [AVAssetResourceLoadingRequest: URLResponse] = [:]

    init(originalURL: URL) {
        self.originalHTTPSURL = originalURL
        super.init()
    }

    // Troca "igproxy" -> "https"
    private func realURL(from requestURL: URL?) -> URL? {
        guard var comp = requestURL.flatMap({ URLComponents(url: $0, resolvingAgainstBaseURL: false) }) else { return nil }
        comp.scheme = "https"
        return comp.url
    }

    func resourceLoader(_ resourceLoader: AVAssetResourceLoader,
                        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {

        guard let httpsURL = realURL(from: loadingRequest.request.url) else {
            loadingRequest.finishLoading(with: NSError(domain: "IGLoader", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL inválida"]))
            return false
        }

        var req = URLRequest(url: httpsURL, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30)
        req.setValue(IGVideo.userAgent, forHTTPHeaderField: "User-Agent")
        req.setValue(IGVideo.referer, forHTTPHeaderField: "Referer")

        if let dataReq = loadingRequest.dataRequest {
            // Suporte básico a byte-range
            let offset = Int64(dataReq.requestedOffset)
            // Se o player pedir de um offset específico, envia Range
            if offset > 0 {
                req.setValue("bytes=\(offset)-", forHTTPHeaderField: "Range")
            }
        }

        let task = session.dataTask(with: req)
        tasks[loadingRequest] = task
        task.resume()
        return true
    }

    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        tasks[loadingRequest]?.cancel()
        tasks.removeValue(forKey: loadingRequest)
        responseInfo.removeValue(forKey: loadingRequest)
    }

    // MARK: URLSessionDataDelegate

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {

        guard let loadingRequest = tasks.first(where: { $0.value == dataTask })?.key else {
            completionHandler(.cancel)
            return
        }

        responseInfo[loadingRequest] = response

        if let http = response as? HTTPURLResponse,
           let info = loadingRequest.contentInformationRequest {

            // Tipo de conteúdo
            let mime = http.mimeType?.lowercased() ?? ""
            // Mapear MIME -> UTI comum do AVFoundation
            if mime.contains("mp4") {
                info.contentType = "public.mpeg-4"
            } else if mime.contains("mpegurl") || mime.contains("m3u8") {
                info.contentType = "application/vnd.apple.mpegurl"
            } else {
                info.contentType = mime // melhor que nada
            }

            let length = http.expectedContentLength
            if length > 0 { info.contentLength = length }

            // Quase todos os CDNs suportam range; se houver "Accept-Ranges", marca true
            let acceptsRanges = (http.allHeaderFields["Accept-Ranges"] as? String)?.lowercased().contains("bytes") ?? true
            info.isByteRangeAccessSupported = acceptsRanges
        }

        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let loadingRequest = tasks.first(where: { $0.value == dataTask })?.key,
              let dataReq = loadingRequest.dataRequest else { return }

        dataReq.respond(with: data)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let loadingRequest = tasks.first(where: { $0.value == task })?.key else { return }

        defer {
            tasks.removeValue(forKey: loadingRequest)
            responseInfo.removeValue(forKey: loadingRequest)
        }

        if let error = error {
            loadingRequest.finishLoading(with: error)
        } else {
            loadingRequest.finishLoading()
        }
    }
}
struct InstagramPlayerView: View {
    let mp4URL: URL
    let postURL: URL?   // fallback p/ Web

    @State private var player: AVPlayer?
    @State private var loader: IGAssetResourceLoader?
    @State private var failed = false
    @State private var statusObserver: NSKeyValueObservation?

    var body: some View {
        ZStack {
            if failed {
                if let post = postURL {
                    WebEmbedView(url: post) // fallback final
                } else {
                    Color.black.opacity(0.1)
                }
            } else if let player {
                VideoPlayer(player: player)
                    // Sem autoplay: sem player.play() aqui
                    .onDisappear { player.pause() }
            } else {
                MediaSkeleton()
            }
        }
        .task { await prepare() }
    }

    @MainActor
    private func prepare() async {
        // 1) HEAD: evita “loading infinito” com URL expirada/barrada
        let ok = await IGVideo.headIsPlayable(mp4URL)
        guard ok else {
            failed = true
            return
        }

        // 2) Monta o asset (iOS 16: UA nativo; iOS 15: resource loader com UA+Referer)
        let asset: AVURLAsset
        if #available(iOS 16.0, *) {
            asset = AVURLAsset(url: mp4URL, options: [AVURLAssetHTTPUserAgentKey: IGVideo.userAgent])
        } else {
            let proxied = mp4URL.replacingScheme("igproxy")
            let a = AVURLAsset(url: proxied)
            let ldr = IGAssetResourceLoader(originalURL: mp4URL)
            a.resourceLoader.setDelegate(ldr, queue: .global(qos: .userInitiated))
            self.loader = ldr // manter referência forte
            asset = a
        }

        // 3) Prepara player (sem dar play)
        let item = AVPlayerItem(asset: asset)
        let p = AVPlayer(playerItem: item)
        p.automaticallyWaitsToMinimizeStalling = true
        p.currentItem?.preferredForwardBufferDuration = 2
        self.player = p

        // 4) Observa falha de preparo (sem exigir que esteja tocando)
        statusObserver = item.observe(\.status, options: [.initial, .new]) { itm, _ in
            DispatchQueue.main.async {
                if itm.status == .failed {
                    self.player?.pause()
                    self.player = nil
                    self.failed = true
                }
            }
        }
    }
}
extension URL {
    func replacingScheme(_ scheme: String) -> URL {
        var comp = URLComponents(url: self, resolvingAgainstBaseURL: false)!
        comp.scheme = scheme
        return comp.url!
    }
}

// MARK: - Models

struct SocialFeedResponse: Decodable {
    let merged_at: TimeInterval
    let schema: [String]
    let items: [SafeSocialItem]
    
    struct SafeSocialItem: Decodable {
        let item: SocialItem?
        init(from decoder: Decoder) throws {
            do {
                item = try SocialItem(from: decoder)
            } catch {
                print("⚠️ Erro ao decodificar item social: \(error)")
                item = nil
            }
        }
    }
}

struct SocialItem: Identifiable, Decodable, Hashable {
    let platform: Platform
    let url: String
    let text: String
    let posted_at: TimeInterval
    let media_urls: [String]
    let id: Int
}

enum Platform: String, CaseIterable, Codable, Identifiable {
    case instagram, tiktok, facebook, youtube, x
    var id: String { rawValue }
    var label: String {
        switch self {
        case .instagram: return "Instagram"
        case .tiktok:    return "TikTok"
        case .facebook:  return "Facebook"
        case .youtube:   return "YouTube"
        case .x:         return "X"
        }
    }
    var sfSymbol: String {
        switch self {
        case .instagram: return "camera.aperture"
        case .tiktok:    return "music.note"
        case .facebook:  return "f.circle"
        case .youtube:   return "play.rectangle.fill"
        case .x:         return "xmark"
        }
    }
}

// MARK: - Persistência de ações (curtir/favoritar)

final class SocialActions: ObservableObject {
    @Published private(set) var liked: Set<Int> = []
    @Published private(set) var favorited: Set<Int> = []
    @Published private(set) var hidden: Set<Int> = []             // ⬅️ novo

    private let likedKey = "social.liked.ids"
    private let favKey   = "social.favorited.ids"
    private let hiddenKey = "social.hidden.ids"                   // ⬅️ novo

    init() {
        liked = Set(UserDefaults.standard.array(forKey: likedKey) as? [Int] ?? [])
        favorited = Set(UserDefaults.standard.array(forKey: favKey) as? [Int] ?? [])
        hidden = Set(UserDefaults.standard.array(forKey: hiddenKey) as? [Int] ?? [])   // ⬅️ novo
    }

    func toggleLike(_ id: Int) {
        if liked.contains(id) { liked.remove(id) } else { liked.insert(id) }
        UserDefaults.standard.set(Array(liked), forKey: likedKey)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func toggleFavorite(_ id: Int) {
        if favorited.contains(id) { favorited.remove(id) } else { favorited.insert(id) }
        UserDefaults.standard.set(Array(favorited), forKey: favKey)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    // ⬇️ NOVO: ocultar/desocultar
    func toggleHidden(_ id: Int) {
        if hidden.contains(id) {
            hidden.remove(id)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            hidden.insert(id)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        UserDefaults.standard.set(Array(hidden), forKey: hiddenKey)
    }

    func isLiked(_ id: Int) -> Bool { liked.contains(id) }
    func isFavorited(_ id: Int) -> Bool { favorited.contains(id) }
    func isHidden(_ id: Int) -> Bool { hidden.contains(id) }       // ⬅️ novo
}


// MARK: - VM

@MainActor
final class SocialFeedVM: ObservableObject {
    @Published var items: [SocialItem] = []
    @Published var query: String = ""
    @Published var selected: Set<Platform> = []
    @Published var isLoading = false
    @Published var error: String? = nil
    @Published var shareItem: SocialItem? = nil  // abre o sheet de compartilhar

    func load(from urlString: String) async {
        guard let url = URL(string: urlString) else {
            error = "URL inválida"
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            let resp = try decoder.decode(SocialFeedResponse.self, from: data)
            // Filtra os nulos (falhas de decode) e ordena
            self.items = resp.items.compactMap { $0.item }.sorted(by: { $0.posted_at > $1.posted_at })
        } catch {
            self.error = "Falha ao carregar: \(error.localizedDescription)"
        }
    }

    var filtered: [SocialItem] {
        var r = items
               if !selected.isEmpty {
                   r = r.filter { selected.contains($0.platform) }
               }
        if !query.isEmpty {
            let q = query.lowercased()
            r = r.filter { $0.text.lowercased().contains(q) || $0.url.lowercased().contains(q) }
        }
        return r
    }
}

// MARK: - Utils

extension TimeInterval {
    func asRelativeString() -> String {
        let date = Date(timeIntervalSince1970: self)
        let rel = RelativeDateTimeFormatter()
        rel.locale = Locale(identifier: "pt_BR")
        rel.unitsStyle = .full
        return rel.localizedString(for: date, relativeTo: Date())
    }
}

extension String {
    var isVideoURL: Bool {
        let lower = self.lowercased()
        return lower.hasSuffix(".mp4") || lower.hasSuffix(".m3u8")
    }
    var isYouTube: Bool { contains("youtube.com") || contains("youtu.be") }
}

// MARK: - Player & Embeds

struct AVPlayerView: View {
    let url: URL
    @State private var player: AVPlayer? = nil

    var body: some View {
        VideoPlayer(player: player)
            .onAppear {
                player = AVPlayer(url: url)
                player?.play()
            }
            .onDisappear {
                player?.pause()
                player = nil
            }
    }
}

struct WebEmbedView: UIViewRepresentable {
    let url: URL
    func makeUIView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        cfg.allowsInlineMediaPlayback = true
        let web = WKWebView(frame: .zero, configuration: cfg)
        web.scrollView.isScrollEnabled = true
        web.scrollView.bounces = false
        web.backgroundColor = .clear
        web.isOpaque = false
        web.load(URLRequest(url: url))
        return web
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

struct YouTubeEmbedView: UIViewRepresentable {
    let postURL: URL
    func makeUIView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        cfg.allowsInlineMediaPlayback = true
        let web = WKWebView(frame: .zero, configuration: cfg)
        web.isOpaque = false
        web.backgroundColor = .clear
        if let embed = Self.embedURL(from: postURL) {
            web.load(URLRequest(url: embed))
        } else {
            web.load(URLRequest(url: postURL))
        }
        return web
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    static func embedURL(from url: URL) -> URL? {
        let s = url.absoluteString
        var videoID: String? = nil
        
        if s.contains("youtu.be/") {
            videoID = s.split(separator: "/").last?.split(separator: "?").first.map(String.init)
        } else if s.contains("watch?v=") {
            if let comp = URLComponents(string: s) {
                videoID = comp.queryItems?.first(where: { $0.name == "v" })?.value
            }
        } else if s.contains("shorts/") {
            videoID = s.components(separatedBy: "shorts/").last?.split(separator: "?").first.map(String.init)
        } else if s.contains("embed/") {
            videoID = s.components(separatedBy: "embed/").last?.split(separator: "?").first.map(String.init)
        }
        
        if let id = videoID {
            return URL(string: "https://www.youtube-nocookie.com/embed/\(id)?playsinline=1")
        }
        return nil
    }
}

// MARK: - Share sheet (iOS 15)

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Card

struct SocialCardView: View {
    let item: SocialItem
    @EnvironmentObject var actions: SocialActions
    @State private var showShare = false

    @State private var showRedirectConfirm = false
    @State private var candidateURL: URL? = nil
    @State private var presentURL: URL? = nil

    @GestureState private var pressing = false // feedback no long-press

    var body: some View {
        Group {
            if actions.isHidden(item.id) {
                // Card fino quando oculto (segure para mostrar)
                HiddenPostView(platform: item.platform) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        actions.toggleHidden(item.id) // desocultar
                    }
                }
            } else {
                // ===== Card completo (seu conteúdo original) =====
                VStack(alignment: .leading, spacing: 10) {
                    // Cabeçalho
                    HStack(spacing: 8) {
                        Image(systemName: item.platform.sfSymbol)
                        Text(item.platform.label)
                            .font(.headline)
                        Spacer()
                        Text(item.posted_at.asRelativeString())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Texto
                    if !item.text.isEmpty {
                        ExpandableText(text: item.text, lineLimit: 6, font: .subheadline)
                    }

                    // Mídia
                    MediaBlock(item: item)
                        .frame(maxWidth: .infinity)
                        .frame(height: 230)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    // Ações
                    HStack(spacing: 18) {
                        Button {
                            actions.toggleLike(item.id)
                        } label: {
                            Label("Curtir", systemImage: actions.isLiked(item.id) ? "heart.fill" : "heart")
                                .labelStyle(.iconOnly)
                                .foregroundColor(actions.isLiked(item.id) ? .red : .primary)
                                .font(.title3)
                        }

                        Button {
                            actions.toggleFavorite(item.id)
                        } label: {
                            Label("Favoritar", systemImage: actions.isFavorited(item.id) ? "bookmark.fill" : "bookmark")
                                .labelStyle(.iconOnly)
                                .foregroundColor(actions.isFavorited(item.id) ? .yellow : .primary)
                                .font(.title3)
                        }

                        Button {
                            showShare = true
                        } label: {
                            Label("Compartilhar", systemImage: "square.and.arrow.up")
                                .labelStyle(.iconOnly)
                                .font(.title3)
                        }
                        .sheet(isPresented: $showShare) {
                            let shareText = item.text.isEmpty ? "" : "\(item.text)\n"
                            ShareSheet(items: [shareText, URL(string: item.url)!].compactMap { $0 })
                        }

                        Spacer()

                        // Abrir fora (com aviso de redirecionamento)
                        Button(action: {
                            candidateURL = URL(string: item.url)
                            showRedirectConfirm = candidateURL != nil
                        }, label: {
                            Image(systemName: "arrow.up.right.square")
                        })
                        .font(.title3)
                        .alert("Abrir \(item.platform.label)?",
                               isPresented: $showRedirectConfirm) {
                            Button("Cancelar", role: .cancel) { }
                            Button("Abrir") {
                                // abre dentro do app (SafariView)
                                presentURL = candidateURL
                            }
                        } message: {
                            Text("Você será redirecionado para o site/app do \(item.platform.label).")
                        }
                        .sheet(item: $presentURL) { url in
                            SafariView(url: url)
                        }
                    }
                    .padding(.top, 4)
                }
                .contentShape(Rectangle())                         // ⬅️ área do gesto
                .scaleEffect(pressing ? 0.98 : 1)
                .animation(.easeInOut(duration: 0.15), value: pressing)
                .simultaneousGesture(                                // ⬅️ troca de .gesture -> .simultaneousGesture
                    LongPressGesture(minimumDuration: 0.6, maximumDistance: 12)
                        .updating($pressing) { _, state, _ in state = true }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                actions.toggleHidden(item.id)       // ocultar
                            }
                        }
                )
            }
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
        )
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.98)),
            removal: .opacity.combined(with: .scale(scale: 0.98))
        ))
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: actions.isHidden(item.id))
    }
}


struct MediaBlock: View {
    let item: SocialItem

    var body: some View {
        ZStack {
            switch item.platform {
            case .instagram, .tiktok:
                if let s = item.media_urls.first, let u = URL(string: s) {
                        InstagramPlayerView(mp4URL: u, postURL: URL(string: item.url))
                    } else if let thumb = item.media_urls.first, let u = URL(string: thumb) {
                        AsyncImage(url: u) { img in
                            img.resizable()
                               .scaledToFit()
                               .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } placeholder: { MediaSkeleton() }
                    } else {
                        // Placeholder quando não há mídia disponível
                        MediaUnavailablePlaceholder(platform: item.platform)
                    }

            case .youtube:
                if let y = URL(string: item.url) {
                    YouTubeEmbedView(postURL: y)
                } else if let thumb = item.media_urls.first, let u = URL(string: thumb) {
                    AsyncImage(url: u) { img in
                        img.resizable()
                           .scaledToFit()
                           .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } placeholder: { MediaSkeleton() }
                } else {
                    MediaUnavailablePlaceholder(platform: item.platform)
                }

            case .facebook, .x:
                if let imgURL = item.media_urls.first, let u = URL(string: imgURL) {
                    AsyncImage(url: u) { img in
                        img.resizable()
                           .scaledToFit()
                           .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } placeholder: { MediaSkeleton() }
                } else {
                    // Placeholder quando não há mídia disponível
                    MediaUnavailablePlaceholder(platform: item.platform)
                }
            }
        }
        .contentShape(Rectangle())
    }

    private func firstPlayable(_ item: SocialItem) -> URL? {
        if let s = item.media_urls.first(where: { $0.isVideoURL }),
           let u = URL(string: s) { return u }
        return nil
    }
}

// MARK: - Filtros (chips)

struct FilterBar: View {
    @Binding var selected: Set<Platform>

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Chip(title: "Todos", isOn: selected.isEmpty) { selected.removeAll() }
                ForEach(Platform.allCases) { p in
                                    Chip(title: p.label, system: p.sfSymbol, isOn: selected.contains(p)) {
                                        if selected.contains(p) {
                                            selected.remove(p)
                                        } else {
                                            selected.insert(p)
                                        }
                                    }
                                }
            }
            .padding(8)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

struct Chip: View {
    let title: String
    var system: String? = nil
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let s = system { Image(systemName: s) }
                Text(title).font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(isOn ? Color.white.opacity(0.22) : Color.white.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .foregroundColor(.white)
    }
}

// MARK: - View principal

struct SocialFeedView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var vm = SocialFeedVM()
    @StateObject private var actions = SocialActions()
    @EnvironmentObject private var linkHandler: LinkHandler
    @State private var showUnhideAllConfirm = false

    let apiURL: String
    let initialPlatform: Platform?

    init(apiURL: String = "https://redessociais.ticketss.app/imprensa.json",
         initialPlatform: Platform? = nil) {
        self.apiURL = apiURL
        self.initialPlatform = initialPlatform
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.black.opacity(0.4), Color.blue.opacity(0.3)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                FilterBar(selected: $vm.selected)


                if vm.isLoading {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(0..<6, id: \.self) { _ in
                                SkeletonCardView()
                                    .padding(.horizontal, 16)
                            }
                        }
                        .padding(.vertical, 12)
                    }
                    .refreshable {
                        await vm.load(from: apiURL)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred() // opcional
                    }

                } else if let err = vm.error {
                    // Envolve o erro em um ScrollView para permitir pull-to-refresh
                    ScrollView {
                        VStack(spacing: 16) {
                            Text("Servidor indisponível no momento.")
                                .foregroundColor(.red)
                            Text(err)
                                .font(.footnote)
                                .foregroundColor(.secondary)

                            VStack(spacing: 12) {
                                SocialLinkRow(title: "Instagram", system: "camera.aperture") { linkHandler.openSocial("instagram") }
                                SocialLinkRow(title: "TikTok",    system: "music.note")      { linkHandler.openSocial("tiktok") }
                                SocialLinkRow(title: "Facebook",  system: "f.circle")        { linkHandler.openSocial("facebook") }
                                SocialLinkRow(title: "YouTube",   system: "play.rectangle.fill") { linkHandler.openSocial("youtube") }
                                SocialLinkRow(title: "X",         system: "xmark")           { linkHandler.openSocial("twitter") }
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.vertical, 24)
                    }
                    .refreshable {
                        await vm.load(from: apiURL)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred() // opcional
                    }

                } else if vm.filtered.isEmpty {
                    ScrollView {
                        VStack(spacing: 8) {
                            Text("Nada encontrado")
                                .foregroundColor(.secondary)
                                .padding()
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                    }
                    .refreshable {
                        await vm.load(from: apiURL)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }

                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(vm.filtered) { item in
                                SocialCardView(item: item)
                                    .environmentObject(actions)
                                    .padding(.horizontal, 16)
                            }
                        }
                        .padding(.vertical, 12)
                    }
                    .refreshable {
                        await vm.load(from: apiURL)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }

            }
        }
        .navigationTitle("Redes Sociais")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                        Text("Voltar")
                    }
                    .foregroundColor(.white)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 14) {
                    // Desocultar todos
                    Button(action: {
                        showUnhideAllConfirm = true
                    }, label: {
                        Image(systemName: "eye") // ícone de “mostrar”
                            .font(.system(size: 17, weight: .semibold))
                            .frame(width: 28, height: 28)
                            .contentShape(Rectangle())
                            .accessibilityLabel("Desocultar todos")
                    })
                    .disabled(actions.hidden.isEmpty)
                    .opacity(actions.hidden.isEmpty ? 0.4 : 1.0)
                    .alert("Desocultar todos?", isPresented: $showUnhideAllConfirm) {
                        Button("Cancelar", role: .cancel) { }
                        Button("Desocultar", role: .none) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                actions.unhideAll()
                            }
                        }
                    } message: {
                        Text("Todos os posts ocultos voltarão a aparecer.")
                    }

                    // Curtidos
                    NavigationLink(destination: {
                        LikedFeedView(vm: vm).environmentObject(actions)
                    }, label: {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(width: 28, height: 28)
                            .contentShape(Rectangle())
                            .accessibilityLabel("Curtidos")
                    })

                    // Salvos
                    NavigationLink(destination: {
                        SavedFeedView(vm: vm).environmentObject(actions)
                    }, label: {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(width: 28, height: 28)
                            .contentShape(Rectangle())
                            .accessibilityLabel("Salvos")
                    })
                }
            }
        }


        .task {
                   if let p = initialPlatform {
                       vm.selected = [p]
                   } else {
                       vm.selected.removeAll()
                  }
                    await vm.load(from: apiURL)
                }
        .searchable(text: $vm.query, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Buscar…")
    }
}


// MARK: - Preview (opcional)

struct SocialFeedView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SocialFeedView()
                .environmentObject(LinkHandler.shared)
        }
    }
}

// MARK: - Media helpers

extension URL {
    var looksLikeVideo: Bool {
        let s = absoluteString.lowercased()
        let ext = pathExtension.lowercased()
        if ["mp4", "m4v", "mov", "m3u8"].contains(ext) { return true }
        if s.contains("mime_type=video") || s.contains("content_type=video") { return true }
        if (host ?? "").contains("cdninstagram") && s.contains(".mp4") { return true }
        if (host ?? "").contains("tiktokcdn") && (s.contains("/video/") || s.contains("/tos/")) { return true }
        return false
    }
}

// primeira URL reproduzível do array
func firstPlayableURL(_ media: [String]) -> URL? {
    for s in media {
        if let u = URL(string: s), u.looksLikeVideo { return u }
        if s.lowercased().contains(".mp4"), let u = URL(string: s) { return u }
    }
    return nil
}

// algumas URLs de tiktok no feed são thumbs (…origin.image)
func isTikTokImageURL(_ s: String) -> Bool {
    s.contains("tiktokcdn") && s.contains("origin.image")
}

func formatRelative(_ epoch: TimeInterval) -> String {
    epoch.asRelativeString()
}


// Skeletons básicos
struct SkeletonLine: View {
    var width: CGFloat? = nil
    var height: CGFloat = 12
    var corner: CGFloat = 6
    var body: some View {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
            .fill(Color.white.opacity(0.18))
            .frame(width: width, height: height)
            .shimmering()
    }
}

struct MediaUnavailablePlaceholder: View {
    let platform: Platform
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.08))
            
            VStack(spacing: 12) {
                Image(systemName: platform.sfSymbol)
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.6))
                
                Text("Mídia não disponível")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white.opacity(0.8))
                
                Text("Toque no botão acima para ver no \(platform.label)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        }
    }
}

struct MediaSkeleton: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.white.opacity(0.12))
            .shimmering()
    }
}

// Card “fake” para loading
struct SkeletonCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Cabeçalho
            HStack(spacing: 8) {
                Circle().fill(Color.white.opacity(0.18))
                    .frame(width: 18, height: 18)
                    .shimmering()
                SkeletonLine(width: 90, height: 14)
                Spacer()
                SkeletonLine(width: 70, height: 12)
            }

            // Texto (3 linhas)
            VStack(alignment: .leading, spacing: 6) {
                SkeletonLine(width: nil, height: 12)
                SkeletonLine(width: nil, height: 12)
                SkeletonLine(width: 180, height: 12)
            }

            // Mídia
            MediaSkeleton()
                .frame(height: 230)

            // Ações
            HStack(spacing: 18) {
                ForEach(0..<3) { _ in
                    Circle().fill(Color.white.opacity(0.18))
                        .frame(width: 28, height: 28)
                        .shimmering()
                }
                Spacer()
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 28, height: 28)
                    .shimmering()
            }
            .padding(.top, 4)
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
}

struct SocialLinkRow: View {
    let title: String
    let system: String
    let action: () -> Void

    var body: some View {
        Button(action: action, label: {
            HStack(spacing: 12) {
                Image(systemName: system).imageScale(.medium)
                Text(title).font(.subheadline.weight(.semibold))
                Spacer()
                Image(systemName: "arrow.up.right") // opcional
                    .imageScale(.small)
                    .opacity(0.7)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: 48)      // ⬅️ mesma largura/altura
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.ultraThinMaterial)               // frosted
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
        })
        .buttonStyle(.plain)
        .foregroundColor(.white)
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Curtidos

struct LikedFeedView: View {
    @ObservedObject var vm: SocialFeedVM
    @EnvironmentObject var actions: SocialActions

    @State private var query: String = ""
    @State private var selected: Set<Platform> = []

    private var base: [SocialItem] {
        vm.items.filter { actions.isLiked($0.id) }
    }
    private var filtered: [SocialItem] {
        var r = base
        if !selected.isEmpty { r = r.filter { selected.contains($0.platform) } }
        if !query.isEmpty {
            let q = query.lowercased()
            r = r.filter { $0.text.lowercased().contains(q) || $0.url.lowercased().contains(q) }
        }
        return r.sorted(by: { $0.posted_at > $1.posted_at })
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.black.opacity(0.4), Color.blue.opacity(0.3)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                FilterBar(selected: $selected)

                if vm.isLoading {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(0..<6, id: \.self) { _ in
                                SkeletonCardView()
                                    .padding(.horizontal, 16)
                            }
                        }
                        .padding(.vertical, 12)
                    }
                } else if filtered.isEmpty {
                    VStack(spacing: 8) {
                        Text("Nenhum curtido ainda")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Curta posts no feed para vê-los aqui.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filtered) { item in
                                SocialCardView(item: item)
                                    .environmentObject(actions)
                                    .padding(.horizontal, 16)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            actions.toggleLike(item.id)
                                        } label: {
                                            Label("Remover curtida", systemImage: "heart.slash")
                                        }
                                    }
                            }
                        }
                        .padding(.vertical, 12)
                    }
                }
            }
        }
        .navigationTitle("Curtidos")
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Buscar…")
    }
}

// MARK: - Salvos

struct SavedFeedView: View {
    @ObservedObject var vm: SocialFeedVM
    @EnvironmentObject var actions: SocialActions

    @State private var query: String = ""
    @State private var selected: Set<Platform> = []

    private var base: [SocialItem] {
        vm.items.filter { actions.isFavorited($0.id) }
    }
    private var filtered: [SocialItem] {
        var r = base
        if !selected.isEmpty { r = r.filter { selected.contains($0.platform) } }
        if !query.isEmpty {
            let q = query.lowercased()
            r = r.filter { $0.text.lowercased().contains(q) || $0.url.lowercased().contains(q) }
        }
        return r.sorted(by: { $0.posted_at > $1.posted_at })
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.black.opacity(0.4), Color.blue.opacity(0.3)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                FilterBar(selected: $selected)

                if vm.isLoading {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(0..<6, id: \.self) { _ in
                                SkeletonCardView()
                                    .padding(.horizontal, 16)
                            }
                        }
                        .padding(.vertical, 12)
                    }
                } else if filtered.isEmpty {
                    VStack(spacing: 8) {
                        Text("Nenhum salvo ainda")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Favoritos aparecerão aqui para você rever depois.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filtered) { item in
                                SocialCardView(item: item)
                                    .environmentObject(actions)
                                    .padding(.horizontal, 16)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            actions.toggleFavorite(item.id)
                                        } label: {
                                            Label("Remover dos salvos", systemImage: "bookmark.slash")
                                        }
                                    }
                            }
                        }
                        .padding(.vertical, 12)
                    }
                }
            }
        }
        .navigationTitle("Salvos")
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Buscar…")
    }
}


struct ExpandableText: View {
    let text: String
    var lineLimit: Int = 6
    var font: Font = .subheadline
    var moreLabel: String = "Ler mais…"
    var lessLabel: String = "Ler menos"

    @State private var expanded = false
    @State private var parentWidth: CGFloat = 0
    @State private var limitedHeight: CGFloat = .zero
    @State private var fullHeight: CGFloat = .zero

    private var isTruncated: Bool {
        // tolerância para flutuações de layout
        (fullHeight > 0 && limitedHeight > 0) && fullHeight > (limitedHeight + 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Texto visível
            Text(text)
                .font(font)
                .lineLimit(expanded ? nil : lineLimit)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(.easeInOut(duration: 0.2), value: expanded)

            // Botão só quando realmente precisa
            if isTruncated {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
                }, label: {
                    Text(expanded ? lessLabel : moreLabel)
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.blue)
                        .padding(.vertical, 4)
                })
                .buttonStyle(.plain)
            }
        }
        // Medidores ocultos (só quando já temos largura do pai)
        .background(
            Group {
                if parentWidth > 0 {
                    MeasuringText(text: text, font: font, lineLimit: lineLimit, width: parentWidth) { h in
                        limitedHeight = h
                    }
                    MeasuringText(text: text, font: font, lineLimit: nil, width: parentWidth) { h in
                        fullHeight = h
                    }
                }
            }
        )
        // Lê a largura real do container pai (sem “esticar” layout)
        .overlay(WidthReader { w in parentWidth = w })
    }
}

// MARK: - Helpers

private struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

private struct MeasuringText: View {
    let text: String
    let font: Font
    let lineLimit: Int?
    let width: CGFloat
    var onChange: (CGFloat) -> Void

    var body: some View {
        Text(text)
            .font(font)
            .lineLimit(lineLimit)
            .fixedSize(horizontal: false, vertical: true)
            .frame(width: width, alignment: .leading)
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: HeightPreferenceKey.self, value: proxy.size.height)
                }
            )
            .onPreferenceChange(HeightPreferenceKey.self, perform: onChange)
            .hidden() // fora da tela
    }
}

private struct WidthReader: View {
    var onChange: (CGFloat) -> Void
    var body: some View {
        GeometryReader { geo in
            Color.clear
                .onAppear { onChange(geo.size.width) }
                .onChange(of: geo.size.width) { onChange($0) }
        }
    }
}

struct HiddenPostView: View {
    let platform: Platform
    let onLongPress: () -> Void

    @GestureState private var pressing = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: platform.sfSymbol)
                .imageScale(.medium)
                .opacity(0.9)
            Image(systemName: "eye.slash.fill")
                .imageScale(.medium)
                .opacity(0.9)
            Text("Post oculto")
                .font(.subheadline.weight(.semibold))
                .opacity(0.95)
            Spacer()
            Text("Segure p/ mostrar")
                .font(.footnote.weight(.medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(minHeight: 44)
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))  // área do gesto
        .scaleEffect(pressing ? 0.98 : 1)
        .animation(.easeInOut(duration: 0.15), value: pressing)
        .simultaneousGesture(                                              // ⬅️ scroll-friendly
            LongPressGesture(minimumDuration: 0.6, maximumDistance: 12)
                .updating($pressing) { _, state, _ in state = true }
                .onEnded { _ in onLongPress() }
        )
    }
}

extension SocialActions {
    func unhideAll() {
        guard !hidden.isEmpty else { return }
        hidden.removeAll()
        UserDefaults.standard.set(Array(hidden), forKey: hiddenKey)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
