import Foundation
import Combine

struct AppData: Codable, Equatable {
    let app: AppInfo
}

struct AppInfo: Codable, Equatable {
    let id: String
    let nome: String
    let site: String
    let ativo: String
    let privacy: String
    let share: String
    let erro: ErrorInfo
    let radios: [Radio]
}

struct ErrorInfo: Codable, Equatable {
    let codigo: String
    let descricao: String
}

struct Radio: Codable, Equatable {
    let id: String
    let nome: String
    let site: String
    let streaming: String
    let redundancia: String
    let video: String
    let sociais: [Social]
}

struct Social: Codable, Equatable {
    let tipo: String
    let link: String
    let scheme: String
    let rotulo: String
}

class AppDataController: NSObject, ObservableObject {
    @Published var appData: AppData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lottieControl: LottieControlCenter?
    @Published var minimalMode = false {
        didSet {
            lottieControl?.pauseAll = minimalMode
        }
    }

     func parseAppData() {
         let urlServidor: String = "https://devapi.virtueslab.app"
         let urlServico: String = "appradio"
         let urlVersao: String = "12.1"
         let urlAppData = String("\(urlServidor)/\(urlVersao)/\(urlServico).php?APPID=14318&token=3809174946973661a4877a8.58525175")
         guard let url = URL(string: urlAppData) else {
             errorMessage = "URL inválida"
             return
        }
         isLoading = true
         errorMessage = nil
         
         URLSession.shared.dataTask(with: url) { data, response, error in
             DispatchQueue.main.async {
                 self.isLoading = false
                 if let error = error {
                     self.errorMessage = "Erro: \(error.localizedDescription)"
                     return
                 }
                 guard let data = data else {
                     self.errorMessage = "Nenhum dado recebido"
                     return
                 }
                 //let decoder = JSONDecoder()
                 do {
                     var radiosA : [Radio] = []
                     var sociaisA : [Social] = []
                     let jsonResponse = try JSON(data: data)
                     let identificador = jsonResponse["app"]["id"].stringValue
                     let nome = jsonResponse["app"]["nome"].stringValue
                     let site = jsonResponse["app"]["site"].stringValue
                     let ativo = jsonResponse["app"]["ativo"].stringValue
                     let privacy = jsonResponse["app"]["privacy"].stringValue
                     let share = jsonResponse["app"]["share"].stringValue
                     let erroCodigo = jsonResponse["app"]["erro"]["codigo"].stringValue
                     let erroDescricao = jsonResponse["app"]["erro"]["descricao"].stringValue
                     let erro = ErrorInfo(codigo: erroCodigo, descricao: erroDescricao)
                     let radiosArray = jsonResponse["app"]["radios"].arrayValue
                     for aRadios in radiosArray {
                         let identificador = aRadios["id"].stringValue
                         let nome = aRadios["nome"].stringValue
                         let site = aRadios["site"].stringValue
                         let streaming = aRadios["streaming"].stringValue
                         let redundancia = aRadios["redundancia"].stringValue
                         let video = aRadios["video"].stringValue
                         let sociaisArray = aRadios["sociais"].arrayValue
                         for aSociais in sociaisArray {
                             let tipo = aSociais["tipo"].stringValue
                             let link = aSociais["link"].stringValue
                             let scheme = aSociais["scheme"].stringValue
                             let rotulo = aSociais["rotulo"].stringValue
                             let sociais = Social(tipo: tipo, link: link, scheme: scheme, rotulo: rotulo)
                             sociaisA.append(sociais)
                         }
                         radiosA.append(Radio(id: identificador, nome: nome, site: site, streaming: streaming, redundancia: redundancia, video: video, sociais: sociaisA))
                     }
                     let aplicativo = AppData(app: AppInfo(id: identificador, nome: nome, site: site, ativo: ativo, privacy: privacy, share: share,erro: erro, radios: radiosA))
                     
                     DispatchQueue.main.async {
                         print(aplicativo)
                         self.appData = aplicativo
                     }
                 } catch {
                     self.errorMessage = "Falha ao decodificar JSON: \(error)"
                 }
             }
         }.resume()
    }
}
