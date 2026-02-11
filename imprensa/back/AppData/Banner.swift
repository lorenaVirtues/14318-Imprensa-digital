import SwiftUI
import WebKit
import Combine

struct bannerView: UIViewRepresentable {
    typealias UIViewType = WKWebView
    let webView: WKWebView
    
    func makeUIView(context: Context) -> WKWebView {
        // Garante que as configurações de scroll estejam desabilitadas
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.bouncesZoom = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.zoomScale = 1.0
        webView.scrollView.panGestureRecognizer.isEnabled = false
        webView.scrollView.pinchGestureRecognizer?.isEnabled = false
        
        return webView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        // Garante que o scroll permaneça desabilitado sempre que a view for atualizada
        uiView.scrollView.isScrollEnabled = false
        uiView.scrollView.bounces = false
        uiView.scrollView.bouncesZoom = false
        uiView.scrollView.showsHorizontalScrollIndicator = false
        uiView.scrollView.showsVerticalScrollIndicator = false
        uiView.scrollView.contentInsetAdjustmentBehavior = .never
        uiView.scrollView.minimumZoomScale = 1.0
        uiView.scrollView.maximumZoomScale = 1.0
        uiView.scrollView.zoomScale = 1.0
        uiView.scrollView.panGestureRecognizer.isEnabled = false
        uiView.scrollView.pinchGestureRecognizer?.isEnabled = false
    }
}

class Banner: NSObject, ObservableObject, WKNavigationDelegate {
    let webView: WKWebView
    var radio: String
    var url: URL
    @Published var showBanner: Bool = false  // Flag para controlar se o banner será exibido
    @Published var isLoading: Bool = true  // Flag para controlar o estado de carregamento
    
    init(radio: String) {
        self.radio = radio.isEmpty ? "10223" : radio
        
        // Configuração do dispositivo e montagem da URL
        let deviceType = UIDevice.current.type.rawValue
        var dispositivo = "\(deviceType)"
        let version = UIDevice.current.systemVersion.trimmingCharacters(in: .whitespacesAndNewlines)
        var sistema = String(format: "iOS %@", version)
        sistema = sistema.replacingOccurrences(of: " ", with: "%20")
        dispositivo = dispositivo.replacingOccurrences(of: " ", with: "%20")
        let parameters = String(format: "?radio=%@&formato=html&sistema=%@&plataforma=%@&tipoRel=imp",
                                  self.radio, sistema, dispositivo)
        print("Parâmetros do banner rotativo: \(parameters)")
        url = URL(string: "https://devapi.virtueslab.app/12.1/banner.php\(parameters)")!
        
        // Configuração do WKWebView
        webView = WKWebView(frame: CGRect(x: 0, y: 1150, width: 1024, height: 200))
        super.init()
        
        // Desabilita navegação dentro do frame
        webView.allowsBackForwardNavigationGestures = false
        
        // Desabilita scroll
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.bouncesZoom = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        
        // Configura para exibir conteúdo completo sem zoom
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.zoomScale = 1.0
        
        webView.navigationDelegate = self
        webView.isOpaque = false
        webView.backgroundColor = .clear
        
        // Desabilita interação com gestos (exceto toques)
        webView.scrollView.panGestureRecognizer.isEnabled = false
        webView.scrollView.pinchGestureRecognizer?.isEnabled = false
        
        loadUrl()
    }
    
    func loadUrl() {
        // Garante que o scroll esteja desabilitado antes de carregar
        disableScroll()
        isLoading = true
        showBanner = false
        webView.load(URLRequest(url: url))
    }
    
    /// Método auxiliar para desabilitar scroll e interações
    private func disableScroll() {
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.bouncesZoom = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.zoomScale = 1.0
        webView.scrollView.panGestureRecognizer.isEnabled = false
        webView.scrollView.pinchGestureRecognizer?.isEnabled = false
    }
    
