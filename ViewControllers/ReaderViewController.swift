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
        view.backgroundColor = .systemBackground
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
            print("TTS: Audio session configured successfully")
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
            
            // Will update constraints after toolbar/bottombar are created
            navigator.didMove(toParent: self)
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
            tapGesture.delegate = self
            navigator.view.addGestureRecognizer(tapGesture)
            
            Task {
                let positionsResult = await publication.positions()
                if case .success(let positions) = positionsResult {
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
        
        // Now constrain navigator view properly
        if let navigatorView = navigator?.view {
            NSLayoutConstraint.activate([
                navigatorView.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
                navigatorView.bottomAnchor.constraint(equalTo: isEmbeddedMode ? view.bottomAnchor : bottomBar.topAnchor),
                navigatorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                navigatorView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
        }
    }
    
    private func setupToolbar() {
        toolbar.backgroundColor = .systemBackground
        toolbar.layer.shadowColor = UIColor.black.cgColor
        toolbar.layer.shadowOpacity = 0.1
        toolbar.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.addSubview(toolbar)
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        
        let height: CGFloat = isEmbeddedMode ? 44 : 56
        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: height)
        ])
        
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        
        titleLabel.text = publication.metadata.title ?? "Reader"
        titleLabel.font = .systemFont(ofSize: isEmbeddedMode ? 14 : 17, weight: .semibold)
        titleLabel.textAlignment = .center
        
        tocButton.setImage(UIImage(systemName: "list.bullet"), for: .normal)
        tocButton.addTarget(self, action: #selector(tocTapped), for: .touchUpInside)
        
        searchButton.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        searchButton.addTarget(self, action: #selector(searchTapped), for: .touchUpInside)
        
        bookmarkButton.setImage(UIImage(systemName: "star"), for: .normal)
        bookmarkButton.addTarget(self, action: #selector(bookmarkTapped), for: .touchUpInside)
        
        moreButton.setImage(UIImage(systemName: "ellipsis.circle"), for: .normal)
        moreButton.addTarget(self, action: #selector(moreTapped), for: .touchUpInside)
        
        [closeButton, titleLabel, tocButton, searchButton, bookmarkButton, moreButton].forEach {
            toolbar.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        if isEmbeddedMode {
            closeButton.isHidden = true
            tocButton.isHidden = true
            searchButton.isHidden = true
            bookmarkButton.isHidden = true
            
            NSLayoutConstraint.activate([
                titleLabel.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor, constant: 16),
                titleLabel.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),
                titleLabel.trailingAnchor.constraint(equalTo: moreButton.leadingAnchor, constant: -8),
                moreButton.trailingAnchor.constraint(equalTo: toolbar.trailingAnchor, constant: -8),
                moreButton.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),
                moreButton.widthAnchor.constraint(equalToConstant: 44),
                moreButton.heightAnchor.constraint(equalToConstant: 44)
            ])
        } else {
            NSLayoutConstraint.activate([
                closeButton.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor, constant: 8),
                closeButton.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),
                closeButton.widthAnchor.constraint(equalToConstant: 44),
                closeButton.heightAnchor.constraint(equalToConstant: 44),
                tocButton.leadingAnchor.constraint(equalTo: closeButton.trailingAnchor, constant: 4),
                tocButton.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),
                tocButton.widthAnchor.constraint(equalToConstant: 44),
                tocButton.heightAnchor.constraint(equalToConstant: 44),
                titleLabel.leadingAnchor.constraint(equalTo: tocButton.trailingAnchor, constant: 8),
                titleLabel.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),
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
                searchButton.heightAnchor.constraint(equalToConstant: 44)
            ])
        }
    }
    
    private func setupBottomBar() {
        bottomBar.backgroundColor = .systemBackground
        bottomBar.layer.shadowColor = UIColor.black.cgColor
        bottomBar.layer.shadowOpacity = 0.1
        bottomBar.layer.shadowOffset = CGSize(width: 0, height: -2)
        view.addSubview(bottomBar)
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            bottomBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        prevButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        prevButton.addTarget(self, action: #selector(prevPage), for: .touchUpInside)
        
        nextButton.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        nextButton.addTarget(self, action: #selector(nextPage), for: .touchUpInside)
        
        pageSlider.minimumValue = 0
        pageSlider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        
        pageLabel.text = "Location 1 of \(totalLocations)"
        pageLabel.font = .systemFont(ofSize: 12)
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
        ttsButton.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
        ttsButton.backgroundColor = .systemBlue
        ttsButton.tintColor = .white
        ttsButton.layer.cornerRadius = 28
        ttsButton.addTarget(self, action: #selector(ttsTapped), for: .touchUpInside)
        view.addSubview(ttsButton)
        ttsButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            ttsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            ttsButton.bottomAnchor.constraint(equalTo: isEmbeddedMode ? view.bottomAnchor : bottomBar.topAnchor, constant: -20),
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
        // Stop TTS when navigating from TOC
        if isTTSPlaying {
            stopTTS()
        }
        
        Task {
            guard let anyURL = AnyURL(string: link.href) else { return }
            let locator = Locator(
                href: anyURL,
                mediaType: link.mediaType ?? MediaType.html,
                title: link.title
            )
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
        // Stop TTS when navigating from search
        if isTTSPlaying {
            stopTTS()
        }
        
        Task {
            print("Navigating to locator: href=\(locator.href.string), position=\(String(describing: locator.locations.position)), progression=\(String(describing: locator.locations.progression))")
            let success = await navigator?.go(to: locator)
            if success == true {
                print("Navigation successful")
            } else {
                print("Navigation failed, trying alternative approach")
                // If direct navigation fails, try navigating to just the chapter
                let simpleLocator = Locator(
                    href: locator.href,
                    mediaType: locator.mediaType,
                    title: locator.title,
                    locations: Locator.Locations(
                        progression: locator.locations.progression, position: locator.locations.position
                    )
                )
                await navigator?.go(to: simpleLocator)
            }
        }
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
            sheet.prefersGrabberVisible = true
        }
        present(navController, animated: true)
    }
    
    @objc private func prevPage() {
        // Stop TTS when manually navigating
        if isTTSPlaying {
            stopTTS()
        }
        Task { await navigator?.goBackward() }
    }
    
    @objc private func nextPage() {
        // Stop TTS when manually navigating
        if isTTSPlaying {
            stopTTS()
        }
        Task { await navigator?.goForward() }
    }
    
    @objc private func sliderChanged() {
        guard totalLocations > 0 else { return }
        let positionIndex = Int(pageSlider.value)
        
        // Stop TTS when manually navigating
        if isTTSPlaying {
            stopTTS()
        }
        
        Task {
            let positionsResult = await publication.positions()
            if case .success(let positions) = positionsResult, positionIndex < positions.count {
                let locator = positions[positionIndex]
                await navigator?.go(to: locator)
            }
        }
    }
    
    @objc private func ttsTapped() {
        print("TTS: Button tapped, current state: \(isTTSPlaying ? "playing" : "stopped")")
        
        if isTTSPlaying {
            print("TTS: Stopping playback")
            stopTTS()
        } else {
            print("TTS: Starting playback")
            // Provide visual feedback
            ttsButton.alpha = 0.5
            UIView.animate(withDuration: 0.2) {
                self.ttsButton.alpha = 1.0
            }
            startTTS()
        }
    }
    
    @objc private func handleTap() {
        toolbarVisible.toggle()
        UIView.animate(withDuration: 0.3) {
            self.toolbar.alpha = self.toolbarVisible ? 1.0 : 0.0
            if !self.isEmbeddedMode {
                self.bottomBar.alpha = self.toolbarVisible ? 1.0 : 0.0
            }
        }
    }
    
    // MARK: - Helpers
    
    private func updateBookmarkButton() {
        guard let locator = currentLocator else {
            bookmarkButton.setImage(UIImage(systemName: "star"), for: .normal)
            return
        }
        let bookmarkId = locator.href.string + (locator.locations.position?.description ?? "")
        let isBookmarked = ReaderPersistence.shared.listBookmarks(for: publicationFileName).contains { $0.id == bookmarkId }
        bookmarkButton.setImage(UIImage(systemName: isBookmarked ? "star.fill" : "star"), for: .normal)
    }
    
    private func updatePageLabel() {
        guard totalLocations > 0 else {
            pageLabel.text = ""
            return
        }
        let currentPage = (currentLocator?.locations.position ?? 0) + 1
        pageLabel.text = "Location \(currentPage) of \(totalLocations)"
    }
    
    private func startTTS() {
        // Cancel any existing TTS task
        ttsTask?.cancel()
        
        // Reactivate audio session
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            print("TTS: Audio session reactivated")
        } catch {
            print("TTS: Failed to reactivate audio session: \(error)")
        }
        
        ttsTask = Task {
            // Wait for page to fully load
            print("TTS: Waiting for page to load...")
            try? await Task.sleep(nanoseconds: 800_000_000) // 800ms delay
            
            // Check if task was cancelled
            if Task.isCancelled {
                print("TTS: Task was cancelled, stopping")
                return
            }
            // Extract only visible text on current screen/page
            let javascript = """
            (function() {
                try {
                    // Get viewport dimensions
                    var viewportHeight = window.innerHeight || document.documentElement.clientHeight;
                    var viewportWidth = window.innerWidth || document.documentElement.clientWidth;
                    var scrollTop = window.pageYOffset || document.documentElement.scrollTop;
                    var scrollLeft = window.pageXOffset || document.documentElement.scrollLeft;
                    
                    console.log('Viewport: height=' + viewportHeight + ', scrollTop=' + scrollTop);
                    
                    // Function to check if element is visible in viewport
                    function isElementInViewport(el) {
                        var rect = el.getBoundingClientRect();
                        return (
                            rect.top < viewportHeight &&
                            rect.bottom > 0 &&
                            rect.left < viewportWidth &&
                            rect.right > 0
                        );
                    }
                    
                    // Get all text nodes that are visible
                    var visibleText = [];
                    var walker = document.createTreeWalker(
                        document.body,
                        NodeFilter.SHOW_TEXT,
                        null,
                        false
                    );
                    
                    var node;
                    while (node = walker.nextNode()) {
                        // Skip script and style content
                        var parent = node.parentElement;
                        if (parent && (parent.tagName === 'SCRIPT' || parent.tagName === 'STYLE' || parent.tagName === 'NOSCRIPT')) {
                            continue;
                        }
                        
                        // Check if parent element is visible
                        if (parent && isElementInViewport(parent)) {
                            var text = node.textContent.trim();
                            if (text.length > 0) {
                                visibleText.push(text);
                            }
                        }
                    }
                    
                    // Join all visible text
                    var result = visibleText.join(' ');
                    
                    // Clean up whitespace
                    result = result.replace(/\\s+/g, ' ').trim();
                    
                    console.log('TTS extracted visible text length:', result.length);
                    console.log('TTS text preview:', result.substring(0, 100));
                    return result;
                } catch (error) {
                    console.error('TTS extraction error:', error);
                    return '';
                }
            })();
            """
            
            do {
                print("TTS: Starting text extraction...")
                guard let navigator = navigator else {
                    print("TTS: Navigator is nil")
                    await MainActor.run { self.showTTSError("Navigator not ready") }
                    return
                }
                
                let result = try await navigator.evaluateJavaScript(javascript)
                print("TTS: JavaScript result type: \(type(of: result))")
                
                // Handle Result type from Readium
                var extractedText: String?
                
                if let text = result as? String {
                    extractedText = text
                } else if let resultValue = result as? Result<Any, Error> {
                    // Unwrap Result type
                    switch resultValue {
                    case .success(let value):
                        print("TTS: Unwrapping Result.success, value type: \(type(of: value))")
                        extractedText = value as? String
                    case .failure(let error):
                        print("TTS: Result.failure: \(error)")
                        throw error
                    }
                } else {
                    // Try direct conversion
                    extractedText = "\(result)"
                }
                
                if let text = extractedText {
                    print("TTS: Extracted text length: \(text.count)")
                    let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if !trimmedText.isEmpty {
                        print("TTS: Starting speech synthesis with \(trimmedText.count) characters")
                        await MainActor.run {
                            // Limit text to prevent overly long utterances
                            let maxLength = 5000
                            let textToSpeak = trimmedText.count > maxLength ? String(trimmedText.prefix(maxLength)) : trimmedText
                            
                            let utterance = AVSpeechUtterance(string: textToSpeak)
                            utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 1.1 // Slightly faster
                            utterance.volume = 1.0
                            utterance.pitchMultiplier = 1.0
                            
                            // Use default voice for current language
                            if let voice = AVSpeechSynthesisVoice(language: "en-US") {
                                utterance.voice = voice
                            }
                            
                            self.speechSynthesizer.speak(utterance)
                            self.isTTSPlaying = true
                            self.ttsButton.setImage(UIImage(systemName: "pause.circle.fill"), for: .normal)
                            print("TTS: Speech started successfully")
                        }
                    } else {
                        print("TTS: No text found on page, trying to advance")
                        await MainActor.run {
                            self.didFinishSpeechAndShouldContinue()
                        }
                    }
                } else {
                    print("TTS: Could not extract string from result: \(String(describing: result))")
                    await MainActor.run {
                        self.showTTSError("Could not extract text from page")
                    }
                }
            } catch {
                print("TTS: Error occurred: \(error)")
                await MainActor.run {
                    self.showTTSError("Failed to read page: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showTTSError(_ message: String) {
        let alert = UIAlertController(
            title: "Text-to-Speech Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
        stopTTS()
    }
    
    private func stopTTS() {
        print("TTS: Stopping speech synthesis")
        
        // Cancel any pending TTS task
        ttsTask?.cancel()
        ttsTask = nil
        
        speechSynthesizer.stopSpeaking(at: .immediate)
        isTTSPlaying = false
        ttsButton.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
        
        // Deactivate audio session when not in use
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            print("TTS: Audio session deactivated")
        } catch {
            print("TTS: Failed to deactivate audio session: \(error)")
        }
    }
    
    private func didFinishSpeechAndShouldContinue() {
        print("TTS: Speech finished, isTTSPlaying: \(isTTSPlaying)")
        if isTTSPlaying {
            Task {
                print("TTS: Attempting to go forward...")
                
                // Mark that we're waiting for new page
                pageLoadedForTTS = false
                
                let moved = await navigator?.goForward()
                print("TTS: Forward navigation result: \(String(describing: moved))")
                
                if moved == true {
                    // Wait longer for page to fully load after auto-navigation
                    print("TTS: Waiting for page to load after navigation...")
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    print("TTS: Page changed, restarting TTS")
                    startTTS()
                } else {
                    print("TTS: Cannot move forward, stopping TTS")
                    await MainActor.run {
                        self.stopTTS()
                        let alert = UIAlertController(
                            title: "Reading Complete",
                            message: "Reached the end of the content.",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true)
                    }
                }
            }
        }
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
        
        // Mark page as loaded
        pageLoadedForTTS = true
        print("TTS: Page loaded at position \(locator.locations.position ?? -1)")
    }
    
    func navigator(_ navigator: Navigator, presentError error: NavigatorError) {
        print("Navigator error: \(error)")
        let alert = UIAlertController(
            title: "Navigation Error",
            message: "An error occurred while navigating the publication.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - ReaderSettingsDelegate

extension ReaderViewController: ReaderSettingsDelegate {
    func settingsDidChange() {
        applySettings()
    }
    
    private func applySettings() {
        let settings = ReaderSettings.shared
        
        guard let navigator = navigator else { return }
        
        // Create EPUBPreferences object
        var preferences = EPUBPreferences()
        
        // Apply scroll mode setting
        preferences.scroll = settings.scrollMode == .continuous
        
        // Apply preferences to navigator
        Task {
            do {
                try await navigator.submitPreferences(preferences)
                print("Settings applied successfully: scroll=\(preferences.scroll)")
                
                // Apply CSS-based settings (font size, theme, line spacing)
                await applyCSSSettings()
            } catch {
                print("Failed to apply settings: \(error)")
            }
        }
    }
    
    private func applyCSSSettings() async {
        let settings = ReaderSettings.shared
        
        // Build CSS based on settings
        var backgroundColor = "#FFFFFF"
        var textColor = "#000000"
        
        switch settings.theme {
        case .light:
            backgroundColor = "#FFFFFF"
            textColor = "#000000"
        case .dark:
            backgroundColor = "#1C1C1E"
            textColor = "#FFFFFF"
        case .sepia:
            backgroundColor = "#F4ECD8"
            textColor = "#5B4636"
        }
        
        let css = """
        body {
            font-size: \(settings.fontSize)px !important;
            line-height: \(settings.lineSpacing) !important;
            background-color: \(backgroundColor) !important;
            color: \(textColor) !important;
        }
        
        p, div, span, li, td, th {
            font-size: \(settings.fontSize)px !important;
            line-height: \(settings.lineSpacing) !important;
            color: \(textColor) !important;
        }
        
        h1 { font-size: \(settings.fontSize + 8)px !important; }
        h2 { font-size: \(settings.fontSize + 6)px !important; }
        h3 { font-size: \(settings.fontSize + 4)px !important; }
        h4 { font-size: \(settings.fontSize + 2)px !important; }
        h5 { font-size: \(settings.fontSize + 1)px !important; }
        h6 { font-size: \(settings.fontSize)px !important; }
        """
        
        let javascript = """
        (function() {
            // Remove existing custom style if present
            var existingStyle = document.getElementById('reader-custom-style');
            if (existingStyle) {
                existingStyle.remove();
            }
            
            // Create and inject new style
            var style = document.createElement('style');
            style.id = 'reader-custom-style';
            style.textContent = `\(css)`;
            document.head.appendChild(style);
        })();
        """
        
        do {
            _ = try await navigator?.evaluateJavaScript(javascript)
            print("CSS settings applied successfully")
        } catch {
            print("Failed to apply CSS settings: \(error)")
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension ReaderViewController: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        print("TTS: Speech started - text length: \(utterance.speechString.count)")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("TTS: Speech finished normally")
        didFinishSpeechAndShouldContinue()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        print("TTS: Speech was cancelled")
        isTTSPlaying = false
        ttsButton.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        print("TTS: Speech was paused")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        print("TTS: Speech was continued")
    }
}

extension ReaderViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
