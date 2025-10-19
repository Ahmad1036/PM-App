//
//  ReaderViewController.swift
//  PM-App
//
//  Full-featured EPUB reader with navigation, TOC, search, bookmarks, and TTS
//

import UIKit
import ReadiumShared
import ReadiumNavigator
import ReadiumAdapterGCDWebServer
import AVFoundation

class ReaderViewController: UIViewController {
    
    // MARK: - Properties
    
    private let publication: Publication
    private let publicationFileName: String
    private let httpServer: HTTPServer
    private var navigator: EPUBNavigatorViewController?
    
    // Public accessor for compare view
    var epubNavigator: EPUBNavigatorViewController? {
        return navigator
    }
    
    private var currentLocator: Locator?
    private var totalLocations: Int = 0
    
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var isTTSPlaying = false
    private var isEmbeddedMode = false
    private var ttsTask: Task<Void, Never>?
    private var pageLoadedForTTS = false
    
    // UI Components
    private let toolbar = UIView()
    private let bottomBar = UIView()
    private let closeButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let tocButton = UIButton(type: .system)
    private let searchButton = UIButton(type: .system)
    private let bookmarkButton = UIButton(type: .system)
    private let moreButton = UIButton(type: .system)
    private let prevButton = UIButton(type: .system)
    private let pageSlider = UISlider()
    private let pageLabel = UILabel()
    private let nextButton = UIButton(type: .system)
    private let ttsButton = UIButton(type: .system)
    private var toolbarVisible = true
    
    // MARK: - Initialization
    
    init(publication: Publication, publicationFileName: String, httpServer: HTTPServer, isEmbedded: Bool = false) {
        self.publication = publication
        self.publicationFileName = publicationFileName
        self.httpServer = httpServer
        self.isEmbeddedMode = isEmbedded
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .pmBackground
        speechSynthesizer.delegate = self
        setupAudioSession()
        setupNavigator()
        setupUI()
        applySettings()
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try audioSession.setActive(true)
        } catch {
            print("TTS: Failed to setup audio session: \(error)")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopTTS()
    }
    
    deinit {
        navigator?.willMove(toParent: nil)
        navigator?.view.removeFromSuperview()
        navigator?.removeFromParent()
    }
    
    // MARK: - Setup
    
    private func setupNavigator() {
        do {
            let navigator = try EPUBNavigatorViewController(
                publication: publication,
                initialLocation: nil,
                httpServer: self.httpServer
            )
            self.navigator = navigator
            navigator.delegate = self
            
            addChild(navigator)
            view.insertSubview(navigator.view, at: 0) // Insert behind toolbar/bottombar
            navigator.view.translatesAutoresizingMaskIntoConstraints = false
            
            navigator.didMove(toParent: self)
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
            tapGesture.delegate = self
            navigator.view.addGestureRecognizer(tapGesture)
            
            Task {
                if case .success(let positions) = await publication.positions() {
                    await MainActor.run {
                        self.totalLocations = positions.count
                        self.pageSlider.maximumValue = Float(max(0, self.totalLocations - 1))
                        self.updatePageLabel()
                    }
                }
            }
        } catch {
            print("Failed to create navigator: \(error)")
        }
    }
    
