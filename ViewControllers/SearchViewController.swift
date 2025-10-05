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
        searchResults.removeAll()
        tableView.reloadData()
        
        // Show loading indicator
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.center = CGPoint(x: tableView.bounds.midX, y: tableView.bounds.midY)
        activityIndicator.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        tableView.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        
        // Perform search in background
        Task {
            var locators: [(locator: Locator, snippet: String)] = []
            let lowercasedQuery = query.lowercased()
            
            // Get positions for proper navigation
            let positionsResult = await publication.positions()
            var positions: [Locator] = []
            if case .success(let pos) = positionsResult {
                positions = pos
            }
            
            // Track which chapters we've already added to avoid duplicates
            var processedHrefs = Set<String>()
            
            // Search through reading order (chapters)
            for (index, link) in publication.readingOrder.enumerated() {
                guard let href = AnyURL(string: link.href) else { continue }
                
                // Skip if already processed
                if processedHrefs.contains(link.href) {
                    continue
                }
                
                // Try to get resource content for full-text search
                do {
                    guard let resource = publication.get(href) else { continue }
                    let contentResult = try await resource.read()
                    
                    guard case .success(let data) = contentResult,
                          let content = String(data: data, encoding: .utf8) else {
                        continue
                    }
                    
                    // Better HTML tag and entity stripping
                    var plainText = content
                    // Remove script and style content
                    plainText = plainText.replacingOccurrences(of: "<script[^>]*>[\\s\\S]*?</script>", with: " ", options: .regularExpression)
                    plainText = plainText.replacingOccurrences(of: "<style[^>]*>[\\s\\S]*?</style>", with: " ", options: .regularExpression)
                    // Remove HTML tags
                    plainText = plainText.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
                    // Decode common HTML entities
                    plainText = plainText.replacingOccurrences(of: "&nbsp;", with: " ")
                    plainText = plainText.replacingOccurrences(of: "&amp;", with: "&")
                    plainText = plainText.replacingOccurrences(of: "&lt;", with: "<")
                    plainText = plainText.replacingOccurrences(of: "&gt;", with: ">")
                    plainText = plainText.replacingOccurrences(of: "&quot;", with: "\"")
                    // Normalize whitespace
                    plainText = plainText.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                    plainText = plainText.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Search in content - find ALL matches in this chapter
                    let plainTextLower = plainText.lowercased()
                    var searchRange = plainTextLower.startIndex..<plainTextLower.endIndex
                    var matchCount = 0
                    
                    while let range = plainTextLower.range(of: lowercasedQuery, range: searchRange) {
                        matchCount += 1
                        
                        // Create snippet around the match
                        let contextLength = 60
                        let snippetStart = max(plainText.startIndex,
                                              plainText.index(range.lowerBound, offsetBy: -contextLength, limitedBy: plainText.startIndex) ?? plainText.startIndex)
                        let snippetEnd = min(plainText.endIndex,
                                            plainText.index(range.upperBound, offsetBy: contextLength, limitedBy: plainText.endIndex) ?? plainText.endIndex)
                        let snippetText = String(plainText[snippetStart..<snippetEnd]).trimmingCharacters(in: .whitespacesAndNewlines)
                        let snippet = "..." + snippetText + "..."
                        
                        // Find the position for this chapter
                        let chapterPosition = positions.first { $0.href == href }
                        
                        // Calculate approximate text position within the chapter
                        let matchOffset = plainText.distance(from: plainText.startIndex, to: range.lowerBound)
                        let totalLength = plainText.count
                        let progression = totalLength > 0 ? Double(matchOffset) / Double(totalLength) : 0.0
                        
                        // Create locator with text fragment for better navigation
                        let textFragment = String(plainText[range])
                        var locations = chapterPosition?.locations ?? Locator.Locations(position: index)
                        
                        // Add progression to help with navigation
                        if let position = locations.position {
                            locations.progression = progression
                            locations.totalProgression = (Double(position) + progression) / Double(max(positions.count, 1))
                        }
                        
                        let locator = Locator(
                            href: href,
                            mediaType: link.mediaType ?? MediaType.html,
                            title: link.title,
                            locations: locations,
                            text: Locator.Text(highlight: textFragment)
                        )
                        
                        locators.append((locator, snippet))
                        
                        // Move search range forward to find next occurrence
                        if range.upperBound < plainTextLower.endIndex {
                            searchRange = range.upperBound..<plainTextLower.endIndex
                        } else {
                            break
                        }
                        
                        // Limit results per chapter to avoid too many matches
                        if matchCount >= 20 {
                            break
                        }
                    }
                    
                    // Mark chapter as processed if we found matches
                    if matchCount > 0 {
                        processedHrefs.insert(link.href)
                    }
                    
                } catch {
                    // Skip resources that can't be read
                    continue
                }
            }
            
            // Update UI on main thread
            await MainActor.run {
                activityIndicator.stopAnimating()
                activityIndicator.removeFromSuperview()
                
                self.searchResults = locators
                self.tableView.reloadData()
                
                if self.searchResults.isEmpty {
                    self.showNoResultsMessage()
                }
            }
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
        
        // Format page number display
        var pageInfo = "Unknown Location"
        if let position = result.locator.locations.position {
            pageInfo = "Page \(position + 1)"
        } else if let progression = result.locator.locations.progression {
            pageInfo = String(format: "%.0f%% through chapter", progression * 100)
        }
        
        if let title = result.locator.title, !title.isEmpty {
            pageInfo += " - \(title)"
        }
        
        cell.configure(with: pageInfo, snippet: result.snippet)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let result = searchResults[indexPath.row]
        
        // Provide feedback that navigation is happening
        print("Selected search result: \(result.locator.title ?? "Unknown"), href: \(result.locator.href.string)")
        
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
