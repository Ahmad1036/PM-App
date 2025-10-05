//
//  GenerateViewController.swift
//  PM-App
//
//  Created by usear on 10/4/25.
//
import UIKit

class GenerateViewController: UIViewController {

    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private lazy var projectTypePicker: UIPickerView = {
        let picker = UIPickerView()
        picker.dataSource = self
        picker.delegate = self
        picker.tag = 0
        return picker
    }()
    
    private lazy var projectScalePicker: UIPickerView = {
        let picker = UIPickerView()
        picker.dataSource = self
        picker.delegate = self
        picker.tag = 1
        return picker
    }()
    
    private lazy var standardPicker: UIPickerView = {
        let picker = UIPickerView()
        picker.dataSource = self
        picker.delegate = self
        picker.tag = 2
        return picker
    }()
    
    private let generateButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Generate Process", for: .normal)
        button.titleLabel?.font = Typography.bodyMedium()
        button.setTitleColor(.pmBlack, for: .normal)
        button.addTarget(self, action: #selector(generateButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private let resultContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .pmSurface
        view.layer.cornerRadius = CornerRadius.card
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 8
        view.layer.shadowOpacity = 0.06
        view.isHidden = true
        return view
    }()
    
    private let resultTextView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.font = Typography.body()
        textView.textColor = .pmTextPrimary
        textView.backgroundColor = .clear
        textView.text = ""
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        return textView
    }()
    
    private let actionButtonsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 12
        return stack
    }()
    
    private lazy var modifyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Modify Inputs", for: .normal)
        button.titleLabel?.font = Typography.body()
        button.setTitleColor(.pmBlack, for: .normal)
        button.addTarget(self, action: #selector(modifyInputsTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var regenerateButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Regenerate", for: .normal)
        button.titleLabel?.font = Typography.body()
        button.setTitleColor(.pmBlack, for: .normal)
        button.addTarget(self, action: #selector(regenerateButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var shareButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Share", for: .normal)
        button.titleLabel?.font = Typography.body()
        button.setTitleColor(.pmBlack, for: .normal)
        button.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Data
    private let projectTypes = ProcessGenerator.ProjectType.allCases
    private let projectScales = ProcessGenerator.ProjectScale.allCases
    private let standards = StandardsData.allStandards
    private var hasGenerated = false

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Process Generator"
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
        
        setupUI()
        
        // Apply liquid glass to buttons after setup (no green)
        LiquidGlassStyle.applyToButton(generateButton, tintColor: .white.withAlphaComponent(0.25))
        LiquidGlassStyle.applyToButton(modifyButton, tintColor: .pmCoral.withAlphaComponent(0.12))
        LiquidGlassStyle.applyToButton(regenerateButton, tintColor: .white.withAlphaComponent(0.2))
        LiquidGlassStyle.applyToButton(shareButton, tintColor: .systemPurple.withAlphaComponent(0.15))
    }

    // MARK: - UI Setup
    private func setupUI() {
        // Setup scroll view for smaller screens
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // Setup main stack view
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 25
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
        
        // Add components to stack view
        stackView.addArrangedSubview(createSection(title: "Project Type", picker: projectTypePicker))
        stackView.addArrangedSubview(createSection(title: "Project Scale", picker: projectScalePicker))
        stackView.addArrangedSubview(createSection(title: "Preferred Standard", picker: standardPicker))
        stackView.addArrangedSubview(generateButton)
        stackView.addArrangedSubview(resultContainerView)
        
        // Setup result container
        resultContainerView.addSubview(resultTextView)
        resultContainerView.addSubview(actionButtonsStack)
        
        resultTextView.translatesAutoresizingMaskIntoConstraints = false
        actionButtonsStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Add action buttons to stack
        actionButtonsStack.addArrangedSubview(modifyButton)
        actionButtonsStack.addArrangedSubview(regenerateButton)
        actionButtonsStack.addArrangedSubview(shareButton)

        // Layout
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            generateButton.heightAnchor.constraint(equalToConstant: 50),
            resultContainerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 400),
            
            // Result container layout
            resultTextView.topAnchor.constraint(equalTo: resultContainerView.topAnchor, constant: 12),
            resultTextView.leadingAnchor.constraint(equalTo: resultContainerView.leadingAnchor),
            resultTextView.trailingAnchor.constraint(equalTo: resultContainerView.trailingAnchor),
            resultTextView.bottomAnchor.constraint(equalTo: actionButtonsStack.topAnchor, constant: -12),
            
            actionButtonsStack.leadingAnchor.constraint(equalTo: resultContainerView.leadingAnchor, constant: 16),
            actionButtonsStack.trailingAnchor.constraint(equalTo: resultContainerView.trailingAnchor, constant: -16),
            actionButtonsStack.bottomAnchor.constraint(equalTo: resultContainerView.bottomAnchor, constant: -16),
            actionButtonsStack.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func createSection(title: String, picker: UIPickerView) -> UIView {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        
        let stack = UIStackView(arrangedSubviews: [label, picker])
        stack.axis = .vertical
        stack.spacing = 8
        picker.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        return stack
    }

    // MARK: - Actions
    @objc private func generateButtonTapped() {
        generateProcess()
    }
    
    @objc private func regenerateButtonTapped() {
        // Add a subtle animation
        UIView.transition(with: resultTextView,
                         duration: 0.3,
                         options: .transitionCrossDissolve,
                         animations: {
            self.generateProcess()
        })
    }
    
    @objc private func modifyInputsTapped() {
        // Scroll to top to show pickers
        scrollView.setContentOffset(.zero, animated: true)
        
        // Optional: hide result temporarily
        UIView.animate(withDuration: 0.3) {
            self.resultContainerView.alpha = 0.5
        } completion: { _ in
            UIView.animate(withDuration: 0.3) {
                self.resultContainerView.alpha = 1.0
            }
        }
    }
    
    @objc private func shareButtonTapped() {
        guard hasGenerated, !resultTextView.text.isEmpty else { return }
        
        let textToShare = resultTextView.text ?? ""
        let activityVC = UIActivityViewController(
            activityItems: [textToShare],
            applicationActivities: nil
        )
        
        // For iPad support
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = shareButton
            popover.sourceRect = shareButton.bounds
        }
        
        present(activityVC, animated: true)
    }
    
    // MARK: - Helper Methods
    
    private func generateProcess() {
        let selectedType = projectTypes[projectTypePicker.selectedRow(inComponent: 0)]
        let selectedScale = projectScales[projectScalePicker.selectedRow(inComponent: 0)]
        let selectedStandard = standards[standardPicker.selectedRow(inComponent: 0)]
        
        let generatedText = ProcessGenerator.generate(
            type: selectedType,
            scale: selectedScale,
            standard: selectedStandard
        )
        
        resultTextView.text = generatedText
        
        // Show result container if first generation
        if !hasGenerated {
            resultContainerView.isHidden = false
            hasGenerated = true
            
            // Animate appearance
            resultContainerView.alpha = 0
            resultContainerView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseOut) {
                self.resultContainerView.alpha = 1.0
                self.resultContainerView.transform = .identity
            }
            
            // Scroll to show result
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                let resultFrame = self.resultContainerView.frame
                let scrollOffset = CGPoint(x: 0, y: resultFrame.origin.y - 20)
                self.scrollView.setContentOffset(scrollOffset, animated: true)
            }
        }
    }
}

// MARK: - UIPickerViewDataSource & Delegate
extension GenerateViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView.tag {
        case 0: return projectTypes.count
        case 1: return projectScales.count
        case 2: return standards.count
        default: return 0
        }
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView.tag {
        case 0: return projectTypes[row].rawValue
        case 1: return projectScales[row].rawValue
        case 2: return standards[row].title
        default: return nil
        }
    }
}
