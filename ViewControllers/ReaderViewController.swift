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
        setupNavigator()
        setupUI()
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
                view.addSubview(navigator.view)
                navigator.view.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    navigator.view.topAnchor.constraint(equalTo: view.topAnchor),
                    navigator.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                    navigator.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                    navigator.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
                ])
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
        Task {
            await navigator?.go(to: locator)
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
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        present(navController, animated: true)
    }
    
    @objc private func prevPage() {
        Task { await navigator?.goBackward() }
    }
    
    @objc private func nextPage() {
        Task { await navigator?.goForward() }
    }
    
    @objc private func sliderChanged() {
        guard totalLocations > 0 else { return }
        let positionIndex = Int(pageSlider.value)
        
        Task {
            let positionsResult = await publication.positions()
            if case .success(let positions) = positionsResult, positionIndex < positions.count {
                let locator = positions[positionIndex]
                await navigator?.go(to: locator)
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
        Task {
            let javascript = "document.body.textContent"
            do {
                if let text = try await navigator?.evaluateJavaScript(javascript) as? String, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    let utterance = AVSpeechUtterance(string: text)
                    utterance.rate = AVSpeechUtteranceDefaultSpeechRate
                    speechSynthesizer.speak(utterance)
                    isTTSPlaying = true
                    ttsButton.setImage(UIImage(systemName: "pause.circle.fill"), for: .normal)
                } else {
                    await MainActor.run { didFinishSpeechAndShouldContinue() }
                }
            } catch {
                print("Failed to get text for TTS: \(error)")
                stopTTS()
            }
        }
    }
    
    private func stopTTS() {
        speechSynthesizer.stopSpeaking(at: .immediate)
        isTTSPlaying = false
        ttsButton.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
    }
    
    private func didFinishSpeechAndShouldContinue() {
        if isTTSPlaying {
            Task {
                let moved = await navigator?.goForward()
                if moved == true {
                    try? await Task.sleep(for: .milliseconds(500))
                    startTTS()
                } else {
                    stopTTS()
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
        // Settings application would go here
        // The exact API depends on your Readium version
        print("Settings changed - apply new settings")
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension ReaderViewController: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        didFinishSpeechAndShouldContinue()
    }
}

extension ReaderViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
