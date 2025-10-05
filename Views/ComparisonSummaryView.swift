//
//  ComparisonSummaryView.swift
//  PM-App
//
//  Simple dummy comparison summary view
//

import UIKit

class ComparisonSummaryView: UIView {
    
    // MARK: - UI Components
    
    private let containerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        stack.distribution = .fill
        return stack
    }()
    
    private let headerLabel: UILabel = {
        let label = UILabel()
        label.text = "📊 Comparison Summary"
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private let similaritiesCard = ComparisonCard(
        title: "🟩 Similarities",
        color: .systemGreen
    )
    
    private let differencesCard = ComparisonCard(
        title: "🟥 Differences",
        color: .systemRed
    )
    
    private let uniqueElementsCard = ComparisonCard(
        title: "🟦 Unique Elements",
        color: .systemBlue
    )
    
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
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGray4.cgColor
        
        addSubview(containerStack)
        containerStack.translatesAutoresizingMaskIntoConstraints = false
        
        containerStack.addArrangedSubview(headerLabel)
        containerStack.addArrangedSubview(similaritiesCard)
        containerStack.addArrangedSubview(differencesCard)
        containerStack.addArrangedSubview(uniqueElementsCard)
        
        NSLayoutConstraint.activate([
            containerStack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            containerStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            containerStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            containerStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
        
        // Set dummy content
        setDummyContent()
    }
    
    private func setDummyContent() {
        similaritiesCard.setContent([
            "• Project planning methodologies",
            "• Risk management frameworks",
            "• Stakeholder engagement strategies",
            "• Quality assurance processes"
        ])
        
        differencesCard.setContent([
            "• PMBOK emphasizes knowledge areas",
            "• PRINCE2 focuses on themes and principles",
            "• Different governance structures",
            "• Varied documentation approaches"
        ])
        
        uniqueElementsCard.setContent([
            "Left: Process groups, PMO structure",
            "Right: Product-based planning, stage gates"
        ])
    }
    
    // MARK: - Public Methods
    
    func updateContent(similarities: [String], differences: [String], unique: [String]) {
        similaritiesCard.setContent(similarities.isEmpty ? ["No similarities found"] : similarities)
        differencesCard.setContent(differences.isEmpty ? ["No differences found"] : differences)
        uniqueElementsCard.setContent(unique.isEmpty ? ["No unique elements found"] : unique)
    }
}

// MARK: - Comparison Card

private class ComparisonCard: UIView {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        return label
    }()
    
    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .fill
        return stack
    }()
    
    init(title: String, color: UIColor) {
        super.init(frame: .zero)
        titleLabel.text = title
        titleLabel.textColor = color
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .systemBackground
        layer.cornerRadius = 8
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGray5.cgColor
        
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(contentLabel)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
    }
    
    func setContent(_ items: [String]) {
        contentLabel.text = items.joined(separator: "\n")
    }
}
