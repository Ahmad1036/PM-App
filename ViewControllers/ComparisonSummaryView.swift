//
//  ComparisonSummaryView.swift
//  PM-App
//
//  Dynamic comparison summary view
//

import UIKit

// Data structure for a single comparison result
struct ComparisonResult {
    let topic: String
    let snippet: String
    let sourceStandard: String
    let side: CompareViewController.Side // To know which reader it came from
}

class ComparisonSummaryView: UIView, UITableViewDelegate, UITableViewDataSource {
    
    // Callback to inform the controller that a result was tapped for deep linking
    var onResultTapped: ((ComparisonResult) -> Void)?
    
    // MARK: - Data
    private var similarities: [ComparisonResult] = []
    private var differences: [ComparisonResult] = []
    
    enum Section: Int, CaseIterable {
        case similarities = 0
        case differences = 1
    }
    
    // MARK: - UI Components
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .clear // Background is handled by the sheet's material
        
        addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.register(ComparisonResultCell.self, forCellReuseIdentifier: "ResultCell")
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    // MARK: - Public Method to Update Content
    func updateContent(similarities: [ComparisonResult], differences: [ComparisonResult]) {
        self.similarities = similarities
        self.differences = differences
        tableView.reloadData()
    }
    
    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionType = Section(rawValue: section) else { return 0 }
        switch sectionType {
        case .similarities:
            return max(1, similarities.count) // Show a "None found" cell if empty
        case .differences:
            return max(1, differences.count)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let sectionType = Section(rawValue: indexPath.section) else { return UITableViewCell() }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ResultCell", for: indexPath) as! ComparisonResultCell
        
        switch sectionType {
        case .similarities:
            if similarities.isEmpty {
                cell.configureAsPlaceholder(text: "No direct similarities found on these pages.")
            } else {
                let result = similarities[indexPath.row]
                cell.configure(with: result, icon: "checkmark.circle.fill", color: .systemBlue)
            }
        case .differences:
            if differences.isEmpty {
                cell.configureAsPlaceholder(text: "No unique points found on these pages.")
            } else {
                let result = differences[indexPath.row]
                cell.configure(with: result, icon: "sparkles", color: .systemPurple)
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sectionType = Section(rawValue: section) else { return nil }
        switch sectionType {
        case .similarities:
            return "Similar Concepts"
        case .differences:
            return "Unique Points"
        }
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let sectionType = Section(rawValue: indexPath.section) else { return }
        
        let result: ComparisonResult?
        switch sectionType {
        case .similarities:
            result = similarities.isEmpty ? nil : similarities[indexPath.row]
        case .differences:
            result = differences.isEmpty ? nil : differences[indexPath.row]
        }
        
        if let selectedResult = result {
            // Use the callback to trigger the deep link
            onResultTapped?(selectedResult)
        }
    }
}


// MARK: - Comparison Result Cell
private class ComparisonResultCell: UITableViewCell {
    
    private let iconImageView = UIImageView()
    private let topicLabel = UILabel()
    private let sourceLabel = UILabel()
    private let snippetLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        
        iconImageView.contentMode = .scaleAspectFit
        
        topicLabel.font = Typography.bodyMedium()
        topicLabel.textColor = .pmTextPrimary
        
        sourceLabel.font = Typography.caption()
        sourceLabel.textColor = .pmTextSecondary
        
        snippetLabel.font = Typography.body()
        snippetLabel.textColor = .pmTextSecondary
        snippetLabel.numberOfLines = 2
        
        let headerStack = UIStackView(arrangedSubviews: [topicLabel, sourceLabel])
        headerStack.axis = .vertical
        headerStack.spacing = 2
        
        let mainStack = UIStackView(arrangedSubviews: [iconImageView, headerStack, snippetLabel])
        mainStack.axis = .vertical
        mainStack.spacing = 8
        mainStack.alignment = .leading
        
        contentView.addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 22),
            iconImageView.heightAnchor.constraint(equalToConstant: 22),
            
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with result: ComparisonResult, icon: String, color: UIColor) {
        topicLabel.text = result.topic
        sourceLabel.text = "Found in: \(result.sourceStandard)"
        snippetLabel.text = result.snippet
        iconImageView.image = UIImage(systemName: icon)
        iconImageView.tintColor = color
        
        topicLabel.alpha = 1.0
        sourceLabel.alpha = 1.0
        snippetLabel.alpha = 1.0
        iconImageView.isHidden = false
        accessoryType = .disclosureIndicator
        selectionStyle = .default
    }
    
    func configureAsPlaceholder(text: String) {
        topicLabel.text = text
        topicLabel.alpha = 0.6
        
        sourceLabel.text = ""
        snippetLabel.text = ""
        iconImageView.isHidden = true
        accessoryType = .none
        selectionStyle = .none
    }
}
