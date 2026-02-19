import Foundation

/// Serviço para buscar músicas no YouTube via API interna.
class YouTubeSearchService: ObservableObject {
    @Published var results: [SongModel] = []
    @Published var isSearching = false
    @Published var errorMessage: String?
    
    // URL da API do iTunes para busca de músicas
    private let itunesSearchURL = "https://itunes.apple.com/search"
    
    func search(query: String) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            DispatchQueue.main.async { self.results = [] }
            return
        }
        
        DispatchQueue.main.async {
            self.isSearching = true
            self.errorMessage = nil
        }
        
        var comps = URLComponents(string: itunesSearchURL)!
        comps.queryItems = [
            URLQueryItem(name: "term", value: query),
            URLQueryItem(name: "entity", value: "song"),
            URLQueryItem(name: "limit", value: "25"),
            URLQueryItem(name: "country", value: "BR")
        ]
        
        guard let url = comps.url else {
            DispatchQueue.main.async {
                self.isSearching = false
                self.errorMessage = "Erro ao criar URL de busca"
            }
            return
        }
        
        print("🔍 [YouTubeSearch] Buscando no iTunes: \(url.absoluteString)")
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSON(data: data)
            
            var newResults: [SongModel] = []
            
            // O iTunes retorna os resultados em um array chamado 'results'
            let resultsArray = json["results"].arrayValue
            
            for item in resultsArray {
                let title = item["trackName"].stringValue
                let artist = item["artistName"].stringValue
                // Pega a capa de 100x100 e tenta aumentar para 600x600 para melhor qualidade
                let image = item["artworkUrl100"].stringValue.replacingOccurrences(of: "100x100", with: "600x600")
                
                if !title.isEmpty {
                    let song = SongModel(
                        title: title,
                        artist: artist,
                        date: {
                            let f = DateFormatter()
                            f.dateFormat = "dd/MM/yyyy"
                            return f.string(from: Date())
                        }(),
                        imageUrl: image
                    )
                    newResults.append(song)
                }
            }
            
            DispatchQueue.main.async {
                self.results = newResults
                self.isSearching = false
                if newResults.isEmpty {
                    self.errorMessage = "Nenhum resultado encontrado para \"\(query)\""
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isSearching = false
                self.errorMessage = "Falha na busca pela web: \(error.localizedDescription)"
            }
        }
    }
}
