//
//  TOCViewController.swift
//  PM-App
//
//  Table of Contents viewer for EPUB navigation
//

import UIKit
import ReadiumShared

class TOCViewController: UIViewController {
    
    private let publication: Publication
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var tocItems: [Link] = []
    private var isLoading = true
    
    var onSelectChapter: ((Link) -> Void)?
    
    init(publication: Publication) {
        self.publication = publication
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Table of Contents"
        view.backgroundColor = .systemBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneTapped)
        )
        
        setupTableView()
        loadTOCItems()
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "TOCCell")
    }
    
    @objc private func doneTapped() {
        dismiss(animated: true)
    }
    
    private func loadTOCItems() {
        Task {
            do {
                let result = await publication.tableOfContents()
                await MainActor.run {
                    switch result {
                    case .success(let items):
                        self.tocItems = items
                        self.isLoading = false
                        self.tableView.reloadData()
                    case .failure(let error):
                        print("Failed to load table of contents: \(error)")
                        self.isLoading = false
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }
}

extension TOCViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isLoading {
            return 1 // Show loading cell
        }
        return tocItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TOCCell", for: indexPath)
        
        if isLoading {
            cell.textLabel?.text = "Loading..."
            cell.textLabel?.textAlignment = .center
            cell.accessoryType = .none
            cell.selectionStyle = .none
        } else {
            let item = tocItems[indexPath.row]
            cell.textLabel?.text = item.title ?? "Chapter \(indexPath.row + 1)"
            cell.textLabel?.textAlignment = .left
            cell.textLabel?.numberOfLines = 0
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if !isLoading {
            let item = tocItems[indexPath.row]
            onSelectChapter?(item)
            dismiss(animated: true)
        }
    }
}
