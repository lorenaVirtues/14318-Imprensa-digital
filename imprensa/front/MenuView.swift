import SwiftUI

struct MenuView: View {
    let height = UIScreen.main.bounds.size.height
    let onClose: () -> Void
    let onContato: () -> Void
    let onSite: () -> Void
    let onFacebook: () -> Void
    let onInstagram: () -> Void
    let onWhatsapp: () -> Void
    let onAvaliar: () -> Void
    let onCompartilhar: () -> Void
    let onTermos: () -> Void
    
    
    
    var body: some View {
        GeometryReader{ geometry in
            let isPortrait = geometry.size.height > geometry.size.width
            
            if isPortrait {
                portraitLayout(geometry: geometry)
            } else {
                landscapeLayout(geometry: geometry)
            }
        }
    } // fim do body
    
    @ViewBuilder
    private func portraitLayout(geometry: GeometryProxy) -> some View{
        GeometryReader{ geometry in
            ZStack(alignment: .top) {
                Button(action: onClose) {
                    Color.black.opacity(0.01).edgesIgnoringSafeArea(.all)
                }
                
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color("azulEscuro"))
                        .frame(width: UIDevice.current.userInterfaceIdiom == .phone ? UIScreen.main.bounds.size.width*0.7 : UIScreen.main.bounds.size.width*0.4)
                        .edgesIgnoringSafeArea(.all)
                    
                    ScrollView {
                        ZStack {
                            Image("logo")
                                .resizable()
                                .scaledToFit()
                                .padding(.horizontal, (height > 811 && height < 933) ? 60 : 80)
                        }
                        .frame(width: UIDevice.current.userInterfaceIdiom == .phone ? UIScreen.main.bounds.size.width*0.7 : UIScreen.main.bounds.size.width*0.4, alignment: .leading)
                        .padding(.vertical, 40)
                        
                        LazyVStack(spacing: 1) {
                            
                            Button(action: onContato) {
                                HStack {
                                    Image("contato")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: UIDevice.current.userInterfaceIdiom == .phone ? 20 : 30)
                                        .foregroundColor(Color.white)
                                        .padding()
                                    Text("Fale Conosco")
                                        .foregroundColor(.white)
                                        .font(.custom("Oxanium-ExtraLight", size: UIDevice.current.userInterfaceIdiom == .phone ? 17 : 22))
                                    Spacer()
                                }
                            }
                           
                            Button(action: onSite) {
                                HStack {
                                    Image(systemName: "network")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: UIDevice.current.userInterfaceIdiom == .phone ? 20 : 30)
                                        .foregroundColor(Color.white)
                                        .padding()
                                    Text("Website")
                                        .foregroundColor(.white)
                                        .font(.custom("Oxanium-ExtraLight", size: UIDevice.current.userInterfaceIdiom == .phone ? 17 : 22))
                                    Spacer()
                                }
                            }
                            
                            HStack {
                                Text("Redes Sociais")
                                    .foregroundColor(.white)
                                    .font(.custom("Oxanium-ExtraLight", size: UIDevice.current.userInterfaceIdiom == .phone ? 14 : 19))
                                    .padding()
                                Spacer()
                            }
                            
                            Divider()
                                .padding(.horizontal, 10)
                            
                            
                            Button(action: onInstagram) {
                                HStack {
                                    Image("instagram-fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: UIDevice.current.userInterfaceIdiom == .phone ? 20 : 40)
                                        .foregroundColor(Color.white)
                                        .padding()
                                    Text("Instagram")
                                        .foregroundColor(.white)
                                        .font(.custom("Oxanium-ExtraLight", size: UIDevice.current.userInterfaceIdiom == .phone ? 17 : 22))
                                    Spacer()
                                }
                            }
                            
                            Button {
                                onFacebook()
                            } label: {
                                HStack {
                                    Image("facebook-circle-fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: UIDevice.current.userInterfaceIdiom == .phone ? 20 : 40)
                                        .foregroundColor(Color.white)
                                        .padding()
                                    Text("Facebook")
                                        .foregroundColor(.white)
                                        .font(.custom("Oxanium-ExtraLight", size: UIDevice.current.userInterfaceIdiom == .phone ? 17 : 22))
                                    Spacer()
                                }
                            }
                            
                            Button {
                                onWhatsapp()
                            } label: {
                                HStack {
                                    Image("whatsapp-circle-fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: UIDevice.current.userInterfaceIdiom == .phone ? 20 : 40)
                                        .foregroundColor(Color.white)
                                        .padding()
                                    Text("Whatsapp")
                                        .foregroundColor(.white)
                                        .font(.custom("Oxanium-ExtraLight", size: UIDevice.current.userInterfaceIdiom == .phone ? 17 : 22))
                                    Spacer()
                                }
                            }
                            
                            HStack {
                                Text("Mais Informações")
                                    .foregroundColor(.white)
                                    .font(.custom("Oxanium-ExtraLight", size: UIDevice.current.userInterfaceIdiom == .phone ? 14 : 19))
                                    .padding()
                                Spacer()
                            }
                            
                            Divider()
                                .padding(.horizontal, 10)
                            
                            Button(action: onAvaliar) {
                                HStack {
                                    Image("star-fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: UIDevice.current.userInterfaceIdiom == .phone ? 20 : 40)
                                        .foregroundColor(Color.white)
                                        .padding()
                                    Text("Avaliar")
                                        .foregroundColor(.white)
                                        .font(.custom("Oxanium-ExtraLight", size: UIDevice.current.userInterfaceIdiom == .phone ? 17 : 22))
                                    Spacer()
                                }
                            }
                            
                            Button(action: onCompartilhar) {
                                HStack {
                                    Image("share-fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: UIDevice.current.userInterfaceIdiom == .phone ? 25 : 55)
                                        .foregroundColor(Color.white)
                                        .padding()
                                    Text("Compartilhar")
                                        .foregroundColor(.white)
                                        .font(.custom("Oxanium-ExtraLight", size: UIDevice.current.userInterfaceIdiom == .phone ? 17 : 22))
                                    Spacer()
                                }
                            }
                            
                            Button(action: onTermos) {
                                HStack {
                                    Image("shield-fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: UIDevice.current.userInterfaceIdiom == .phone ? 20 : 40)
                                        .foregroundColor(Color.white)
                                        .padding()
                                    Text("Termos & Políticas")
                                        .foregroundColor(.white)
                                        .font(.custom("Oxanium-ExtraLight", size: UIDevice.current.userInterfaceIdiom == .phone ? 17 : 22))
                                    Spacer()
                                }
                            }
                            
                        }//VStack
                    }
                    .frame(width: UIDevice.current.userInterfaceIdiom == .phone ? UIScreen.main.bounds.size.width*0.7 : UIScreen.main.bounds.size.width*0.4, alignment: .leading)
                }
                .frame(width: UIScreen.main.bounds.size.width, alignment: .leading)
                
            }
        }
    }//fim do portrait
    
    @ViewBuilder
    private func landscapeLayout(geometry: GeometryProxy) -> some View{
        GeometryReader{ geometry in
            ZStack(alignment: .leading) {
                Button(action: onClose) {
                    Color.black.opacity(0.01).edgesIgnoringSafeArea(.all)
                }
                Rectangle()
                    .fill(Color("azulEscuro"))
                    .frame(width: UIDevice.current.userInterfaceIdiom == .phone ? UIScreen.main.bounds.size.width*0.4 : UIScreen.main.bounds.size.width*0.4)
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    ZStack {
                        Image("logo")
                            .resizable()
                            .scaledToFit()
                            .padding(.horizontal, (height > 811 && height < 933) ? 60 : 80)
                    }
                    .frame(width: UIDevice.current.userInterfaceIdiom == .phone ? UIScreen.main.bounds.size.width*0.4 : UIScreen.main.bounds.size.width*0.4, alignment: .leading)
                    .padding(.vertical, 40)
                    
                    LazyVStack(spacing: 1) {
                        
                        
                        Button(action: onContato) {
                            HStack {
                                Image("contato-fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: UIDevice.current.userInterfaceIdiom == .phone ? 20 : 30)
                                    .foregroundColor(Color(.yellow))
                                    .padding()
                                Text("Fale Conosco")
                                    .foregroundColor(.white)
                                    .font(.custom("Oxanium-ExtraLight", size: UIDevice.current.userInterfaceIdiom == .phone ? 17 : 22))
                                Spacer()
                            }
                        }
                        
                        Button(action: onSite) {
                            HStack {
                                Image(systemName: "network")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: UIDevice.current.userInterfaceIdiom == .phone ? 20 : 30)
                                    .foregroundColor(Color(.yellow))
                                    .padding()
                                Text("Website")
                                    .foregroundColor(.white)
                                    .font(.custom("Oxanium-ExtraLight", size: UIDevice.current.userInterfaceIdiom == .phone ? 17 : 22))
                                Spacer()
                            }
                        }
                        
                        HStack {
                            Text("Redes Sociais")
                                .foregroundColor(.white)
                                .font(.custom("Oxanium-ExtraLight", size: UIDevice.current.userInterfaceIdiom == .phone ? 14 : 19))
                                .padding()
                            Spacer()
                        }
                        
                        Divider()
                            .padding(.horizontal, 10)
                        
                        
                        Button(action: onInstagram) {
                            HStack {
                                Image("Instagram")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: UIDevice.current.userInterfaceIdiom == .phone ? 20 : 40)
                                    .padding()
                                Text("Instagram")
                                    .foregroundColor(.white)
                                    .font(.custom("Oxanium-ExtraLight", size: UIDevice.current.userInterfaceIdiom == .phone ? 17 : 22))
                                Spacer()
                            }
                        }
                        
                        Button {
                            onFacebook()
                        } label: {
                            HStack {
                                Image("Facebook")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: UIDevice.current.userInterfaceIdiom == .phone ? 20 : 40)
                                    .padding()
                                Text("Facebook")
                                    .foregroundColor(.white)
                                    .font(.custom("Oxanium-ExtraLight", size: UIDevice.current.userInterfaceIdiom == .phone ? 17 : 22))
                                Spacer()
                            }
                        }
                        
                        Button {
                            onWhatsapp()
                        } label: {
                            HStack {
                                Image("WhatsApp")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: UIDevice.current.userInterfaceIdiom == .phone ? 20 : 40)
                                    .padding()
                                Text("Whatsapp")
                                    .foregroundColor(.white)
                                    .font(.custom("Oxanium-ExtraLight", size: UIDevice.current.userInterfaceIdiom == .phone ? 17 : 22))
                                Spacer()
                            }
                        }
                        
                        HStack {
                            Text("Mais Informações")
                                .foregroundColor(.white)
                                .font(.custom("Oxanium-ExtraLight", size: UIDevice.current.userInterfaceIdiom == .phone ? 14 : 19))
                                .padding()
                            Spacer()
                        }
                        
                        Divider()
                            .padding(.horizontal, 10)
                        
                        Button(action: onAvaliar) {
                            HStack {
                                Image(systemName: "star.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: UIDevice.current.userInterfaceIdiom == .phone ? 20 : 40)
                                    .foregroundColor(Color(.yellow))
                                    .padding()
                                Text("Avaliar")
                                    .foregroundColor(.white)
                                    .font(.custom("Oxanium-ExtraLight", size: UIDevice.current.userInterfaceIdiom == .phone ? 17 : 22))
                                Spacer()
                            }
                        }
                        
                        Button(action: onCompartilhar) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: UIDevice.current.userInterfaceIdiom == .phone ? 25 : 55)
                                    .foregroundColor(Color(.yellow))
                                    .padding()
                                Text("Compartilhar")
                                    .foregroundColor(.white)
                                    .font(.custom("Oxanium-ExtraLight", size: UIDevice.current.userInterfaceIdiom == .phone ? 17 : 22))
                                Spacer()
                            }
                        }
                        
                        Button(action: onTermos) {
                            HStack {
                                Image(systemName: "shield.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: UIDevice.current.userInterfaceIdiom == .phone ? 20 : 40)
                                    .foregroundColor(Color(.yellow))
                                    .padding()
                                Text("Termos & Políticas")
                                    .foregroundColor(.white)
                                    .font(.custom("Oxanium-ExtraLight", size: UIDevice.current.userInterfaceIdiom == .phone ? 17 : 22))
                                Spacer()
                            }
                        }
                        
                    }//VStack
                }
                .frame(width: UIDevice.current.userInterfaceIdiom == .phone ? UIScreen.main.bounds.size.width*0.4 : UIScreen.main.bounds.size.width*0.4, alignment: .leading)
            }
            .frame(width: UIScreen.main.bounds.size.width, alignment: .leading)
        }
    }//fim do landscape
   
} //fim da menu view