    private func setupUI() {
        setupToolbar()
        if !isEmbeddedMode {
            setupBottomBar()
        }
        setupTTSButton()
        
        if let navigatorView = navigator?.view {
            NSLayoutConstraint.activate([
                navigatorView.topAnchor.constraint(equalTo: view.topAnchor),
                navigatorView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                navigatorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                navigatorView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
            view.bringSubviewToFront(toolbar)
            if !isEmbeddedMode {
                view.bringSubviewToFront(bottomBar)
            }
            view.bringSubviewToFront(ttsButton)
        }
    }
    
    private func setupToolbar() {
        let blurEffect = UIBlurEffect(style: .systemThickMaterial)
        let toolbarBackground = UIVisualEffectView(effect: blurEffect)
        toolbar.addSubview(toolbarBackground)
        toolbarBackground.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(toolbar)
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        
        let height: CGFloat = isEmbeddedMode ? 44 : 56
        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: height),
            
            toolbarBackground.topAnchor.constraint(equalTo: toolbar.topAnchor),
            toolbarBackground.bottomAnchor.constraint(equalTo: toolbar.bottomAnchor),
            toolbarBackground.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor),
            toolbarBackground.trailingAnchor.constraint(equalTo: toolbar.trailingAnchor),
        ])
        
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        
        titleLabel.text = publication.metadata.title ?? "Reader"
        titleLabel.font = isEmbeddedMode ? Typography.body() : Typography.bodyMedium()
        titleLabel.textColor = .pmTextPrimary
        titleLabel.textAlignment = .center
        
        tocButton.setImage(UIImage(systemName: "list.bullet"), for: .normal)
        tocButton.addTarget(self, action: #selector(tocTapped), for: .touchUpInside)
        
        searchButton.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        searchButton.addTarget(self, action: #selector(searchTapped), for: .touchUpInside)
        
        bookmarkButton.setImage(UIImage(systemName: "bookmark"), for: .normal)
        bookmarkButton.addTarget(self, action: #selector(bookmarkTapped), for: .touchUpInside)
        
        moreButton.setImage(UIImage(systemName: "ellipsis.circle"), for: .normal)
        moreButton.addTarget(self, action: #selector(moreTapped), for: .touchUpInside)
        
        [closeButton, titleLabel, tocButton, searchButton, bookmarkButton, moreButton].forEach {
            toolbar.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        if isEmbeddedMode {
            // In embedded mode, UI is controlled by parent (CompareViewController)
            toolbar.isHidden = true
        } else {
            NSLayoutConstraint.activate([
                closeButton.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor, constant: 8),
                closeButton.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),
                closeButton.widthAnchor.constraint(equalToConstant: 44),
                closeButton.heightAnchor.constraint(equalToConstant: 44),
                
                titleLabel.centerXAnchor.constraint(equalTo: toolbar.centerXAnchor),
                titleLabel.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),
                titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: closeButton.trailingAnchor, constant: 8),
                titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: searchButton.leadingAnchor, constant: -8),

                moreButton.trailingAnchor.constraint(equalTo: toolbar.trailingAnchor, constant: -8),
                moreButton.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),
                moreButton.widthAnchor.constraint(equalToConstant: 44),
                moreButton.heightAnchor.constraint(equalToConstant: 44),
                
                bookmarkButton.trailingAnchor.constraint(equalTo: moreButton.leadingAnchor, constant: -4),
                bookmarkButton.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),
                bookmarkButton.widthAnchor.constraint(equalToConstant: 44),
                bookmarkButton.heightAnchor.constraint(equalToConstant: 44),
                
                searchButton.trailingAnchor.constraint(equalTo: bookmarkButton.leadingAnchor, constant: -4),
                searchButton.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),
                searchButton.widthAnchor.constraint(equalToConstant: 44),
                searchButton.heightAnchor.constraint(equalToConstant: 44),
                
                tocButton.trailingAnchor.constraint(equalTo: searchButton.leadingAnchor, constant: -4),
                tocButton.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),
                tocButton.widthAnchor.constraint(equalToConstant: 44),
                tocButton.heightAnchor.constraint(equalToConstant: 44),
            ])
        }
    }
    
    private func setupBottomBar() {
        let blurEffect = UIBlurEffect(style: .systemThickMaterial)
        let bottomBarBackground = UIVisualEffectView(effect: blurEffect)
        bottomBar.addSubview(bottomBarBackground)
        bottomBarBackground.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(bottomBar)
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            bottomBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 60),
            
            bottomBarBackground.topAnchor.constraint(equalTo: bottomBar.topAnchor),
            bottomBarBackground.bottomAnchor.constraint(equalTo: bottomBar.bottomAnchor),
            bottomBarBackground.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor),
            bottomBarBackground.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor),
        ])
        
        prevButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        prevButton.addTarget(self, action: #selector(prevPage), for: .touchUpInside)
        
        nextButton.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        nextButton.addTarget(self, action: #selector(nextPage), for: .touchUpInside)
        
        pageSlider.minimumValue = 0
        pageSlider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        
        pageLabel.text = "Location 1 of \(totalLocations)"
        pageLabel.font = Typography.caption()
        pageLabel.textColor = .pmTextSecondary
        pageLabel.textAlignment = .center
        
        [prevButton, pageSlider, pageLabel, nextButton].forEach {
            bottomBar.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            prevButton.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 16),
            prevButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            pageSlider.leadingAnchor.constraint(equalTo: prevButton.trailingAnchor, constant: 12),
            pageSlider.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor, constant: -10),
            nextButton.leadingAnchor.constraint(equalTo: pageSlider.trailingAnchor, constant: 12),
            nextButton.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -16),
            nextButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            pageLabel.topAnchor.constraint(equalTo: pageSlider.bottomAnchor, constant: 4),
            pageLabel.centerXAnchor.constraint(equalTo: pageSlider.centerXAnchor)
        ])
    }

    private func setupTTSButton() {
        if isEmbeddedMode {
            ttsButton.isHidden = true
            return
        }
        
        ttsButton.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
        // The tint color now comes from the tab bar's tint color for consistency
        ttsButton.tintColor = .systemBlue
        ttsButton.backgroundColor = .pmSurface.withAlphaComponent(0.8)
        ttsButton.layer.cornerRadius = 28
        ttsButton.layer.shadowColor = UIColor.black.cgColor
        ttsButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        ttsButton.layer.shadowRadius = 5
        ttsButton.layer.shadowOpacity = 0.1
        
        ttsButton.addTarget(self, action: #selector(ttsTapped), for: .touchUpInside)
        view.addSubview(ttsButton)
        ttsButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            ttsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            ttsButton.bottomAnchor.constraint(equalTo: bottomBar.topAnchor, constant: -20),
            ttsButton.widthAnchor.constraint(equalToConstant: 56),
            ttsButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func closeTapped() {
        stopTTS()
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func tocTapped() {
        let tocVC = TOCViewController(publication: publication)
        tocVC.onSelectChapter = { [weak self] link in
            self?.navigateToLink(link)
        }
        
        let navController = UINavigationController(rootViewController: tocVC)
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(navController, animated: true)
    }
    
    private func navigateToLink(_ link: Link) {
        if isTTSPlaying { stopTTS() }
        Task {
            guard let anyURL = AnyURL(string: link.href) else { return }
            let locator = Locator(href: anyURL, mediaType: link.mediaType ?? .html, title: link.title)
            await navigator?.go(to: locator)
        }
    }
    
    @objc private func searchTapped() {
        let searchVC = SearchViewController(publication: publication, publicationFileName: publicationFileName)
        searchVC.onSelectResult = { [weak self] locator in
            self?.navigateToLocator(locator)
        }
        let navController = UINavigationController(rootViewController: searchVC)
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(navController, animated: true)
    }
    
    private func navigateToLocator(_ locator: Locator) {
        if isTTSPlaying { stopTTS() }
        Task { await navigator?.go(to: locator) }
    }
    
    @objc private func bookmarkTapped() {
        guard let locator = currentLocator else { return }
        let bookmarkId = locator.href.string + (locator.locations.position?.description ?? "")
        
        if let existingBookmark = ReaderPersistence.shared.listBookmarks(for: publicationFileName).first(where: { $0.id == bookmarkId }) {
            ReaderPersistence.shared.removeBookmark(id: existingBookmark.id)
        } else {
            let bookmark = Bookmark(
                id: bookmarkId,
                publicationFileName: publicationFileName,
                title: locator.title ?? "Bookmark",
                href: locator.href.string,
                location: locator.jsonString
            )
            ReaderPersistence.shared.addBookmark(bookmark)
        }
        updateBookmarkButton()
    }
    
    @objc private func moreTapped() {
        let settingsVC = ReaderSettingsViewController()
        settingsVC.delegate = self
        let navController = UINavigationController(rootViewController: settingsVC)
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
        }
        present(navController, animated: true)
    }
    
    @objc private func prevPage() {
        if isTTSPlaying { stopTTS() }
        Task { await navigator?.goBackward() }
    }
    
    @objc private func nextPage() {
        if isTTSPlaying { stopTTS() }
        Task { await navigator?.goForward() }
    }
    
    @objc private func sliderChanged() {
        guard totalLocations > 0 else { return }
        let positionIndex = Int(pageSlider.value)
        if isTTSPlaying { stopTTS() }
        Task {
            if case .success(let positions) = await publication.positions(), positionIndex < positions.count {
                await navigator?.go(to: positions[positionIndex])
            }
        }
    }
    
    @objc private func ttsTapped() {
        if isTTSPlaying {
            stopTTS()
        } else {
            startTTS()
        }
    }
    
    @objc private func handleTap() {
        if isEmbeddedMode { return }
        toolbarVisible.toggle()
        UIView.animate(withDuration: 0.3) {
            self.toolbar.alpha = self.toolbarVisible ? 1.0 : 0.0
            self.bottomBar.alpha = self.toolbarVisible ? 1.0 : 0.0
        }
    }
    
    // MARK: - Helpers
    private func updateBookmarkButton() {
        guard let locator = currentLocator else {
            bookmarkButton.setImage(UIImage(systemName: "bookmark"), for: .normal)
            return
        }
        let bookmarkId = locator.href.string + (locator.locations.position?.description ?? "")
        let isBookmarked = ReaderPersistence.shared.listBookmarks(for: publicationFileName).contains { $0.id == bookmarkId }
        bookmarkButton.setImage(UIImage(systemName: isBookmarked ? "bookmark.fill" : "bookmark"), for: .normal)
    }
    
    private func updatePageLabel() {
        guard totalLocations > 0 else {
            pageLabel.text = ""
            return
        }
        let currentPage = (currentLocator?.locations.position ?? 0) + 1
        pageLabel.text = "Location \(currentPage) of \(totalLocations)"
    }
    
    private func stopTTS() {
        ttsTask?.cancel()
        ttsTask = nil
        speechSynthesizer.stopSpeaking(at: .immediate)
        isTTSPlaying = false
        ttsButton.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("TTS: Failed to deactivate audio session: \(error)")
        }
    }
    
    private func didFinishSpeechAndShouldContinue() {
        if isTTSPlaying {
            Task {
                pageLoadedForTTS = false
                let moved = await navigator?.goForward()
                if moved == true {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    startTTS()
                } else {
                    await MainActor.run {
                        self.stopTTS()
                        let alert = UIAlertController(title: "Reading Complete", message: "Reached the end of the content.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true)
                    }
                }
            }
        }
    }
    
    // MARK: - Text Extraction & Highlighting (NEW FOR COMPARISON)
    
    /// Extracts all visible text from the current page.
    func extractVisibleText() async -> String {
        let javascript = "document.body.innerText;"
        do {
            let result = try await navigator?.evaluateJavaScript(javascript)
            return result as? String ?? ""
        } catch {
            print("Failed to extract text: \(error)")
            return ""
        }
    }
    
    /// Finds a snippet of text on the current page, scrolls to it, and highlights it.
    func findAndHighlight(text: String) async {
        let escapedText = text.replacingOccurrences(of: "'", with: "\\'")
        let javascript = """
        (function() {
            // Remove previous highlights
            var existingHighlights = document.querySelectorAll('mark.pm-app-highlight');
            existingHighlights.forEach(function(node) {
                var parent = node.parentNode;
                while (node.firstChild) {
                    parent.insertBefore(node.firstChild, node);
                }
                parent.removeChild(node);
            });

            // Find the first occurrence of the text
            var snapshot = document.evaluate("string(//body)", document, null, XPathResult.STRING_TYPE, null);
            var bodyText = snapshot.stringValue || "";
            var index = bodyText.indexOf('\(escapedText)');
            
            if (index === -1) return;

            // Find the node containing the text
            var treeWalker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT, null, false);
            var currentNode;
            var charCount = 0;
            var foundNode = null;
            var startOffset = 0;
            
            while (currentNode = treeWalker.nextNode()) {
                var nodeLength = currentNode.nodeValue.length;
                if (charCount + nodeLength > index) {
                    foundNode = currentNode;
                    startOffset = index - charCount;
                    break;
                }
                charCount += nodeLength;
            }
            
            if (!foundNode) return;
            
            // Create a range and highlight
            var range = document.createRange();
            range.setStart(foundNode, startOffset);
            range.setEnd(foundNode, startOffset + '\(escapedText)'.length);
            
            var mark = document.createElement('mark');
            mark.className = 'pm-app-highlight';
            mark.style.backgroundColor = '#FFD700'; // Gold color
            mark.style.color = 'black';
            
            range.surroundContents(mark);
            mark.scrollIntoView({ behavior: 'smooth', block: 'center' });
        })();
        """
        _ = try? await navigator?.evaluateJavaScript(javascript)
    }

}

// MARK: - EPUBNavigatorDelegate
extension ReaderViewController: EPUBNavigatorDelegate {
    func navigator(_ navigator: Navigator, locationDidChange locator: Locator) {
        self.currentLocator = locator
        if let position = locator.locations.position {
            pageSlider.value = Float(position)
        }
        updatePageLabel()
        updateBookmarkButton()
        pageLoadedForTTS = true
    }
    
    func navigator(_ navigator: Navigator, presentError error: NavigatorError) {
        print("Navigator error: \(error)")
    }
}

// MARK: - ReaderSettingsDelegate
extension ReaderViewController: ReaderSettingsDelegate {
    func settingsDidChange() {
        applySettings()
    }
    
    private func applySettings() {
        guard let navigator = navigator else { return }
        let settings = ReaderSettings.shared
        
        var preferences = EPUBPreferences()
        preferences.scroll = settings.scrollMode == .continuous
        
        Task {
            do {
                try await navigator.submitPreferences(preferences)
                await applyCSSSettings()
            } catch {
                print("Failed to apply settings: \(error)")
            }
        }
    }
    
    private func applyCSSSettings() async {
        let settings = ReaderSettings.shared
        var backgroundColor = "#FFFFFF", textColor = "#000000"
        
        switch settings.theme {
        case .dark:
            backgroundColor = "#1C1C1E"; textColor = "#FFFFFF"
        case .sepia:
            backgroundColor = "#F4ECD8"; textColor = "#5B4636"
        default: break
        }
        
        let css = """
        body {
            font-size: \(settings.fontSize)px !important;
            line-height: \(settings.lineSpacing) !important;
            background-color: \(backgroundColor) !important;
            color: \(textColor) !important;
        }
        """
        
        let javascript = """
        var style = document.getElementById('reader-custom-style') || document.createElement('style');
        style.id = 'reader-custom-style';
        style.textContent = `\(css)`;
        document.head.appendChild(style);
        """
        _ = try? await navigator?.evaluateJavaScript(javascript)
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension ReaderViewController: AVSpeechSynthesizerDelegate {
    
    private func startTTS() {
        ttsTask?.cancel()
        do { try AVAudioSession.sharedInstance().setActive(true) } catch { print("TTS audio session error: \(error)") }
        
        ttsTask = Task {
            try? await Task.sleep(nanoseconds: 800_000_000)
            if Task.isCancelled { return }
            
            let javascript = "document.body.innerText;"
            do {
                if let text = try await navigator?.evaluateJavaScript(javascript) as? String, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    await MainActor.run {
                        let utterance = AVSpeechUtterance(string: text)
                        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                        self.speechSynthesizer.speak(utterance)
                        self.isTTSPlaying = true
                        self.ttsButton.setImage(UIImage(systemName: "pause.circle.fill"), for: .normal)
                    }
                } else {
                    await MainActor.run { self.didFinishSpeechAndShouldContinue() }
                }
            } catch {
                print("TTS Error: \(error)")
            }
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        didFinishSpeechAndShouldContinue()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isTTSPlaying = false
        ttsButton.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
    }
}

// MARK: - UIGestureRecognizerDelegate
extension ReaderViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
