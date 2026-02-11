import Foundation

struct DDIInfo: Identifiable {
    let id = UUID()
    let code: String
    let country: String
    let flag: String
    let placeholder: String
}

let DDIList: [DDIInfo] = [
    DDIInfo(code: "+55", country: "Brasil", flag: "🇧🇷", placeholder: "(00) 00000-0000"),
    DDIInfo(code: "+52", country: "Mexico",        flag: "🇲🇽", placeholder: "(00) 0000-0000"),
    DDIInfo(code: "+54", country: "Argentina",     flag: "🇦🇷", placeholder: "(00) 0000-0000"),
    DDIInfo(code: "+56", country: "Chile",         flag: "🇨🇱", placeholder: "0 0000 0000"),
    DDIInfo(code: "+57", country: "Colombia",      flag: "🇨🇴", placeholder: "000 000 0000"),
    DDIInfo(code: "+58", country: "Venezuela",     flag: "🇻🇪", placeholder: "0000-0000000"),
    DDIInfo(code: "+51", country: "Peru",          flag: "🇵🇪", placeholder: "000 000 000"),
    DDIInfo(code: "+593",country: "Ecuador",       flag: "🇪🇨", placeholder: "000 000 0000"),
    DDIInfo(code: "+591",country: "Bolivia",       flag: "🇧🇴", placeholder: "00000000"),
    DDIInfo(code: "+595",country: "Paraguay",      flag: "🇵🇾", placeholder: "0000 000 000"),
    DDIInfo(code: "+598",country: "Uruguai",       flag: "🇺🇾", placeholder: "000 000 000"),
    DDIInfo(code: "+505",country: "Nicaragua",     flag: "🇳🇮", placeholder: "0 0000-0000"),
    DDIInfo(code: "+504",country: "Honduras",      flag: "🇭🇳", placeholder: "0000-0000"),
    DDIInfo(code: "+503",country: "El Salvador",  flag: "🇸🇻", placeholder: "0000-0000"),
    DDIInfo(code: "+506",country: "Costa Rica",    flag: "🇨🇷", placeholder: "0000-0000"),
    DDIInfo(code: "+507",country: "Panama",        flag: "🇵🇦", placeholder: "0000-0000"),
    DDIInfo(code: "+502",country: "Guatemala",     flag: "🇬🇹", placeholder: "0000-0000"),
    DDIInfo(code: "+501",country: "Belize",        flag: "🇧🇿", placeholder: "00000"),
    DDIInfo(code: "+592",country: "Guyana",        flag: "🇬🇾", placeholder: "0000000"),
    DDIInfo(code: "+597",country: "Suriname",      flag: "🇸🇷", placeholder: "0000000"),

    DDIInfo(code: "+1", country: "Estados Unidos", flag: "🇺🇸", placeholder: "(000) 000-0000"),
    DDIInfo(code: "+1", country: "Canadá",         flag: "🇨🇦", placeholder: "(000) 000-0000"),

    DDIInfo(code: "+44",country: "Reino Unido",   flag: "🇬🇧", placeholder: "00000 000000"),
    DDIInfo(code: "+49",country: "Alemanha",       flag: "🇩🇪", placeholder: "0000 0000000"),
    DDIInfo(code: "+33",country: "França",         flag: "🇫🇷", placeholder: "00 00 00 00 00"),
    DDIInfo(code: "+39",country: "Itália",         flag: "🇮🇹", placeholder: "000 0000000"),
    DDIInfo(code: "+34",country: "Espanha",        flag: "🇪🇸", placeholder: "000 00 00 00"),
]
