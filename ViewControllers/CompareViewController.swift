//
//  CompareViewController.swift
//  PM-App
//
//  Side-by-side comparison view for EPUB standards
//
import UIKit
import ReadiumShared
import ReadiumNavigator
import ReadiumStreamer
import ReadiumAdapterGCDWebServer

class CompareViewController: UIViewController {

    // MARK: - UI Components
    private let leftContainer = UIView()
    private let rightContainer = UIView()
    
    // Headers with book selection
    private let leftHeaderButton = UIButton(type: .system)
    private let rightHeaderButton = UIButton(type: .system)
    
    // Navigation controls
    private let leftPrevButton = UIButton(type: .system)
    private let leftNextButton = UIButton(type: .system)
    private let leftPageLabel = UILabel()
    
    private let rightPrevButton = UIButton(type: .system)
    private let rightNextButton = UIButton(type: .system)
    private let rightPageLabel = UILabel()
    
    // Reader data
    private var leftStandard: Standard?
    private var rightStandard: Standard?
    private var leftReaderVC: ReaderViewController?
    private var rightReaderVC: ReaderViewController?

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Compare Standards"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemBackground
        
        // Apply optimized settings for split view
        applySplitViewSettings()
        
        setupSplitView()
        loadDefaultStandards()
    }
    
    // MARK: - Setup
    
    private func applySplitViewSettings() {
        // Optimize settings for split view - minimal font, paginated mode
        let settings = ReaderSettings.shared
        settings.fontSize = 12 // Smallest font for split view
        settings.scrollMode = .paginated // Better for side-by-side
        settings.lineSpacing = 1.0 // Minimum line spacing
        settings.theme = .light // Consistent theme
    }

    private func setupSplitView() {
        // Left side
        let leftStack = createSideView(
            container: leftContainer,
            headerButton: leftHeaderButton,
            prevButton: leftPrevButton,
            nextButton: leftNextButton,
            pageLabel: leftPageLabel,
            side: .left
        )
        
        // Right side
        let rightStack = createSideView(
            container: rightContainer,
            headerButton: rightHeaderButton,
            prevButton: rightPrevButton,
            nextButton: rightNextButton,
            pageLabel: rightPageLabel,
            side: .right
        )
        
        // Main split view
        let splitStack = UIStackView(arrangedSubviews: [leftStack, rightStack])
        splitStack.axis = .horizontal
        splitStack.distribution = .fillEqually
        splitStack.spacing = 1.0
        splitStack.backgroundColor = .systemGray4
        
        view.addSubview(splitStack)
        splitStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            splitStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            splitStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            splitStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            splitStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func createSideView(
        container: UIView,
        headerButton: UIButton,
        prevButton: UIButton,
        nextButton: UIButton,
        pageLabel: UILabel,
        side: Side
    ) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .systemBackground
        
        // Header button for book selection
        headerButton.setTitle("Select Book", for: .normal)
        headerButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        headerButton.backgroundColor = .systemGray6
        headerButton.setTitleColor(.label, for: .normal)
        headerButton.addTarget(self, action: side == .left ? #selector(selectLeftBook) : #selector(selectRightBook), for: .touchUpInside)
        
        // Navigation controls
        prevButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        prevButton.addTarget(self, action: side == .left ? #selector(leftPrevPage) : #selector(rightPrevPage), for: .touchUpInside)
        
        nextButton.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        nextButton.addTarget(self, action: side == .left ? #selector(leftNextPage) : #selector(rightNextPage), for: .touchUpInside)
        
        pageLabel.text = "Page -/-"
        pageLabel.font = .systemFont(ofSize: 11)
        pageLabel.textAlignment = .center
        
        let navStack = UIStackView(arrangedSubviews: [prevButton, pageLabel, nextButton])
        navStack.axis = .horizontal
        navStack.spacing = 8
        navStack.distribution = .fill
        pageLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        // Reader container
        container.backgroundColor = .secondarySystemBackground
        
        // Layout
        containerView.addSubview(headerButton)
        containerView.addSubview(navStack)
        containerView.addSubview(container)
        
        headerButton.translatesAutoresizingMaskIntoConstraints = false
        navStack.translatesAutoresizingMaskIntoConstraints = false
        container.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            headerButton.topAnchor.constraint(equalTo: containerView.topAnchor),
            headerButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            headerButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            headerButton.heightAnchor.constraint(equalToConstant: 36),
            
            navStack.topAnchor.constraint(equalTo: headerButton.bottomAnchor, constant: 4),
            navStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            navStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            navStack.heightAnchor.constraint(equalToConstant: 32),
            
            container.topAnchor.constraint(equalTo: navStack.bottomAnchor, constant: 4),
            container.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            container.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])
        
        return containerView
    }
    
    private func loadDefaultStandards() {
        // Load PMBOK vs PRINCE2 by default
        if let pmbok = StandardsData.allStandards.first(where: { $0.fileName == "PMBOK" }) {
            loadStandard(pmbok, in: .left)
        }
        
        if let prince2 = StandardsData.allStandards.first(where: { $0.fileName == "PRINCE2" }) {
            loadStandard(prince2, in: .right)
        }
    }
    
    private func loadStandard(_ standard: Standard, in side: Side) {
        Task {
            // Load publication
            guard let bookPath = Bundle.main.path(forResource: standard.fileName, ofType: "epub"),
                  let fileURL = FileURL(url: URL(fileURLWithPath: bookPath)) else {
                return
            }
            
            do {
                let httpClient = DefaultHTTPClient()
                let assetRetriever = AssetRetriever(httpClient: httpClient)
                let asset = try await assetRetriever.retrieve(url: fileURL).get()
                
                let publicationOpener = PublicationOpener(
                    parser: DefaultPublicationParser(
                        httpClient: httpClient,
                        assetRetriever: assetRetriever,
                        pdfFactory: DefaultPDFDocumentFactory()
                    )
                )
                
                let publication = try await publicationOpener.open(
                    asset: asset,
                    allowUserInteraction: false,
                    sender: self
                ).get()
                
                let httpServer = GCDHTTPServer(assetRetriever: assetRetriever)
                
                await MainActor.run {
                    embedReader(publication: publication, fileName: standard.fileName, title: standard.title, httpServer: httpServer, in: side)
                }
            } catch {
                print("Failed to load \(standard.title): \(error)")
            }
        }
    }
    
    private func embedReader(publication: Publication, fileName: String, title: String, httpServer: HTTPServer, in side: Side) {
        // Remove existing reader if present
        if side == .left {
            leftReaderVC?.removeFromParent()
            leftReaderVC?.view.removeFromSuperview()
            leftReaderVC = nil
        } else {
            rightReaderVC?.removeFromParent()
            rightReaderVC?.view.removeFromSuperview()
            rightReaderVC = nil
        }
        
        // Apply minimal settings before creating reader
        applySplitViewSettings()
        
        // Create reader
        let readerVC = ReaderViewController(
            publication: publication,
            publicationFileName: fileName,
            httpServer: httpServer,
            isEmbedded: true
        )
        
        // Store reference
        if side == .left {
            leftReaderVC = readerVC
            leftStandard = StandardsData.allStandards.first(where: { $0.fileName == fileName })
            leftHeaderButton.setTitle(title, for: .normal)
        } else {
            rightReaderVC = readerVC
            rightStandard = StandardsData.allStandards.first(where: { $0.fileName == fileName })
            rightHeaderButton.setTitle(title, for: .normal)
        }
        
        // Embed
        addChild(readerVC)
        let container = side == .left ? leftContainer : rightContainer
        container.addSubview(readerVC.view)
        readerVC.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            readerVC.view.topAnchor.constraint(equalTo: container.topAnchor),
            readerVC.view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            readerVC.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            readerVC.view.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])
        
        readerVC.didMove(toParent: self)
        
        // Log navigation state for debugging
        print("Compare: Embedded reader for \(title), navigator available: \(readerVC.epubNavigator != nil)")
    }
    
    // MARK: - Actions
    
    @objc private func selectLeftBook() {
        showBookSelector(for: .left)
    }
    
    @objc private func selectRightBook() {
        showBookSelector(for: .right)
    }
    
    private func showBookSelector(for side: Side) {
        let alert = UIAlertController(title: "Select Book", message: nil, preferredStyle: .actionSheet)
        
        for standard in StandardsData.allStandards {
            alert.addAction(UIAlertAction(title: standard.title, style: .default) { [weak self] _ in
                self?.loadStandard(standard, in: side)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = side == .left ? leftHeaderButton : rightHeaderButton
            popover.sourceRect = (side == .left ? leftHeaderButton : rightHeaderButton).bounds
        }
        
        present(alert, animated: true)
    }
    
    @objc private func leftPrevPage() {
        print("Compare: Left prev button tapped")
        guard let navigator = leftReaderVC?.epubNavigator else {
            print("Compare: Left navigator not available")
            return
        }
        Task {
            let result = await navigator.goBackward()
            print("Compare: Left goBackward result: \(result)")
        }
    }
    
    @objc private func leftNextPage() {
        print("Compare: Left next button tapped")
        guard let navigator = leftReaderVC?.epubNavigator else {
            print("Compare: Left navigator not available")
            return
        }
        Task {
            let result = await navigator.goForward()
            print("Compare: Left goForward result: \(result)")
        }
    }
    
    @objc private func rightPrevPage() {
        print("Compare: Right prev button tapped")
        guard let navigator = rightReaderVC?.epubNavigator else {
            print("Compare: Right navigator not available")
            return
        }
        Task {
            let result = await navigator.goBackward()
            print("Compare: Right goBackward result: \(result)")
        }
    }
    
    @objc private func rightNextPage() {
        print("Compare: Right next button tapped")
        guard let navigator = rightReaderVC?.epubNavigator else {
            print("Compare: Right navigator not available")
            return
        }
        Task {
            let result = await navigator.goForward()
            print("Compare: Right goForward result: \(result)")
        }
    }
    
    // MARK: - Helper Types
    
    enum Side {
        case left, right
    }
}
