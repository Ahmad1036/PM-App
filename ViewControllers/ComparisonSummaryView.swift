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
        label.text = "Comparison Summary"
        label.font = Typography.title2()
        label.textColor = .pmTextPrimary
        label.textAlignment = .center
        return label
    }()
    
    private let similaritiesCard = ComparisonCard(
        title: "Similarities",
        icon: "checkmark.circle.fill",
        color: .systemBlue
    )
    
    private let differencesCard = ComparisonCard(
        title: "Differences",
        icon: "arrow.triangle.branch",
        color: .pmCoral
    )
    
    private let uniqueElementsCard = ComparisonCard(
        title: "Unique Elements",
        icon: "sparkles",
        color: .systemPurple
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
        backgroundColor = .pmSurface
        layer.cornerRadius = CornerRadius.card
        
        // Add subtle shadow for depth
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 8
        layer.shadowOpacity = 0.06
        
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
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .pmTextPrimary
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.bodyMedium()
        label.textColor = .pmTextPrimary
        return label
    }()
    
    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.body()
        label.numberOfLines = 0
        label.textColor = .pmTextSecondary
        return label
    }()
    
    private let headerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        return stack
    }()
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        return stack
    }()
    
    init(title: String, icon: String, color: UIColor) {
        super.init(frame: .zero)
        titleLabel.text = title
        iconImageView.image = UIImage(systemName: icon)
        iconImageView.tintColor = color
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Liquid glass effect background
        backgroundColor = .clear
        layer.cornerRadius = CornerRadius.card
        
        // Create glass background container
        let glassContainer = UIView()
        glassContainer.layer.cornerRadius = CornerRadius.card
        glassContainer.clipsToBounds = true
        addSubview(glassContainer)
        glassContainer.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            glassContainer.topAnchor.constraint(equalTo: topAnchor),
            glassContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            glassContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            glassContainer.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        
        // Apply liquid glass effect
        LiquidGlassStyle.applyToView(glassContainer, tintColor: iconImageView.tintColor.withAlphaComponent(0.08))
        
        // Setup header with icon and title
        headerStack.addArrangedSubview(iconImageView)
        headerStack.addArrangedSubview(titleLabel)
        
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.addArrangedSubview(headerStack)
        stackView.addArrangedSubview(contentLabel)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }
    
    func setContent(_ items: [String]) {
        contentLabel.text = items.joined(separator: "\n")
    }
}
