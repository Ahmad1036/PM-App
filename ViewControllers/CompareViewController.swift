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
    private let leftHeaderButton = UIButton(type: .system)
    private let rightHeaderButton = UIButton(type: .system)
    private let compareButton = UIButton(type: .system)

    // MARK: - Reader Data
    private var leftStandard: Standard?
    private var rightStandard: Standard?
    private var leftReaderVC: ReaderViewController?
    private var rightReaderVC: ReaderViewController?

    // MARK: - Comparison Logic
    private let analysisTopics: [String: [String]] = [
        "Scope Management": ["scope", "requirements", "wbs", "work breakdown"],
        "Risk Management": ["risk", "threat", "opportunity", "issue"],
        "Stakeholder Engagement": ["stakeholder", "communication", "engagement"],
        "Quality Management": ["quality", "assurance", "control", "testing"],
        "Schedule Management": ["schedule", "timeline", "milestone", "gantt"],
        "Cost Management": ["cost", "budget", "estimate", "finance"],
        "Project Governance": ["governance", "roles", "responsibilities", "project board"],
        "Business Case": ["business case", "justification", "benefits", "roi"],
        "Change Control": ["change control", "change request", "variation"]
    ]

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Compare Standards"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .pmBackground
        
        if let navigationBar = navigationController?.navigationBar {
            navigationBar.largeTitleTextAttributes = [.font: Typography.largeTitle(), .foregroundColor: UIColor.pmTextPrimary]
            navigationBar.titleTextAttributes = [.font: Typography.bodyMedium(), .foregroundColor: UIColor.pmTextPrimary]
        }
        
        applySplitViewSettings()
        setupSplitView()
        loadDefaultStandards()
    }
    
    // MARK: - Setup
    private func applySplitViewSettings() {
        let settings = ReaderSettings.shared
        settings.fontSize = 14
        settings.scrollMode = .paginated
        settings.lineSpacing = 1.2
        settings.theme = .light
    }

    private func setupSplitView() {
        // Create headers
        let leftHeader = createHeaderView(button: leftHeaderButton, side: .left)
        let rightHeader = createHeaderView(button: rightHeaderButton, side: .right)
        
        let headerStack = UIStackView(arrangedSubviews: [leftHeader, rightHeader])
        headerStack.distribution = .fillEqually
        headerStack.spacing = 1
        headerStack.backgroundColor = .systemGray4
        
        // Create reader containers
        let readerStack = UIStackView(arrangedSubviews: [leftContainer, rightContainer])
        readerStack.distribution = .fillEqually
        readerStack.spacing = 1
        readerStack.backgroundColor = .systemGray4
        
        // Setup compare button with new style
        compareButton.setTitle("Compare Current Pages", for: .normal)
        PrimaryButtonStyle.applyTo(compareButton, backgroundColor: .pmMintDark)
        compareButton.addTarget(self, action: #selector(compareButtonTapped), for: .touchUpInside)
        
        view.addSubview(headerStack)
        view.addSubview(readerStack)
        view.addSubview(compareButton)
        
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        readerStack.translatesAutoresizingMaskIntoConstraints = false
        compareButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerStack.heightAnchor.constraint(equalToConstant: 44),
            
            readerStack.topAnchor.constraint(equalTo: headerStack.bottomAnchor),
            readerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            readerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            readerStack.bottomAnchor.constraint(equalTo: compareButton.topAnchor, constant: -Spacing.sm),
            
            compareButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.md),
            compareButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.md),
            compareButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Spacing.xs),
            compareButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func createHeaderView(button: UIButton, side: Side) -> UIView {
        let container = UIView()
        container.backgroundColor = .pmSurface
        
        button.setTitle("Select...", for: .normal)
        button.titleLabel?.font = Typography.bodyMedium()
        button.setTitleColor(.pmTextPrimary, for: .normal)
        button.backgroundColor = .pmSoftGray
        button.layer.cornerRadius = 8
        button.addTarget(self, action: side == .left ? #selector(selectLeftBook) : #selector(selectRightBook), for: .touchUpInside)
        
        container.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: container.topAnchor, constant: 6),
            button.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -6),
            button.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            button.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8)
        ])
        
        return container
    }
    
    private func loadDefaultStandards() {
        if let pmbok = StandardsData.allStandards.first(where: { $0.fileName == "PMBOK" }) {
            loadStandard(pmbok, in: .left)
        }
        if let prince2 = StandardsData.allStandards.first(where: { $0.fileName == "PRINCE2" }) {
            loadStandard(prince2, in: .right)
        }
    }
    
    private func loadStandard(_ standard: Standard, in side: Side) {
        Task {
            if let publication = await RediumHelper.shared.loadPublication(for: standard, from: self) {
                await MainActor.run {
                    embedReader(publication: publication, standard: standard, in: side)
                }
            }
        }
    }
    
    private func embedReader(publication: Publication, standard: Standard, in side: Side) {
        let existingReader = side == .left ? leftReaderVC : rightReaderVC
        existingReader?.willMove(toParent: nil)
        existingReader?.view.removeFromSuperview()
        existingReader?.removeFromParent()
        
        applySplitViewSettings()
        
        let readerVC = ReaderViewController(
            publication: publication,
            publicationFileName: standard.fileName,
            httpServer: RediumHelper.shared.httpServer,
            isEmbedded: true
        )
        
        if side == .left {
            leftReaderVC = readerVC
            leftStandard = standard
            leftHeaderButton.setTitle(standard.title, for: .normal)
        } else {
            rightReaderVC = readerVC
            rightStandard = standard
            rightHeaderButton.setTitle(standard.title, for: .normal)
        }
        
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
    }
    
    // MARK: - Actions & Comparison Logic
    
    @objc private func compareButtonTapped() {
        let button = compareButton
        button.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        UIView.animate(withDuration: 0.2) {
            button.transform = .identity
        }
        
        Task {
            guard let leftReader = leftReaderVC, let rightReader = rightReaderVC,
                  let leftStandard = leftStandard, let rightStandard = rightStandard else { return }
            
            let leftText = await leftReader.extractVisibleText().lowercased()
            let rightText = await rightReader.extractVisibleText().lowercased()
            
            var similarities = [ComparisonResult]()
            var differences = [ComparisonResult]()
            
            for (topic, keywords) in analysisTopics {
                let leftMatches = keywords.filter { leftText.contains($0) }
                let rightMatches = keywords.filter { rightText.contains($0) }
                
                if !leftMatches.isEmpty && !rightMatches.isEmpty {
                    let snippet = "Both standards discuss topics related to '\(leftMatches.first!)'."
                    similarities.append(ComparisonResult(topic: topic, snippet: snippet, sourceStandard: "\(leftStandard.title) & \(rightStandard.title)", side: .left))
                } else if !leftMatches.isEmpty {
                    let snippet = "Mentions '\(leftMatches.first!)', a key aspect of this topic."
                    differences.append(ComparisonResult(topic: topic, snippet: snippet, sourceStandard: leftStandard.title, side: .left))
                } else if !rightMatches.isEmpty {
                    let snippet = "Mentions '\(rightMatches.first!)', a key aspect of this topic."
                    differences.append(ComparisonResult(topic: topic, snippet: snippet, sourceStandard: rightStandard.title, side: .right))
                }
            }
            
            await MainActor.run {
                presentComparisonResults(similarities: similarities, differences: differences)
            }
        }
    }
    
    private func presentComparisonResults(similarities: [ComparisonResult], differences: [ComparisonResult]) {
        let summaryVC = UIViewController()
        let summaryView = ComparisonSummaryView()
        
        summaryVC.view.addSubview(summaryView)
        summaryView.translatesAutoresizingMaskIntoConstraints = false
        summaryView.updateContent(similarities: similarities, differences: differences)
        
        summaryView.onResultTapped = { [weak self] result in
            self?.dismiss(animated: true) { self?.handleDeepLink(for: result) }
        }
        
        NSLayoutConstraint.activate([
            summaryView.topAnchor.constraint(equalTo: summaryVC.view.safeAreaLayoutGuide.topAnchor),
            summaryView.leadingAnchor.constraint(equalTo: summaryVC.view.leadingAnchor),
            summaryView.trailingAnchor.constraint(equalTo: summaryVC.view.trailingAnchor),
            summaryView.bottomAnchor.constraint(equalTo: summaryVC.view.bottomAnchor)
        ])
        
        let navController = UINavigationController(rootViewController: summaryVC)
        navController.navigationBar.topItem?.title = "Comparison Results"
        
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(navController, animated: true)
    }
    
    private func handleDeepLink(for result: ComparisonResult) {
        Task {
            let readerToSearch = (result.side == .left) ? leftReaderVC : rightReaderVC
            if let keyword = analysisTopics[result.topic]?.first {
                await readerToSearch?.findAndHighlight(text: keyword)
            }
        }
    }
    
    @objc private func selectLeftBook() { showBookSelector(for: .left) }
    @objc private func selectRightBook() { showBookSelector(for: .right) }
    
    private func showBookSelector(for side: Side) {
        let alert = UIAlertController(title: "Select Standard", message: nil, preferredStyle: .actionSheet)
        
        for standard in StandardsData.allStandards {
            alert.addAction(UIAlertAction(title: standard.title, style: .default) { [weak self] _ in
                self?.loadStandard(standard, in: side)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let popover = alert.popoverPresentationController {
            popover.sourceView = side == .left ? leftHeaderButton : rightHeaderButton
        }
        present(alert, animated: true)
    }

    enum Side { case left, right }
}
