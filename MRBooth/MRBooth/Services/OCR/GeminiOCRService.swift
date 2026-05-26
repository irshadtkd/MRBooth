//
//  GeminiOCRService.swift
//  MRBooth
//

import Foundation
import PDFKit
import UniformTypeIdentifiers

#if canImport(UIKit)
import UIKit
#endif

final class GeminiOCRService: OCRServiceProtocol, @unchecked Sendable {
    private let keyProvider: GeminiAPIKeyProviding
    private let client: GeminiAPIClient
    private let maxImageDimension: CGFloat = 2048
    private let jpegCompressionQuality: CGFloat = 0.85

    init(
        store: GeminiAPIKeyProviding = SessionStore.shared,
        client: GeminiAPIClient = GeminiAPIClient()
    ) {
        self.keyProvider = store
        self.client = client
    }

    func extractVoters(from imageData: Data) async throws -> [Voter] {
        let apiKey = try requireAPIKey()
        guard let base64 = Self.jpegBase64(from: imageData, maxDimension: maxImageDimension, quality: jpegCompressionQuality) else {
            throw AppError.ocrFailed("Invalid image data")
        }
        let extracted = try await client.extractVoters(fromJPEGBase64: base64, apiKey: apiKey)
        return try votersOrThrow(mapToVoters(extracted))
    }

    func extractVoters(from url: URL) async throws -> [Voter] {
        let apiKey = try requireAPIKey()
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed { url.stopAccessingSecurityScopedResource() }
        }

        if Self.isPDF(url: url) {
            let pageImages = try Self.renderPDFPages(from: url, maxDimension: maxImageDimension)
            guard !pageImages.isEmpty else {
                throw AppError.ocrFailed("PDF has no readable pages")
            }
            var allExtracted: [AIExtractedVoter] = []
            for imageData in pageImages {
                guard let base64 = Self.jpegBase64(
                    from: imageData,
                    maxDimension: maxImageDimension,
                    quality: jpegCompressionQuality
                ) else { continue }
                let pageVoters = try await client.extractVoters(fromJPEGBase64: base64, apiKey: apiKey)
                allExtracted.append(contentsOf: pageVoters)
            }
            return try votersOrThrow(mapToVoters(allExtracted))
        }

        let data = try Data(contentsOf: url)
        return try await extractVoters(from: data)
    }

    private func votersOrThrow(_ voters: [Voter]) throws -> [Voter] {
        guard !voters.isEmpty else {
            throw AppError.ocrFailed("No voter rows found in document")
        }
        return voters
    }

    private func requireAPIKey() throws -> String {
        guard let key = keyProvider.loadGeminiAPIKey() else {
            throw AppError.validationFailed(AppStrings.geminiAPIKeyMissing)
        }
        return key
    }

    private func mapToVoters(_ extracted: [AIExtractedVoter]) -> [Voter] {
        extracted
            .filter { !$0.isEffectivelyEmpty }
            .map { $0.toVoter() }
            .filter { !$0.name.isEmpty || !$0.voterID.isEmpty || !$0.serialNumber.isEmpty }
    }

    private static func isPDF(url: URL) -> Bool {
        if url.pathExtension.lowercased() == "pdf" { return true }
        if let type = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType {
            return type.conforms(to: .pdf)
        }
        return false
    }

    #if canImport(UIKit)
    static func jpegBase64(from data: Data, maxDimension: CGFloat, quality: CGFloat) -> String? {
        guard let image = UIImage(data: data) else { return nil }
        let resized = resize(image: image, maxDimension: maxDimension)
        guard let jpeg = resized.jpegData(compressionQuality: quality) else { return nil }
        return jpeg.base64EncodedString()
    }

    static func renderPDFPages(from url: URL, maxDimension: CGFloat) throws -> [Data] {
        guard let document = PDFDocument(url: url) else {
            throw AppError.ocrFailed("Could not open PDF")
        }
        var images: [Data] = []
        for index in 0..<document.pageCount {
            guard let page = document.page(at: index) else { continue }
            let pageRect = page.bounds(for: .mediaBox)
            let scale = min(
                maxDimension / max(pageRect.width, 1),
                maxDimension / max(pageRect.height, 1),
                2.0
            )
            let size = CGSize(
                width: pageRect.width * scale,
                height: pageRect.height * scale
            )
            let renderer = UIGraphicsImageRenderer(size: size)
            let image = renderer.image { context in
                UIColor.white.setFill()
                context.fill(CGRect(origin: .zero, size: size))
                context.cgContext.translateBy(x: 0, y: size.height)
                context.cgContext.scaleBy(x: scale, y: -scale)
                page.draw(with: .mediaBox, to: context.cgContext)
            }
            if let data = image.jpegData(compressionQuality: 0.85) {
                images.append(data)
            }
        }
        return images
    }

    private static func resize(image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let longest = max(size.width, size.height)
        guard longest > maxDimension else { return image }
        let scale = maxDimension / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    #else
    static func jpegBase64(from data: Data, maxDimension: CGFloat, quality: CGFloat) -> String? {
        nil
    }

    static func renderPDFPages(from url: URL, maxDimension: CGFloat) throws -> [Data] {
        throw AppError.ocrFailed("PDF extraction requires iOS")
    }
    #endif
}
