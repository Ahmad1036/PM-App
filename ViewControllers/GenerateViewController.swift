//
//  GenerateViewController.swift
//  PM-App
//
//  Created by usear on 10/4/25.
//
import UIKit

class GenerateViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // MARK: - Data
    private let projectTypes = ProcessGenerator.ProjectType.allCases
    private let projectScales = ProcessGenerator.ProjectScale.allCases
    private let standards = StandardsData.allStandards
    
    // Selections
    private var selectedType = ProcessGenerator.ProjectType.software
    private var selectedScale = ProcessGenerator.ProjectScale.medium
    private var selectedStandard = StandardsData.allStandards.first!

    enum Section: Int, CaseIterable {
        case inputs = 0
        case action = 1
    }
    
    // MARK: - UI Components
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Process Generator"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .pmBackground
        
        if let navigationBar = navigationController?.navigationBar {
            navigationBar.largeTitleTextAttributes = [.font: Typography.largeTitle(), .foregroundColor: UIColor.pmTextPrimary]
            navigationBar.titleTextAttributes = [.font: Typography.bodyMedium(), .foregroundColor: UIColor.pmTextPrimary]
        }
        
        setupTableView()
    }

    // MARK: - UI Setup
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "InputCell")
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    // MARK: - Actions
    @objc private func generateButtonTapped() {
        let generatedText = ProcessGenerator.generate(
            type: selectedType,
            scale: selectedScale,
            standard: selectedStandard
        )
        
        // Present the result in a new view controller
        let resultVC = ResultViewController(generatedText: generatedText)
        let navController = UINavigationController(rootViewController: resultVC)
        present(navController, animated: true)
    }
    
    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionType = Section(rawValue: section) else { return 0 }
        switch sectionType {
        case .inputs:
            return 3 // Type, Scale, Standard
        case .action:
            return 1 // Generate button
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let sectionType = Section(rawValue: indexPath.section) else { return UITableViewCell() }
        
        switch sectionType {
        case .inputs:
            let cell = UITableViewCell(style: .value1, reuseIdentifier: "InputCell")
            cell.accessoryType = .disclosureIndicator
            var content = cell.defaultContentConfiguration()
            
            switch indexPath.row {
            case 0:
                content.text = "Project Type"
                content.secondaryText = selectedType.rawValue
            case 1:
                content.text = "Project Scale"
                content.secondaryText = selectedScale.rawValue
            case 2:
                content.text = "Preferred Standard"
                content.secondaryText = selectedStandard.title
            default: break
            }
            
            content.textProperties.font = Typography.body()
            content.secondaryTextProperties.font = Typography.body()
            cell.contentConfiguration = content
            return cell
            
        case .action:
            let cell = UITableViewCell(style: .default, reuseIdentifier: "ButtonCell")
            var content = cell.defaultContentConfiguration()
            content.text = "Generate Process"
            content.textProperties.font = Typography.bodyMedium()
            content.textProperties.color = .pmCoral
            content.textProperties.alignment = .center
            cell.contentConfiguration = content
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sectionType = Section(rawValue: section) else { return nil }
        return sectionType == .inputs ? "Project Scenario" : nil
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let sectionType = Section(rawValue: indexPath.section) else { return }
        
        switch sectionType {
        case .inputs:
            // Present a picker for the selected row
            presentPicker(for: indexPath.row)
        case .action:
            // Trigger the generation
            generateButtonTapped()
        }
    }
    
    private func presentPicker(for row: Int) {
        let title: String
        let data: [String]
        let handler: (String) -> Void
        
        switch row {
        case 0:
            title = "Select Project Type"
            data = projectTypes.map { $0.rawValue }
            handler = { [weak self] selectedValue in
                self?.selectedType = ProcessGenerator.ProjectType(rawValue: selectedValue) ?? .software
            }
        case 1:
            title = "Select Project Scale"
            data = projectScales.map { $0.rawValue }
            handler = { [weak self] selectedValue in
                self?.selectedScale = ProcessGenerator.ProjectScale(rawValue: selectedValue) ?? .medium
            }
        case 2:
            title = "Select Preferred Standard"
            data = standards.map { $0.title }
            handler = { [weak self] selectedValue in
                self?.selectedStandard = StandardsData.allStandards.first(where: { $0.title == selectedValue }) ?? StandardsData.allStandards.first!
            }
        default: return
        }
        
        let pickerVC = PickerViewController(title: title, data: data) { [weak self] selectedValue in
            handler(selectedValue)
            self?.tableView.reloadData()
        }

        let navController = UINavigationController(rootViewController: pickerVC)
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        present(navController, animated: true)
    }
}


// MARK: - Result View Controller
// A new simple VC to display the generated text
class ResultViewController: UIViewController {
    
    private let textView = UITextView()
    private let generatedText: String
    
    init(generatedText: String) {
        self.generatedText = generatedText
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Generated Process"
        view.backgroundColor = .pmBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(shareTapped))
        
        textView.text = generatedText
        textView.font = Typography.body()
        textView.textColor = .pmTextPrimary
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.textContainerInset = UIEdgeInsets(top: Spacing.md, left: Spacing.sm, bottom: Spacing.md, right: Spacing.sm)
        
        view.addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
    }
    
    @objc private func doneTapped() {
        dismiss(animated: true)
    }
    
    @objc private func shareTapped() {
        let activityVC = UIActivityViewController(activityItems: [generatedText], applicationActivities: nil)
        present(activityVC, animated: true)
    }
}

// MARK: - Picker View Controller
// A reusable picker presented in a sheet
class PickerViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    private let pickerView = UIPickerView()
    private let data: [String]
    private var onValueSelected: (String) -> Void
    
    init(title: String, data: [String], onValueSelected: @escaping (String) -> Void) {
        self.data = data
        self.onValueSelected = onValueSelected
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .pmSurface
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))
        
        pickerView.delegate = self
        pickerView.dataSource = self
        view.addSubview(pickerView)
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            pickerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pickerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            pickerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pickerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    @objc private func doneTapped() {
        let selectedRow = pickerView.selectedRow(inComponent: 0)
        let selectedValue = data[selectedRow]
        onValueSelected(selectedValue)
        dismiss(animated: true)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { data.count }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? { data[row] }
}
