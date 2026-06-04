import Foundation

struct Profile: Codable, Identifiable, Equatable {
    let name: String
    let email: String
    let active: Bool
    var id: String { name }
}

struct ListResult: Codable, Equatable {
    let active: String?
    let profiles: [Profile]
}

struct WhoAmI: Codable, Equatable {
    let email: String?
}
