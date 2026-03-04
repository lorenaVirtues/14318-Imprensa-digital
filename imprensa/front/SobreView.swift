import SwiftUI
import UIKit

// MARK: - Theme (cores aproximadas da arte)
enum AppTheme {
    static let deepBlue  = Color(red: 11/255, green: 37/255, blue: 63/255)      // #0B253F (fundo de baixo)
    static let brandBlue = Color(red: 69/255, green: 99/255, blue: 131/255)     // #456383 (azul dos textos/borda)
    static let softGray  = Color(red: 116/255, green: 116/255, blue: 116/255)   // cinza do “Developed by/Contato”
    static let lightGray = Color(red: 149/255, green: 149/255, blue: 149/255)   // cinza do “Site/Version”
    static let textBlack = Color(red: 28/255, green: 28/255, blue: 28/255)      // preto suave (arte)
}

// MARK: - Modifier de Fonte (compatível iOS 13+)
struct SpartanText: ViewModifier {
    enum Style { case regular, semibold, bold }
    let style: Style
    let size: CGFloat
    let color: Color
    let kerning: CGFloat

    func body(content: Content) -> some View {
        content
            .font(.custom(fontName, size: size))
            .foregroundColor(color)
    }

    private var fontName: String {
        switch style {
        case .regular: return "Spartan-Regular"
        case .semibold: return "Spartan-SemiBold"
        case .bold: return "Spartan-Bold"
        }
    }
}

extension View {
    func spartan(_ style: SpartanText.Style, _ size: CGFloat, _ color: Color, kerning: CGFloat = 0.0) -> some View {
        self.modifier(SpartanText(style: style, size: size, color: color, kerning: kerning))
    }
}

// MARK: - Link sublinhado + cor (compatível iOS 13+)
struct UnderlinedLinkText: View {
    let title: String
    let url: URL
    let fontName: String
    let size: CGFloat
    let color: Color

    var body: some View {
        Link(destination: url) {
            Text(title)
                .font(.custom(fontName, size: size))
                .foregroundColor(color)
                .overlay(
                    Rectangle()
                        .fill(color)
                        .frame(height: 1),
                    alignment: .bottom
                )
                .padding(.bottom, 1) // dá espaço pro “underline”
        }
    }
}

// MARK: - Debug de fontes (pra confirmar se não está em fallback)
@inline(__always)
func debugFonts() {
    ["Spartan-Regular", "Spartan-Bold", "Spartan-SemiBold"].forEach { name in
        print("[FONT]", name, "=>", UIFont(name: name, size: 16) != nil ? "OK" : "NIL (fallback)")
    }
}

// MARK: - SobreView
struct SobreView: View {
    @EnvironmentObject var router: NavigationRouter

    var body: some View {
        ZStack {
            // Fundo azul inferior (igual arte)
            AppTheme.deepBlue.ignoresSafeArea()

            // Conteúdo branco por cima
            ZStack {
                Color.white.ignoresSafeArea()

                VStack(spacing: 0) {

                    // Header
                    headerView

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 30) {

                            // Developed by
                            VStack(spacing: 12) {
                                Text("Developed by:")
                                    .spartan(.regular, 16, AppTheme.textBlack, kerning: 0.2)

                                Image("virtues2")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 70)

                                VStack(spacing: 5) {
                                    Text("Virtues Technology")
                                        .spartan(.regular, 21, AppTheme.textBlack, kerning: 0.1)

                                    UnderlinedLinkText(
                                        title: "www.virtues.ag",
                                        url: URL(string: "https://www.virtues.ag")!,
                                        fontName: "Spartan-Bold",
                                        size: 13,
                                        color: AppTheme.brandBlue
                                    )
                                }

                                HStack(spacing: 5) {
                                    Text("Contato:")
                                        .spartan(.regular, 15, AppTheme.textBlack, kerning: 0.1)

                                    UnderlinedLinkText(
                                        title: "comercial@virtues.ag",
                                        url: URL(string: "mailto:comercial@virtues.ag")!,
                                        fontName: "Spartan-Bold",
                                        size: 15,
                                        color: AppTheme.brandBlue
                                    )
                                }

                            }
                            .padding(.top, 15)

                            // Disclaimer Box
                            VStack(spacing: 20) {
                                Text("A responsabilidade pelo uso e supervisão dos conteúdos publicados/inseridos é de total compromisso/dever dos usuários e administradores do Aplicativo.")
                                    .spartan(.bold, 13, AppTheme.textBlack, kerning: 0.0)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(4)

                                Text("Em caso de dúvidas, sugestão, reclamação, suporte, novas funcionalidades e/ou qualquer inquietude entrar em contato pelos nossos canais de relacionamento.")
                                    .spartan(.bold, 13, AppTheme.textBlack, kerning: 0.0)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(4)
                            }
                            .padding(25)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(AppTheme.brandBlue, lineWidth: 1)
                            )
                            .padding(.horizontal, 20)

                            // Bottom Section
                            VStack(spacing: 8) {
                                Text("Product APPRADIO.PRO © 2025")
                                    .spartan(.semibold, 17, AppTheme.textBlack, kerning: 0.1)

                                HStack(spacing: 5) {
                                    Text("Site:")
                                        .spartan(.regular, 14, AppTheme.textBlack, kerning: 0.0)

                                    UnderlinedLinkText(
                                        title: "www.appradio.pro",
                                        url: URL(string: "https://www.appradio.pro")!,
                                        fontName: "Spartan-Bold",
                                        size: 14,
                                        color: AppTheme.brandBlue
                                    )
                                }

                                // IMPORTANTE:
                                // Você já tem appVersion no seu projeto, então mantive como estava no seu código original:
                                Text("Version: \(Bundle.main.appVersion)")
                                    .spartan(.regular, 14, AppTheme.textBlack, kerning: 0.0)
                            }
                            .padding(.bottom, 140) // espaço pro botão voltar
                        }
                    }

                    // iPad: mantém o fundo azul aparecendo melhor
                    if UIDevice.current.userInterfaceIdiom != .phone {
                        Spacer()
                    }
                }

                // Back Button (canto inferior esquerdo)
                VStack {
                    Spacer()
                    HStack {
                        Button {
                            router.go(to: .menu)
                        } label: {
                            Image("btn_return")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100)
                        }
                        Spacer()
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.light)
        .onAppear {
            debugFonts() // se der NIL em algum, a fonte está em fallback
        }
    }

    // MARK: - Header
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                Image("bg_header_title_about_us")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160)
                    .padding(.leading)

                Spacer()

                HeaderDateTimeView()
                    .padding(.trailing, 20)
            }
            .padding(.top, 40)
            .padding(.bottom, 15)

            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
                .padding(.horizontal, 20)
                .padding(.top, 5)
        }
    }
}
