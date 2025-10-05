//
//  RediumHelper.swift
//  PM-App
//
//  Created with assistance from Cascade
//

import UIKit
import ReadiumShared
import ReadiumNavigator
import ReadiumStreamer
import ReadiumAdapterGCDWebServer

class RediumHelper {
    static let shared = RediumHelper()
    
    private let httpClient: HTTPClient
    private let assetRetriever: AssetRetriever
    private let publicationOpener: PublicationOpener
    private let httpServer: HTTPServer
    
    private init() {
        // Initialize HTTP client
        self.httpClient = DefaultHTTPClient()
        
        // Initialize asset retriever
        self.assetRetriever = AssetRetriever(httpClient: httpClient)
        
        // Initialize publication opener with default parser
        self.publicationOpener = PublicationOpener(
            parser: DefaultPublicationParser(
                httpClient: httpClient,
                assetRetriever: assetRetriever,
                pdfFactory: DefaultPDFDocumentFactory()
            )
        )
        
        // Initialize HTTP server for serving EPUB resources
        self.httpServer = GCDHTTPServer(assetRetriever: assetRetriever)
    }
    
    // MARK: - Public API
    
    /// Opens reader in modal full-screen mode with enhanced UI
    func openReader(for standard: Standard, from viewController: UIViewController) {
        Task {
            if let publication = await loadPublication(for: standard, from: viewController) {
                await presentReaderUI(publication: publication, publicationFileName: standard.fileName, from: viewController)
            }
        }
    }
    
    /// Presents the enhanced reader UI with toolbar and controls
    func presentReaderUI(publication: Publication, publicationFileName: String, from viewController: UIViewController) async {
        await MainActor.run {
            let readerVC = ReaderViewController(
                publication: publication,
                publicationFileName: publicationFileName,
                httpServer: self.httpServer,
                isEmbedded: false
            )
            readerVC.modalPresentationStyle = .fullScreen
            viewController.present(readerVC, animated: true)
        }
    }
    
    /// Loads publication from standard
    private func loadPublication(for standard: Standard, from viewController: UIViewController) async -> Publication? {
        guard let bookPath = Bundle.main.path(forResource: standard.fileName, ofType: "epub") else {
            await MainActor.run {
                self.showError(
                    message: "The EPUB file for \(standard.title) could not be found.",
                    in: viewController
                )
            }
            return nil
        }
        
        do {
            let url = URL(fileURLWithPath: bookPath)
            guard let fileURL = FileURL(url: url) else {
                await MainActor.run {
                    self.showError(message: "Invalid EPUB file path", in: viewController)
                }
                return nil
            }
            
            let asset = try await assetRetriever.retrieve(url: fileURL).get()
            let publication = try await publicationOpener.open(
                asset: asset,
                allowUserInteraction: false,
                sender: viewController
            ).get()
            
            return publication
        } catch {
            await MainActor.run {
                self.showError(
                    message: "Failed to load EPUB: \(error.localizedDescription)",
                    in: viewController
                )
            }
            return nil
        }
    }
    
    /// Opens reader embedded in a container view with enhanced UI
    func openEmbeddedReader(for standard: Standard, in parentViewController: UIViewController, containerView: UIView) {
        Task {
            if let publication = await loadPublication(for: standard, from: parentViewController) {
                await embedReaderUI(
                    publication: publication,
                    publicationFileName: standard.fileName,
                    in: parentViewController,
                    containerView: containerView
                )
            }
        }
    }
    
    /// Embeds the enhanced reader UI as a child view controller
    private func embedReaderUI(publication: Publication, publicationFileName: String, in parentViewController: UIViewController, containerView: UIView) async {
        await MainActor.run {
            let readerVC = ReaderViewController(
                publication: publication,
                publicationFileName: publicationFileName,
                httpServer: self.httpServer,
                isEmbedded: true
            )
            
            parentViewController.addChild(readerVC)
            containerView.addSubview(readerVC.view)
            readerVC.view.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                readerVC.view.topAnchor.constraint(equalTo: containerView.topAnchor),
                readerVC.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                readerVC.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                readerVC.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
            ])
            
            readerVC.didMove(toParent: parentViewController)
        }
    }
    
    private func showError(message: String, in viewController: UIViewController) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        viewController.present(alert, animated: true)
    }
}
