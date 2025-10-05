//
//  BookmarksViewController.swift
//  PM-App
//
//  View controller to display and manage bookmarks for a publication
//

import UIKit
import ReadiumShared

protocol BookmarksViewControllerDelegate: AnyObject {
    func bookmarksViewController(_ controller: BookmarksViewController, didSelectBookmark bookmark: Bookmark)
}

class BookmarksViewController: UIViewController {
    
    // MARK: - Properties
    
    private let publicationFileName: String
    weak var delegate: BookmarksViewControllerDelegate?
    
    private var bookmarks: [Bookmark] = []
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let emptyLabel = UILabel()
    
    // MARK: - Initialization
    
    init(publicationFileName: String) {
        self.publicationFileName = publicationFileName
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Bookmarks"
        view.backgroundColor = .systemBackground
        
        setupNavigationBar()
        setupTableView()
        setupEmptyState()
        loadBookmarks()
    }
    
    // MARK: - Setup
    
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneTapped)
        )
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(BookmarkCell.self, forCellReuseIdentifier: "BookmarkCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func setupEmptyState() {
        emptyLabel.text = "No bookmarks yet.\n\nTap the star icon while reading to bookmark a page."
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.font = .systemFont(ofSize: 16)
        emptyLabel.isHidden = true
        
        view.addSubview(emptyLabel)
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }
    
    private func loadBookmarks() {
        bookmarks = ReaderPersistence.shared.listBookmarks(for: publicationFileName)
        updateEmptyState()
        tableView.reloadData()
    }
    
    private func updateEmptyState() {
        let isEmpty = bookmarks.isEmpty
        emptyLabel.isHidden = !isEmpty
        tableView.isHidden = isEmpty
    }
    
    // MARK: - Actions
    
    @objc private func doneTapped() {
        dismiss(animated: true)
    }
    
    private func deleteBookmark(at indexPath: IndexPath) {
        let bookmark = bookmarks[indexPath.row]
        
        let alert = UIAlertController(
            title: "Delete Bookmark",
            message: "Are you sure you want to delete this bookmark?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            ReaderPersistence.shared.removeBookmark(id: bookmark.id)
            self.bookmarks.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
            self.updateEmptyState()
        })
        
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension BookmarksViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bookmarks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BookmarkCell", for: indexPath) as! BookmarkCell
        let bookmark = bookmarks[indexPath.row]
        cell.configure(with: bookmark)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension BookmarksViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let bookmark = bookmarks[indexPath.row]
        delegate?.bookmarksViewController(self, didSelectBookmark: bookmark)
        dismiss(animated: true)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.deleteBookmark(at: indexPath)
            completion(true)
        }
        deleteAction.image = UIImage(systemName: "trash")
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

// MARK: - BookmarkCell

class BookmarkCell: UITableViewCell {
    
    private let titleLabel = UILabel()
    private let timestampLabel = UILabel()
    private let iconImageView = UIImageView()
    
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
        iconImageView.tintColor = .systemBlue
        iconImageView.contentMode = .scaleAspectFit
        
        // Title
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.numberOfLines = 2
        
        // Timestamp
        timestampLabel.font = .systemFont(ofSize: 13)
        timestampLabel.textColor = .secondaryLabel
        
        // Stack view
        let textStack = UIStackView(arrangedSubviews: [titleLabel, timestampLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        
        let mainStack = UIStackView(arrangedSubviews: [iconImageView, textStack])
        mainStack.axis = .horizontal
        mainStack.spacing = 12
        mainStack.alignment = .center
        
        contentView.addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    func configure(with bookmark: Bookmark) {
        titleLabel.text = bookmark.title
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        timestampLabel.text = formatter.string(from: bookmark.timestamp)
    }
}
