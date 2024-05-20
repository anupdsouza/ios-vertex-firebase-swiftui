//
//  ContentView.swift
//  VertexFirebaseSwiftUI
//
//  Created by Anup D'Souza on 16/05/24.
//  🕸️ https://www.anupdsouza.com
//  🔗 https://twitter.com/swift_odyssey
//  👨🏻‍💻 https://github.com/anupdsouza
//  ☕️ https://www.buymeacoffee.com/anupdsouza
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var textInput = ""
    @State private var chatService = ChatService()
    @State private var photoPickerItems = [PhotosPickerItem]()
    @State private var selectedMedia = [Media]()
    
    var body: some View {
        VStack {
            Image(.geminiStarLogo)
                .resizable()
                .scaledToFit()
                .frame(width: 50)
            
            // MARK: Chat message list
            ScrollViewReader(content: { proxy in
                ScrollView {
                    ForEach(chatService.messages) { message in
                        // MARK: Chat message view
                        chatMessageView(message)
                            .id(message.id)
                    }
                }
                .onChange(of: chatService.messages) { oldValue, newValue in
                    guard let recentMessage = chatService.messages.last else { return }
                    DispatchQueue.main.async {
                        withAnimation {
                            proxy.scrollTo(recentMessage.id, anchor: .bottom)
                        }
                    }
                }
            })
            
            // MARK: Image preview
            if selectedMedia.count > 0 {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 10, content: {
                        ForEach(0..<selectedMedia.count, id: \.self) { index in
                            Image(uiImage: selectedMedia[index].thumbnail)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                    })
                }
                .frame(height: 50)
            }
            
            // MARK: Input fields
            HStack {
                PhotosPicker(selection: $photoPickerItems,
                             maxSelectionCount: 2,
                             matching: .any(of: [.images, .videos])) {
                    Image(systemName: "photo.stack.fill")
                        .frame(width: 40, height: 25)
                }.onChange(of: photoPickerItems) { oldValue, newValue in
                    Task {
                        selectedMedia.removeAll()
                        for item in photoPickerItems {
                            do {
                                let (mimeType, data, thumbnail) = try await ThumbnailService().processPhotoPickerItem(for: item)
                                selectedMedia.append(.init(mimeType: mimeType, data: data, thumbnail: thumbnail))
                            } catch {
                                print(error.localizedDescription)
                            }
                        }
                    }
                }
                
                TextField("Enter a message...", text: $textInput)
                    .textFieldStyle(.roundedBorder)
                    .foregroundStyle(.black)
                
                if chatService.loadingResponse {
                    ProgressView()
                        .tint(Color.white)
                        .frame(width: 30)
                } else {
                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "paperplane.fill")
                    }
                    .frame(width: 30)
                }
            }
        }
        .foregroundStyle(.white)
        .padding()
        .background {
            Color.black.ignoresSafeArea()
        }
    }
    
    @ViewBuilder private func chatMessageView(_ message: ChatMessage) -> some View {
        // MARK: Chat media
        if let media = message.media, media.isEmpty == false {
            GeometryReader(content: { geometry in
                ScrollView(.horizontal) {
                    HStack(spacing: 10, content: {
                        Spacer()
                            .frame(width: spacerWidth(for: media, geometry: geometry))
                        
                        ForEach(0..<media.count, id: \.self) { index in
                            let mediaItem = media[index]
                            Image(uiImage: mediaItem.thumbnail)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 150)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                                .overlay(alignment: .topLeading) {
                                    let icon = mediaItem.mimeType.starts(with: "video") ? "video.circle.fill" : "photo.circle.fill"
                                    Image(systemName: icon)
                                        .resizable()
                                        .frame(width: 20, height: 20)
                                        .shadow(color: .black, radius: 10)
                                        .padding(8)
                                }
                        }
                    })
                }
            })
            .frame(height: 150)
        }
        
        // MARK: Chat bubble
        ChatBubble(direction: message.role == .aiModel ? .left : .right) {
            Text(message.message)
                .font(.title3)
                .padding(.all, 20)
                .foregroundStyle(.white)
                .background(message.role == .aiModel ? Color.blue : Color.green)
        }
    }
    
    private func sendMessage() {
        Task {
            let chatMedia = selectedMedia
            selectedMedia.removeAll()
            await chatService.sendMessage(message: textInput, media: chatMedia)
            textInput = ""
        }
    }
    
    private func spacerWidth(for media: [Media], geometry: GeometryProxy) -> CGFloat {
        var totalWidth: CGFloat = 0
        for mediaItem in media {
            let scaledWidth = mediaItem.thumbnail.size.width * (150/mediaItem.thumbnail.size.height)
            totalWidth += scaledWidth + 20
        }
        
        return totalWidth < geometry.size.width ? geometry.size.width - totalWidth : 0
    }
}

#Preview {
    ContentView()
}
