//
//  SearchViewController.swift
//  PM-App
//
//  Search functionality for EPUB content
//

import UIKit
import ReadiumShared

class SearchViewController: UIViewController {
    
    private let publication: Publication
    private let publicationFileName: String
    private let searchBar = UISearchBar()
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var searchResults: [(locator: Locator, snippet: String)] = []
    
    var onSelectResult: ((Locator) -> Void)?
    
    init(publication: Publication, publicationFileName: String) {
        self.publication = publication
        self.publicationFileName = publicationFileName
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Search"
        view.backgroundColor = .systemBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneTapped)
        )
        
        setupSearchBar()
        setupTableView()
    }
    
    private func setupSearchBar() {
        searchBar.delegate = self
        searchBar.placeholder = "Search in publication..."
        searchBar.autocapitalizationType = .none
        
        view.addSubview(searchBar)
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SearchResultCell.self, forCellReuseIdentifier: "SearchCell")
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    @objc private func doneTapped() {
        dismiss(animated: true)
    }
    
    private func performSearch(query: String) {
        // Simple text-based search through reading order
        searchResults.removeAll()
        
        for (index, link) in publication.readingOrder.enumerated() {
            // Create a locator for this chapter - href is a String, not Optional
            let href = link.href
            
            // Convert href string to URL or AnyURL for Locator
            let locator = Locator(
                href: AnyURL(string: href)!,
                mediaType: link.mediaType ?? MediaType.html,
                title: link.title ?? "Chapter \(index + 1)"
            )
            
            // Check if title contains search query (simplified search)
            if let title = link.title?.lowercased(), title.contains(query.lowercased()) {
                let snippet = "Found in: \(link.title ?? "Chapter")"
                searchResults.append((locator, snippet))
            }
        }
        
        tableView.reloadData()
        
        if searchResults.isEmpty {
            showNoResultsMessage()
        }
    }
    
    private func showNoResultsMessage() {
        let alert = UIAlertController(
            title: "No Results",
            message: "No matches found for your search query.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UISearchBarDelegate

extension SearchViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let query = searchBar.text, !query.isEmpty else { return }
        performSearch(query: query)
        searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            searchResults.removeAll()
            tableView.reloadData()
        }
    }
}

// MARK: - UITableViewDataSource & Delegate

extension SearchViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchCell", for: indexPath) as! SearchResultCell
        let result = searchResults[indexPath.row]
        cell.configure(with: result.locator.title ?? "Result", snippet: result.snippet)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let result = searchResults[indexPath.row]
        onSelectResult?(result.locator)
        dismiss(animated: true)
    }
}

// MARK: - Search Result Cell

class SearchResultCell: UITableViewCell {
    
    private let titleLabel = UILabel()
    private let snippetLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.numberOfLines = 1
        
        snippetLabel.font = .systemFont(ofSize: 14)
        snippetLabel.textColor = .secondaryLabel
        snippetLabel.numberOfLines = 2
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, snippetLabel])
        stackView.axis = .vertical
        stackView.spacing = 4
        
        contentView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    func configure(with title: String, snippet: String) {
        titleLabel.text = title
        snippetLabel.text = snippet
    }
}
