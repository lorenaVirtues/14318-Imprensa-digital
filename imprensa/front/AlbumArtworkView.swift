import SwiftUI

/// Reusable view for album artwork with consistent masking and fallback logic.
struct AlbumArtworkView: View {
    var artwork: UIImage? = nil
    var artworkURL: String? = nil
    var maskImageName: String
    var fallbackImageName: String = "live"
    
    var body: some View {
        ZStack {
            // Main Artwork
            if let artwork = artwork {
                Image(uiImage: artwork)
                    .resizable()
                    .scaledToFill()
            } else if let urlStr = artworkURL, !urlStr.isEmpty {
                if urlStr.contains("http") {
                    // Remote Image
                    AsyncImage(url: URL(string: urlStr)) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill()
                        } else {
                            Image(fallbackImageName)
                                .resizable()
                                .scaledToFill()
                        }
                    }
                } else {
                    // Local Image (from Documents)
                    if let uiImage = loadLocalImage(named: urlStr) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(fallbackImageName)
                            .resizable()
                            .scaledToFill()
                    }
                }
            } else {
                // No artwork provided, show fallback
                Image(fallbackImageName)
                    .resizable()
                    .scaledToFill()
            }
        }
        .mask(
            Image(maskImageName)
                .resizable()
                .scaledToFit()
        )
    }
    
    private func loadLocalImage(named name: String) -> UIImage? {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let fileURL = documentsURL.appendingPathComponent(name)
        return UIImage(contentsOfFile: fileURL.path)
    }
}
