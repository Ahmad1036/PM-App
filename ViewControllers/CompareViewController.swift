//
//  CompareViewController.swift
//  PM-App
//
//  Created by usear on 10/4/25.
//  Updated to use Readium instead of FolioKit
//
import UIKit

class CompareViewController: UIViewController {

    private let leftContainer = UIView()
    private let rightContainer = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Compare Standards"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemBackground
        setupSplitView()
        loadStandardsForComparison()
    }

    private func setupSplitView() {
        let stackView = UIStackView(arrangedSubviews: [leftContainer, rightContainer])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 1.0
        stackView.backgroundColor = .systemGray4
        
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func loadStandardsForComparison() {
        // For the MVP, we hardcode PMBOK vs. PRINCE2 for comparison.
        guard let pmbok = StandardsData.allStandards.first(where: { $0.fileName == "PMBOK" }),
              let prince2 = StandardsData.allStandards.first(where: { $0.fileName == "PRINCE2" }) else {
            print("Error: Could not find PMBOK or PRINCE2 epub files for comparison.")
            return
        }

        // Embed each reader's view into container views using Readium
        embedReader(for: pmbok, in: leftContainer)
        embedReader(for: prince2, in: rightContainer)
    }

    private func embedReader(for standard: Standard, in containerView: UIView) {
        // Create header label
        let label = UILabel()
        label.text = standard.title
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.backgroundColor = .systemBackground
        
        containerView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        // Create reader container
        let readerContainer = UIView()
        readerContainer.backgroundColor = .secondarySystemBackground
        containerView.addSubview(readerContainer)
        readerContainer.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: containerView.topAnchor),
            label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            label.heightAnchor.constraint(equalToConstant: 40),
            
            readerContainer.topAnchor.constraint(equalTo: label.bottomAnchor),
            readerContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            readerContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            readerContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])
        
        // Embed EPUB reader
        RediumHelper.shared.openEmbeddedReader(
            for: standard,
            in: self,
            containerView: readerContainer
        )
    }
}
