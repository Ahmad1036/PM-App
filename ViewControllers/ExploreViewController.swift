//
//  ExploreViewController.swift
//  PM-App
//
//  Explore standards and view bookmarks
//
import UIKit
import ReadiumShared

class ExploreViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let standards = StandardsData.allStandards
    private var allBookmarks: [Bookmark] = []
    
    enum Section: Int, CaseIterable {
        case standards = 0
        case bookmarks = 1
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Explore Standards"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .pmBackground
        setupTableView()
        
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadBookmarks()
    }

    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "StandardCell")
        tableView.register(BookmarkTableCell.self, forCellReuseIdentifier: "BookmarkCell")
    }
    
    private func loadBookmarks() {
        // Get all bookmarks from all publications
        var allBookmarksTemp: [Bookmark] = []
        for standard in standards {
            let bookmarks = ReaderPersistence.shared.listBookmarks(for: standard.fileName)
            allBookmarksTemp.append(contentsOf: bookmarks)
        }
        // Sort by most recent first
        allBookmarks = allBookmarksTemp.sorted { $0.timestamp > $1.timestamp }
        tableView.reloadData()
    }

    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionType = Section(rawValue: section) else { return 0 }
        
        switch sectionType {
        case .standards:
            return standards.count
        case .bookmarks:
            return min(allBookmarks.count, 5) // Show max 5 recent bookmarks
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let sectionType = Section(rawValue: indexPath.section) else {
            return UITableViewCell()
        }
        
        switch sectionType {
        case .standards:
            let cell = tableView.dequeueReusableCell(withIdentifier: "StandardCell", for: indexPath)
            let standard = standards[indexPath.row]
            var content = cell.defaultContentConfiguration()
            content.text = standard.title
            content.textProperties.font = Typography.bodyMedium()
            content.textProperties.color = .pmTextPrimary
            content.image = UIImage(systemName: "book.closed")
            content.imageProperties.tintColor = .systemBlue
            cell.contentConfiguration = content
            cell.accessoryType = .disclosureIndicator
            return cell
            
        case .bookmarks:
            let cell = tableView.dequeueReusableCell(withIdentifier: "BookmarkCell", for: indexPath) as! BookmarkTableCell
            let bookmark = allBookmarks[indexPath.row]
            cell.configure(with: bookmark)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sectionType = Section(rawValue: section) else { return nil }
        
        switch sectionType {
        case .standards:
            return "Standards"
        case .bookmarks:
            return allBookmarks.isEmpty ? nil : "Recent Bookmarks"
        }
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard let sectionType = Section(rawValue: section) else { return nil }
        
        switch sectionType {
        case .standards:
            return nil
        case .bookmarks:
            if allBookmarks.isEmpty {
                return "Bookmarks you save while reading will appear here"
            } else if allBookmarks.count > 5 {
                return "Showing 5 most recent bookmarks"
            }
            return nil
        }
    }

    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let sectionType = Section(rawValue: indexPath.section) else { return }
        
        switch sectionType {
        case .standards:
            let selectedStandard = standards[indexPath.row]
            RediumHelper.shared.openReader(for: selectedStandard, from: self)
            
        case .bookmarks:
            let bookmark = allBookmarks[indexPath.row]
            openBookmark(bookmark)
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let sectionType = Section(rawValue: indexPath.section), sectionType == .bookmarks else {
            return nil
        }
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.deleteBookmark(at: indexPath)
            completion(true)
        }
        deleteAction.image = UIImage(systemName: "trash")
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    private func deleteBookmark(at indexPath: IndexPath) {
        let bookmark = allBookmarks[indexPath.row]
        
        let alert = UIAlertController(
            title: "Delete Bookmark",
            message: "Are you sure you want to delete this bookmark?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            ReaderPersistence.shared.removeBookmark(id: bookmark.id)
            self.allBookmarks.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
            
            // Reload section if no more bookmarks
            if self.allBookmarks.isEmpty {
                self.tableView.reloadSections(IndexSet(integer: Section.bookmarks.rawValue), with: .automatic)
            }
        })
        
        present(alert, animated: true)
    }
    
    private func openBookmark(_ bookmark: Bookmark) {
        // Find the standard for this bookmark
        guard let standard = standards.first(where: { $0.fileName == bookmark.publicationFileName }) else {
            return
        }
        
        // Open reader and navigate to bookmark
        RediumHelper.shared.openReaderAndNavigate(
            for: standard,
            from: self,
            toHref: bookmark.href,
            title: bookmark.title
        )
    }
}

// MARK: - BookmarkTableCell

class BookmarkTableCell: UITableViewCell {
    
    private let iconImageView = UIImageView()
    private let bookTitleLabel = UILabel()
    private let bookmarkTitleLabel = UILabel()
    private let timestampLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Icon
        iconImageView.image = UIImage(systemName: "bookmark.fill")
        iconImageView.tintColor = .pmCoral
        iconImageView.contentMode = .scaleAspectFit
        
        // Book title (small, gray)
        bookTitleLabel.font = Typography.caption()
        bookTitleLabel.textColor = .pmTextSecondary
        
        // Bookmark title
        bookmarkTitleLabel.font = Typography.body()
        bookmarkTitleLabel.textColor = .pmTextPrimary
        bookmarkTitleLabel.numberOfLines = 2
        
        // Timestamp
        timestampLabel.font = Typography.caption()
        timestampLabel.textColor = .pmTextSecondary
        timestampLabel.alpha = 0.7
        
        // Stack views
        let textStack = UIStackView(arrangedSubviews: [bookTitleLabel, bookmarkTitleLabel, timestampLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        
        let mainStack = UIStackView(arrangedSubviews: [iconImageView, textStack])
        mainStack.axis = .horizontal
        mainStack.spacing = 12
        mainStack.alignment = .top
        
        contentView.addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    func configure(with bookmark: Bookmark) {
        // Get the book title from the publication filename
        if let standard = StandardsData.allStandards.first(where: { $0.fileName == bookmark.publicationFileName }) {
            bookTitleLabel.text = standard.title
        } else {
            bookTitleLabel.text = bookmark.publicationFileName
        }
        
        bookmarkTitleLabel.text = bookmark.title
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        timestampLabel.text = formatter.localizedString(for: bookmark.timestamp, relativeTo: Date())
    }
}
