//
//  Chat.swift
//  VertexFirebaseSwiftUI
//
//  Created by Anup D'Souza on 16/05/24.
//  🕸️ https://www.anupdsouza.com
//  🔗 https://twitter.com/swift_odyssey
//  👨🏻‍💻 https://github.com/anupdsouza
//  ☕️ https://www.buymeacoffee.com/anupdsouza
//

import Foundation
import UIKit

enum ChatRole {
    case user
    case aiModel
}

struct Media {
    let mimeType: String
    let data: Data
    let thumbnail: UIImage
}

struct ChatMessage: Identifiable, Equatable {
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id
    }
    
    let id = UUID().uuidString
    let role: ChatRole
    let message: String
    let media: [Media]?
}