    func updateRadio(_ newRadio: String) {
        guard !newRadio.isEmpty && newRadio != radio else { return }
        radio = newRadio
        
        // Reconstrói a URL com o novo radio
        let deviceType = UIDevice.current.type.rawValue
        var dispositivo = "\(deviceType)"
        let version = UIDevice.current.systemVersion.trimmingCharacters(in: .whitespacesAndNewlines)
        var sistema = String(format: "iOS %@", version)
        sistema = sistema.replacingOccurrences(of: " ", with: "%20")
        dispositivo = dispositivo.replacingOccurrences(of: " ", with: "%20")
        let parameters = String(format: "?radio=%@&formato=html&sistema=%@&plataforma=%@&tipoRel=imp",
                                  radio, sistema, dispositivo)
        print("🔄 [Banner] Parâmetros do banner rotativo atualizados: \(parameters)")
        url = URL(string: "https://devapi.virtueslab.app/12.1/banner.php\(parameters)")!
        
        // Garante que o scroll permaneça desabilitado
        disableScroll()
        
        // Reseta o estado e recarrega
        showBanner = false
        isLoading = true
        loadUrl()
    }
    
    // Delegate para interceptar cliques em links
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let requestURL = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        
        let urlString = requestURL.absoluteString
        
        // Se for um clique em link, sempre abre externamente
        if navigationAction.navigationType == .linkActivated {
            if UIApplication.shared.canOpenURL(requestURL) {
                UIApplication.shared.open(requestURL)
                print("🔗 [Banner] Link aberto externamente: \(urlString)")
                decisionHandler(.cancel) // Cancela a navegação dentro do frame
                return
            }
        }
        
        // Para qualquer outra navegação (incluindo quando retorna do navegador externo),
        // cancela para evitar que a webview se torne navegável
        if navigationAction.navigationType == .backForward ||
           navigationAction.navigationType == .reload ||
           navigationAction.navigationType == .formSubmitted ||
           navigationAction.navigationType == .formResubmitted {
            // Bloqueia silenciosamente - comportamento esperado
            decisionHandler(.cancel)
            return
        }
        
        // Permite apenas o carregamento inicial da URL do banner
        if navigationAction.navigationType == .other {
            // Verifica se é a URL original do banner (banner.php)
            if urlString.contains("banner.php") {
                print("✅ [Banner] Carregando banner inicial")
                decisionHandler(.allow)
                return
            } else {
                // Qualquer outra URL (como links do banner) é bloqueada silenciosamente
                // Isso é comportamento esperado - não queremos carregar links dentro do frame
                decisionHandler(.cancel)
                return
            }
        }
        
        // Por padrão, cancela qualquer outra navegação
        decisionHandler(.cancel)
    }
    
    // Verifica, ao finalizar o carregamento, se há uma imagem válida no banner
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Garante que o scroll permaneça desabilitado após o carregamento
        disableScroll()
        
        // Verifica o tamanho do array "imagem" definido na resposta da API
        webView.evaluateJavaScript("imagem.length") { (result, error) in
            DispatchQueue.main.async {
                self.isLoading = false
                if let count = result as? Int, count > 0 {
                    print("✅ [Banner] Banner com imagens cadastradas: \(count)")
                    self.showBanner = true
                    
                    // Garante que a imagem seja exibida completa e sem scroll
                    // Desabilita qualquer interação de scroll após o carregamento
                    self.disableScroll()
                } else {
                    print("⚠️ [Banner] Nenhuma imagem cadastrada no banner.")
                    self.showBanner = false
                }
            }
        }
    }
    
    // Intercepta quando a navegação falha ou é cancelada
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        // Garante que o scroll permaneça desabilitado mesmo em caso de erro
        disableScroll()
        DispatchQueue.main.async {
            self.isLoading = false
            self.showBanner = false
        }
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        // Garante que o scroll permaneça desabilitado mesmo em caso de erro
        disableScroll()
        DispatchQueue.main.async {
            self.isLoading = false
            self.showBanner = false
        }
    }

}

