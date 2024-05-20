//
//  ThumbnailService.swift
//  VertexFirebaseSwiftUI
//
//  Created by Anup D'Souza on 16/05/24.
//  🕸️ https://www.anupdsouza.com
//  🔗 https://twitter.com/swift_odyssey
//  👨🏻‍💻 https://github.com/anupdsouza
//  ☕️ https://www.buymeacoffee.com/anupdsouza
//

import Foundation
import SwiftUI
import PhotosUI
import AVFoundation

struct ThumbnailService {
    private let largestImageDimension = 768.0
    
    func processPhotoPickerItem(for item: PhotosPickerItem) async throws -> (String, Data, UIImage) {
        guard let mimeType = item.supportedContentTypes.first?.preferredMIMEType else {
            throw NSError(domain: "DataError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to determine MIME type"])
        }
        guard let data = try await item.loadTransferable(type: Data.self) else {
            throw NSError(domain: "DataError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load data"])
        }
        
        if mimeType.starts(with: "video") {
            // MARK: Generate video thumbnail
            let thumbnail = try await generateVideoThumbnail(for: data, mimeType: mimeType)
            return (mimeType, data, thumbnail)
        }
        else if mimeType.starts(with: "image") {
            // MARK: Generate image thumbnail
            let (data, thumbnail) = try await generateImageThumbnail(for: data)
            return (mimeType, data, thumbnail)
        }
        else {
            throw NSError(domain: "UnsupportedTypeError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unsupported media type"])
        }
    }
    
    func generateVideoThumbnail(for data: Data, mimeType: String) async throws -> UIImage {
        let fileExtension: String
        if mimeType == "video/mp4" {
            fileExtension = "mp4"
        } else if mimeType == "video/quicktime" {
            fileExtension = "mov"
        } else {
            throw NSError(domain: "UnsupportedTypeError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Unsupported video"])
        }
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension(fileExtension)
        try data.write(to: tempURL)
        
        let asset = AVAsset(url: tempURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        let time = CMTime(seconds: 1, preferredTimescale: 60)
        let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
        let uiImage = UIImage(cgImage: cgImage)
        
        return uiImage
    }
    
    func generateImageThumbnail(for data: Data) async throws -> (Data, UIImage) {
        guard let image = UIImage(data: data) else {
            throw NSError(domain: "DataError", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to create UIImage from data"])
        }
        
        let finalImage: UIImage
        if !image.size.fits(largestDimension: largestImageDimension) {
            guard let resizedImage = image.preparingThumbnail(of: image.size.aspectFit(largestDimension: largestImageDimension)) else {
                throw NSError(domain: "DataError", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to resize UIImage"])
            }
            finalImage = resizedImage
        } else {
            finalImage = image
        }
        
        guard let jpegData = finalImage.jpegData(compressionQuality: 0.5) else {
            throw NSError(domain: "DataError", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to create JPEG data"])
        }
        
        return (jpegData, finalImage)
    }
}

private extension CGSize {
    func fits(largestDimension length: CGFloat) -> Bool {
        return width <= length && height <= length
    }
    
    func aspectFit(largestDimension length: CGFloat) -> CGSize {
        let aspectRatio = width/height
        if width > height {
            let width = min(self.width, length)
            return CGSize(width: width, height: round(width/aspectRatio))
        } else {
            let height = min(self.height, length)
            return CGSize(width: round(height * aspectRatio), height: height)
        }
    }
}
