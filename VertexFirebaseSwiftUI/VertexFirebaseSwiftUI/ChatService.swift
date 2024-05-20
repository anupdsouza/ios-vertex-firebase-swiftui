//
//  ChatService.swift
//  VertexFirebaseSwiftUI
//
//  Created by Anup D'Souza on 16/05/24.
//  🕸️ https://www.anupdsouza.com
//  🔗 https://twitter.com/swift_odyssey
//  👨🏻‍💻 https://github.com/anupdsouza
//  ☕️ https://www.buymeacoffee.com/anupdsouza
//

import Foundation
import FirebaseVertexAI
import SwiftUI

@Observable class ChatService {
    private var model = VertexAI.vertexAI().generativeModel(modelName: "gemini-1.5-pro-preview-0409")
    private(set) var messages = [ChatMessage]()
    private(set) var loadingResponse = false
    
    func sendMessage(message: String, media: [Media]) async {
        loadingResponse = true
        
        messages.append(.init(role: .user, message: message, media: media))
        messages.append(.init(role: .aiModel, message: "", media: nil))
        
        do {
            var chatMedia = [any ThrowingPartsRepresentable]()
            for mediaItem in media {
                if mediaItem.mimeType == "video/mp4" {
                    chatMedia.append(ModelContent.Part.data(mimetype: mediaItem.mimeType, mediaItem.data))
                } else {
                    chatMedia.append(ModelContent.Part.jpeg(mediaItem.data))
                }
            }
            
            let response = try await model.generateContent(message, chatMedia)
            
            loadingResponse = false
            
            guard let text = response.text else {
                messages.append(.init(role: .aiModel, message: "Something went wrong, please try again", media: nil))
                return
            }
            
            messages.removeLast()
            messages.append(.init(role: .aiModel, message: text, media: nil))
        }
        catch {
            loadingResponse = false
            messages.removeLast()
            messages.append(.init(role: .aiModel, message: "Something went wrong, please try again", media: nil))
            print(error.localizedDescription)
        }
    }
}
