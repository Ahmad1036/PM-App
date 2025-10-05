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
        button.titleLabel?.font = .boldSystemFont(ofSize: 18)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(generateButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private let resultTextView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.font = .monospacedSystemFont(ofSize: 15, weight: .regular)
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 8
        textView.text = "Your generated process summary will appear here..."
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        return textView
    }()
    
    // MARK: - Data
    private let projectTypes = ProcessGenerator.ProjectType.allCases
    private let projectScales = ProcessGenerator.ProjectScale.allCases
    private let standards = StandardsData.allStandards

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Process Generator"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemBackground
        setupUI()
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
        stackView.addArrangedSubview(resultTextView)

        // Layout
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            generateButton.heightAnchor.constraint(equalToConstant: 50),
            resultTextView.heightAnchor.constraint(equalToConstant: 300)
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
        let selectedType = projectTypes[projectTypePicker.selectedRow(inComponent: 0)]
        let selectedScale = projectScales[projectScalePicker.selectedRow(inComponent: 0)]
        let selectedStandard = standards[standardPicker.selectedRow(inComponent: 0)]
        
        resultTextView.text = ProcessGenerator.generate(
            type: selectedType,
            scale: selectedScale,
            standard: selectedStandard
        )
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
