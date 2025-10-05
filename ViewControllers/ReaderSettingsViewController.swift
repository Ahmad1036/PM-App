//
//  ReaderSettingsViewController.swift
//  PM-App
//
//  Settings panel for ReaderViewController with ReadiumCSS integration
//

import UIKit

protocol ReaderSettingsDelegate: AnyObject {
    func settingsDidChange()
}

class ReaderSettingsViewController: UIViewController {
    
    // MARK: - Properties
    
    weak var delegate: ReaderSettingsDelegate?
    private let settings = ReaderSettings.shared
    
    // MARK: - UI Components
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Font Size
    private let fontSizeLabel = UILabel()
    private let fontSizeStepper = UIStepper()
    private let fontSizeValueLabel = UILabel()
    
    // Theme
    private let themeLabel = UILabel()
    private let themeSegmentedControl = UISegmentedControl(items: ["Light", "Dark", "Sepia"])
    
    // Scroll Mode
    private let scrollModeLabel = UILabel()
    private let scrollModeSegmentedControl = UISegmentedControl(items: ["Paginated", "Continuous"])
    
    // Line Spacing
    private let lineSpacingLabel = UILabel()
    private let lineSpacingSlider = UISlider()
    private let lineSpacingValueLabel = UILabel()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadCurrentSettings()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Reader Settings"
        
        // Setup navigation bar
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneTapped)
        )
        
        // Setup scroll view
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        setupControls()
    }
    
    private func setupControls() {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 30
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
        
        // Font Size Section
        let fontSizeSection = createFontSizeSection()
        stackView.addArrangedSubview(fontSizeSection)
        
        // Theme Section
        let themeSection = createThemeSection()
        stackView.addArrangedSubview(themeSection)
        
        // Scroll Mode Section
        let scrollModeSection = createScrollModeSection()
        stackView.addArrangedSubview(scrollModeSection)
        
        // Line Spacing Section
        let lineSpacingSection = createLineSpacingSection()
        stackView.addArrangedSubview(lineSpacingSection)
        
        // Layout
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func createFontSizeSection() -> UIView {
        let container = UIView()
        
        fontSizeLabel.text = "Font Size"
        fontSizeLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        
        fontSizeStepper.minimumValue = 12
        fontSizeStepper.maximumValue = 24
        fontSizeStepper.stepValue = 1
        fontSizeStepper.addTarget(self, action: #selector(fontSizeChanged), for: .valueChanged)
        
        fontSizeValueLabel.text = "16"
        fontSizeValueLabel.font = .systemFont(ofSize: 16)
        fontSizeValueLabel.textAlignment = .center
        fontSizeValueLabel.widthAnchor.constraint(equalToConstant: 40).isActive = true
        
        let stepperStack = UIStackView(arrangedSubviews: [fontSizeStepper, fontSizeValueLabel])
        stepperStack.axis = .horizontal
        stepperStack.spacing = 16
        stepperStack.alignment = .center
        
        let stack = UIStackView(arrangedSubviews: [fontSizeLabel, stepperStack])
        stack.axis = .vertical
        stack.spacing = 12
        
        container.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    private func createThemeSection() -> UIView {
        let container = UIView()
        
        themeLabel.text = "Theme"
        themeLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        
        themeSegmentedControl.addTarget(self, action: #selector(themeChanged), for: .valueChanged)
        
        let stack = UIStackView(arrangedSubviews: [themeLabel, themeSegmentedControl])
        stack.axis = .vertical
        stack.spacing = 12
        
        container.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    private func createScrollModeSection() -> UIView {
        let container = UIView()
        
        scrollModeLabel.text = "Scroll Mode"
        scrollModeLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        
        scrollModeSegmentedControl.addTarget(self, action: #selector(scrollModeChanged), for: .valueChanged)
        
        let stack = UIStackView(arrangedSubviews: [scrollModeLabel, scrollModeSegmentedControl])
        stack.axis = .vertical
        stack.spacing = 12
        
        container.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    private func createLineSpacingSection() -> UIView {
        let container = UIView()
        
        lineSpacingLabel.text = "Line Spacing"
        lineSpacingLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        
        lineSpacingSlider.minimumValue = 1.0
        lineSpacingSlider.maximumValue = 2.5
        lineSpacingSlider.addTarget(self, action: #selector(lineSpacingChanged), for: .valueChanged)
        
        lineSpacingValueLabel.text = "1.5"
        lineSpacingValueLabel.font = .systemFont(ofSize: 16)
        lineSpacingValueLabel.textAlignment = .center
        lineSpacingValueLabel.widthAnchor.constraint(equalToConstant: 50).isActive = true
        
        let sliderStack = UIStackView(arrangedSubviews: [lineSpacingSlider, lineSpacingValueLabel])
        sliderStack.axis = .horizontal
        sliderStack.spacing = 16
        sliderStack.alignment = .center
        
        let stack = UIStackView(arrangedSubviews: [lineSpacingLabel, sliderStack])
        stack.axis = .vertical
        stack.spacing = 12
        
        container.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    // MARK: - Actions
    
    @objc private func doneTapped() {
        dismiss(animated: true)
    }
    
    @objc private func fontSizeChanged() {
        let fontSize = Int(fontSizeStepper.value)
        settings.fontSize = fontSize
        fontSizeValueLabel.text = "\(fontSize)"
        delegate?.settingsDidChange()
    }
    
    @objc private func themeChanged() {
        let selectedIndex = themeSegmentedControl.selectedSegmentIndex
        let themes: [ReaderSettings.Theme] = [.light, .dark, .sepia]
        if selectedIndex < themes.count {
            settings.theme = themes[selectedIndex]
            delegate?.settingsDidChange()
        }
    }
    
    @objc private func scrollModeChanged() {
        let selectedIndex = scrollModeSegmentedControl.selectedSegmentIndex
        let modes: [ReaderSettings.ScrollMode] = [.paginated, .continuous]
        if selectedIndex < modes.count {
            settings.scrollMode = modes[selectedIndex]
            delegate?.settingsDidChange()
        }
    }
    
    @objc private func lineSpacingChanged() {
        let lineSpacing = Double(lineSpacingSlider.value)
        settings.lineSpacing = lineSpacing
        lineSpacingValueLabel.text = String(format: "%.1f", lineSpacing)
        delegate?.settingsDidChange()
    }
    
    // MARK: - Helpers
    
    private func loadCurrentSettings() {
        // Load font size
        fontSizeStepper.value = Double(settings.fontSize)
        fontSizeValueLabel.text = "\(settings.fontSize)"
        
        // Load theme
        switch settings.theme {
        case .light:
            themeSegmentedControl.selectedSegmentIndex = 0
        case .dark:
            themeSegmentedControl.selectedSegmentIndex = 1
        case .sepia:
            themeSegmentedControl.selectedSegmentIndex = 2
        }
        
        // Load scroll mode
        switch settings.scrollMode {
        case .paginated:
            scrollModeSegmentedControl.selectedSegmentIndex = 0
        case .continuous:
            scrollModeSegmentedControl.selectedSegmentIndex = 1
        }
        
        // Load line spacing
        lineSpacingSlider.value = Float(settings.lineSpacing)
        lineSpacingValueLabel.text = String(format: "%.1f", settings.lineSpacing)
    }
}
