import SwiftUI
import GoogleCast

struct CastButton: UIViewControllerRepresentable {
    func makeUIViewController(context: UIViewControllerRepresentableContext<CastButton>) -> UIViewController {
        let castButton = GCKUICastButton(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        
        // Torna o botão completamente invisível
        castButton.tintColor = .clear  // Remove a cor do ícone
        castButton.backgroundColor = .clear  // Torna o fundo do botão transparente
        castButton.isHidden = true  // Torna o botão invisível e não interativo
        
        // Cria um UIViewController para encapsular o castButton
        let viewController = UIViewController()
        viewController.view = castButton
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<CastButton>) {
        // Atualizar o estado do botão se necessário
    }
}
