import SwiftUI

struct SobreView: View {
    @EnvironmentObject var router: NavigationRouter
    
    var body: some View {
        Color("azulEscuro")
            .edgesIgnoringSafeArea(.bottom)
        
        ZStack {
            Color.white
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
                        
                        // "Developed by:" Section
                        VStack(spacing: 12) {
                            Text("Developed by:")
                                .font(.custom("Spartan-Regular", size: 16))
                                .foregroundColor(.black)
                            
                            Image("virtues2")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 70)
                            
                            VStack(spacing: 5) {
                                Text("Virtues Technology")
                                    .font(.custom("Spartan-Bold", size: 21))
                                    .foregroundColor(Color(red: 26/255, green: 60/255, blue: 104/255))
                                
                                Link("www.virtues.ag", destination: URL(string: "https://www.virtues.ag")!)
                                    .font(.custom("Spartan-Bold", size: 13))
                                    .foregroundColor(Color(red: 26/255, green: 60/255, blue: 104/255))
                            }
                            
                            HStack(spacing: 5) {
                                Text("Contato:")
                                    .font(.custom("Spartan-Regular", size: 15))
                                    .foregroundColor(.black)
                                
                                Link("comercial@virtues.ag", destination: URL(string: "mailto:comercial@virtues.ag")!)
                                    .font(.custom("Spartan-Bold", size: 15))
                                    .foregroundColor(Color(red: 26/255, green: 60/255, blue: 104/255))
                            }
                        }
                        .padding(.top, 15)
                        
                        // Disclaimer Box
                        VStack(spacing: 20) {
                            Text("A responsabilidade pelo uso e supervisão dos conteúdos publicados/inseridos é de total compromisso/dever dos usuários e administradores do Aplicativo.")
                                .font(.custom("Spartan-Bold", size: 14))
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                            
                            Text("Em caso de dúvidas, sugestão, reclamação, suporte, novas funcionalidades e/ou qualquer inquietude entrar em contato pelos nossos canais de relacionamento.")
                                .font(.custom("Spartan-Bold", size: 14))
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                        .padding(25)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color(red: 26/255, green: 60/255, blue: 104/255), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                        
                        // Bottom Section
                        VStack(spacing: 8) {
                            Text("Product APPRADIO.PRO @ 2025")
                                .font(.custom("Spartan-SemiBold", size: 17))
                                .foregroundColor(Color(red: 26/255, green: 60/255, blue: 104/255))
                            
                            HStack(spacing: 5) {
                                Text("Site:")
                                    .font(.custom("Spartan-Regular", size: 14))
                                    .foregroundColor(.gray)
                                Link("www.appradio.pro", destination: URL(string: "https://www.appradio.pro")!)
                                    .font(.custom("Spartan-Bold", size: 14))
                                    .foregroundColor(Color(red: 26/255, green: 60/255, blue: 104/255))
                            }
                            
                            Text("Version: \(Bundle.main.appVersion)")
                                .font(.custom("Spartan-Regular", size: 14))
                                .foregroundColor(.gray)
                        }
                        .padding(.bottom, 140) // Extra padding for back button
                    }
                }
                
                if UIDevice.current.userInterfaceIdiom == .phone {
                    
                } else {
                    Spacer()
                }
            }
            
            // Bottom Left Back Button
            VStack {
                Spacer()
                HStack {
                    Button(action: {
                        router.backTopLevel()
                    }) {
                        Image("btn_return")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100)
                    }
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.light)
    }
    
    // MARK: - Components
    
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
