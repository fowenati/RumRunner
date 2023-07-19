import SwiftUI
import Combine

import SwiftUI
import Combine

struct Package: Decodable, Identifiable {
    let id: UUID = UUID()
    let name: String
    let versions: [String]?
    var isSelected: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case versions
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        if let versionsData = try? container.decode(Data.self, forKey: .versions),
           let versionsDictionary = try? JSONSerialization.jsonObject(with: versionsData, options: []) as? [String: Any] {
            self.versions = Array(versionsDictionary.keys)
        } else {
            self.versions = nil
        }
    }
}


struct Cask: Decodable, Identifiable {
    let id: UUID = UUID()
    let name: String
    let versions: [String]?
    var isSelected: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id
        case token
        case versions
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .token)
        if let versionsData = try? container.decode(Data.self, forKey: .versions),
           let versionsDictionary = try? JSONSerialization.jsonObject(with: versionsData, options: []) as? [String: Any] {
            self.versions = Array(versionsDictionary.keys)
        } else {
            self.versions = nil
        }
    }
}

struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    var intValue: Int? {
        return nil
    }
    
    init?(intValue: Int) {
        return nil
    }
}
