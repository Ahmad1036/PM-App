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
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
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
    
    // Comparison section
    private let compareButton = UIButton(type: .system)
    private let comparisonSummaryView = ComparisonSummaryView()
    
    // Reader data
    private var leftStandard: Standard?
    private var rightStandard: Standard?
    private var leftReaderVC: ReaderViewController?
    private var rightReaderVC: ReaderViewController?
    
    // Selected chapters for comparison
    private var leftSelectedChapter: Link?
    private var rightSelectedChapter: Link?

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Compare Standards"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .pmBackground
        
        // Style navigation bar
        if let navigationBar = navigationController?.navigationBar {
            navigationBar.largeTitleTextAttributes = [
                .font: Typography.largeTitle(),
                .foregroundColor: UIColor.pmTextPrimary
            ]
            navigationBar.titleTextAttributes = [
                .font: Typography.bodyMedium(),
                .foregroundColor: UIColor.pmTextPrimary
            ]
        }
        
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
        
        // Main split view for readers
        let splitStack = UIStackView(arrangedSubviews: [leftStack, rightStack])
        splitStack.axis = .horizontal
        splitStack.distribution = .fillEqually
        splitStack.spacing = 1.0
        splitStack.backgroundColor = .systemGray4
        
        // Big compare button at bottom with liquid glass effect (no green)
        compareButton.setTitle("Compare Standards", for: .normal)
        compareButton.titleLabel?.font = Typography.bodyMedium()
        compareButton.setTitleColor(.pmBlack, for: .normal)
        LiquidGlassStyle.applyToButton(compareButton, tintColor: .white.withAlphaComponent(0.25))
        compareButton.addTarget(self, action: #selector(compareButtonTapped), for: .touchUpInside)
        
        // Hide comparison summary initially
        comparisonSummaryView.isHidden = true
        
        view.addSubview(splitStack)
        view.addSubview(compareButton)
        
        splitStack.translatesAutoresizingMaskIntoConstraints = false
        compareButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            splitStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            splitStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            splitStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            splitStack.bottomAnchor.constraint(equalTo: compareButton.topAnchor, constant: -8),
            
            compareButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            compareButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            compareButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            compareButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    @objc private func compareButtonTapped() {
        // Show comparison summary in a modal sheet
        let summaryVC = UIViewController()
        summaryVC.view.backgroundColor = .pmBackground
        
        let summaryView = ComparisonSummaryView()
        summaryVC.view.addSubview(summaryView)
        summaryView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            summaryView.topAnchor.constraint(equalTo: summaryVC.view.safeAreaLayoutGuide.topAnchor, constant: 20),
            summaryView.leadingAnchor.constraint(equalTo: summaryVC.view.leadingAnchor, constant: 16),
            summaryView.trailingAnchor.constraint(equalTo: summaryVC.view.trailingAnchor, constant: -16),
            summaryView.bottomAnchor.constraint(lessThanOrEqualTo: summaryVC.view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
        
        let navController = UINavigationController(rootViewController: summaryVC)
        navController.navigationBar.topItem?.title = "Comparison Results"
        navController.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissComparison))
        
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        
        present(navController, animated: true)
    }
    
    @objc private func dismissComparison() {
        dismiss(animated: true)
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
        containerView.backgroundColor = .pmSurface
        
        // Header button for book selection
        headerButton.setTitle("Select Book", for: .normal)
        headerButton.titleLabel?.font = Typography.body()
        headerButton.backgroundColor = .pmSoftGray
        headerButton.setTitleColor(.pmTextPrimary, for: .normal)
        headerButton.layer.cornerRadius = 8
        headerButton.addTarget(self, action: side == .left ? #selector(selectLeftBook) : #selector(selectRightBook), for: .touchUpInside)
        
        // Navigation controls
        prevButton.setImage(UIImage(systemName: "chevron.left.circle.fill"), for: .normal)
        prevButton.tintColor = .systemBlue
        prevButton.addTarget(self, action: side == .left ? #selector(leftPrevPage) : #selector(rightPrevPage), for: .touchUpInside)
        
        nextButton.setImage(UIImage(systemName: "chevron.right.circle.fill"), for: .normal)
        nextButton.tintColor = .systemBlue
        nextButton.addTarget(self, action: side == .left ? #selector(leftNextPage) : #selector(rightNextPage), for: .touchUpInside)
        
        // TOC button for jumping to chapters
        let tocButton = UIButton(type: .system)
        tocButton.setImage(UIImage(systemName: "list.bullet.circle.fill"), for: .normal)
        tocButton.tintColor = .systemPurple
        tocButton.addTarget(self, action: side == .left ? #selector(showLeftTOC) : #selector(showRightTOC), for: .touchUpInside)
        
        pageLabel.text = "Ready"
        pageLabel.font = Typography.caption()
        pageLabel.textAlignment = .center
        pageLabel.textColor = .pmTextSecondary
        
        let navStack = UIStackView(arrangedSubviews: [prevButton, tocButton, pageLabel, nextButton])
        navStack.axis = .horizontal
        navStack.spacing = 6
        navStack.distribution = .fill
        pageLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        prevButton.setContentHuggingPriority(.required, for: .horizontal)
        nextButton.setContentHuggingPriority(.required, for: .horizontal)
        tocButton.setContentHuggingPriority(.required, for: .horizontal)
        
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
    
    @objc private func showLeftTOC() {
        guard let readerVC = leftReaderVC else { return }
        showTOC(for: readerVC, side: .left)
    }
    
    @objc private func showRightTOC() {
        guard let readerVC = rightReaderVC else { return }
        showTOC(for: readerVC, side: .right)
    }
    
    private func showTOC(for readerVC: ReaderViewController, side: Side) {
        guard let publication = readerVC.epubNavigator?.publication else { return }
        
        let tocVC = TOCViewController(publication: publication)
        tocVC.onSelectChapter = { [weak self] link in
            self?.navigateToChapter(link, in: side)
        }
        
        let navController = UINavigationController(rootViewController: tocVC)
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(navController, animated: true)
    }
    
    private func navigateToChapter(_ link: Link, in side: Side) {
        Task {
            guard let anyURL = AnyURL(string: link.href) else { return }
            let locator = Locator(
                href: anyURL,
                mediaType: link.mediaType ?? MediaType.html,
                title: link.title
            )
            
            let navigator = side == .left ? leftReaderVC?.epubNavigator : rightReaderVC?.epubNavigator
            await navigator?.go(to: locator)
            
            await MainActor.run {
                let label = side == .left ? leftPageLabel : rightPageLabel
                label.text = link.title ?? "Chapter"
            }
        }
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
        Task {
            guard let navigator = leftReaderVC?.epubNavigator else {
                print("Compare: Left navigator not available")
                await MainActor.run {
                    showNavigationError(for: .left)
                }
                return
            }
            let result = await navigator.goBackward()
            print("Compare: Left goBackward result: \(result)")
            await updatePageLabel(for: .left)
        }
    }
    
    @objc private func leftNextPage() {
        print("Compare: Left next button tapped")
        Task {
            guard let navigator = leftReaderVC?.epubNavigator else {
                print("Compare: Left navigator not available")
                await MainActor.run {
                    showNavigationError(for: .left)
                }
                return
            }
            let result = await navigator.goForward()
            print("Compare: Left goForward result: \(result)")
            await updatePageLabel(for: .left)
        }
    }
    
    @objc private func rightPrevPage() {
        print("Compare: Right prev button tapped")
        Task {
            guard let navigator = rightReaderVC?.epubNavigator else {
                print("Compare: Right navigator not available")
                await MainActor.run {
                    showNavigationError(for: .right)
                }
                return
            }
            let result = await navigator.goBackward()
            print("Compare: Right goBackward result: \(result)")
            await updatePageLabel(for: .right)
        }
    }
    
    @objc private func rightNextPage() {
        print("Compare: Right next button tapped")
        Task {
            guard let navigator = rightReaderVC?.epubNavigator else {
                print("Compare: Right navigator not available")
                await MainActor.run {
                    showNavigationError(for: .right)
                }
                return
            }
            let result = await navigator.goForward()
            print("Compare: Right goForward result: \(result)")
            await updatePageLabel(for: .right)
        }
    }
    
    // MARK: - Helper Methods
    
    private func updatePageLabel(for side: Side) async {
        await MainActor.run {
            let label = side == .left ? leftPageLabel : rightPageLabel
            label.text = "📄"
            
            // Briefly flash the label to show it updated
            UIView.animate(withDuration: 0.15) {
                label.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            } completion: { _ in
                UIView.animate(withDuration: 0.15) {
                    label.transform = .identity
                }
            }
        }
    }
    
    private func showNavigationError(for side: Side) {
        let alert = UIAlertController(
            title: "Navigation Error",
            message: "Please wait for the \(side == .left ? "left" : "right") reader to fully load.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Helper Types
    
    enum Side {
        case left, right
    }
}
