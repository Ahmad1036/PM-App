//
//  ReaderPersistence.swift
//  PM-App
//
//  Persistence layer for reader bookmarks and highlights
//

import Foundation

// MARK: - Models

struct Bookmark: Codable, Identifiable {
    let id: String
    let publicationFileName: String
    let title: String
    let href: String
    let location: String? // CFI or page number
    let timestamp: Date
    
    init(id: String = UUID().uuidString, publicationFileName: String, title: String, href: String, location: String?, timestamp: Date = Date()) {
        self.id = id
        self.publicationFileName = publicationFileName
        self.title = title
        self.href = href
        self.location = location
        self.timestamp = timestamp
    }
}

struct Highlight: Codable, Identifiable {
    let id: String
    let publicationFileName: String
    let text: String
    let href: String
    let color: String // hex color
    let location: String? // CFI or selection range
    let createdAt: Date
    
    init(id: String = UUID().uuidString, publicationFileName: String, text: String, href: String, color: String = "#FFFF00", location: String?, createdAt: Date = Date()) {
        self.id = id
        self.publicationFileName = publicationFileName
        self.text = text
        self.href = href
        self.color = color
        self.location = location
        self.createdAt = createdAt
    }
}

// MARK: - Persistence Manager

class ReaderPersistence {
    static let shared = ReaderPersistence()
    
    private let bookmarksKey = "reader_bookmarks"
    private let highlightsKey = "reader_highlights"
    
    private var bookmarks: [Bookmark] = []
    private var highlights: [Highlight] = []
    
    private init() {
        loadData()
    }
    
    // MARK: - Load/Save
    
    private func loadData() {
        // Load bookmarks
        if let bookmarksData = UserDefaults.standard.data(forKey: bookmarksKey),
           let decoded = try? JSONDecoder().decode([Bookmark].self, from: bookmarksData) {
            bookmarks = decoded
        }
        
        // Load highlights
        if let highlightsData = UserDefaults.standard.data(forKey: highlightsKey),
           let decoded = try? JSONDecoder().decode([Highlight].self, from: highlightsData) {
            highlights = decoded
        }
    }
    
    private func saveBookmarks() {
        if let encoded = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(encoded, forKey: bookmarksKey)
        }
    }
    
    private func saveHighlights() {
        if let encoded = try? JSONEncoder().encode(highlights) {
            UserDefaults.standard.set(encoded, forKey: highlightsKey)
        }
    }
    
    // MARK: - Bookmarks
    
    func addBookmark(_ bookmark: Bookmark) {
        bookmarks.append(bookmark)
        saveBookmarks()
    }
    
    func removeBookmark(id: String) {
        bookmarks.removeAll { $0.id == id }
        saveBookmarks()
    }
    
    func listBookmarks(for publicationFileName: String) -> [Bookmark] {
        return bookmarks.filter { $0.publicationFileName == publicationFileName }
            .sorted { $0.timestamp > $1.timestamp }
    }
    
    func isBookmarked(publicationFileName: String, href: String) -> Bool {
        return bookmarks.contains { $0.publicationFileName == publicationFileName && $0.href == href }
    }
    
    // MARK: - Highlights
    
    func addHighlight(_ highlight: Highlight) {
        highlights.append(highlight)
        saveHighlights()
    }
    
    func removeHighlight(id: String) {
        highlights.removeAll { $0.id == id }
        saveHighlights()
    }
    
    func listHighlights(for publicationFileName: String) -> [Highlight] {
        return highlights.filter { $0.publicationFileName == publicationFileName }
            .sorted { $0.createdAt > $1.createdAt }
    }
    
    func clearAll() {
        bookmarks.removeAll()
        highlights.removeAll()
        saveBookmarks()
        saveHighlights()
    }
}

// MARK: - Reader Settings

class ReaderSettings {
    static let shared = ReaderSettings()
    
    private let fontSizeKey = "reader_fontSize"
    private let themeKey = "reader_theme"
    private let scrollModeKey = "reader_scrollMode"
    private let lineSpacingKey = "reader_lineSpacing"
    
    enum Theme: String {
        case light = "Light"
        case dark = "Dark"
        case sepia = "Sepia"
    }
    
    enum ScrollMode: String {
        case paginated = "Paginated"
        case continuous = "Continuous"
    }
    
    var fontSize: Int {
        get { UserDefaults.standard.integer(forKey: fontSizeKey) == 0 ? 16 : UserDefaults.standard.integer(forKey: fontSizeKey) }
        set { UserDefaults.standard.set(newValue, forKey: fontSizeKey) }
    }
    
    var theme: Theme {
        get {
            if let raw = UserDefaults.standard.string(forKey: themeKey),
               let theme = Theme(rawValue: raw) {
                return theme
            }
            return .light
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: themeKey) }
    }
    
    var scrollMode: ScrollMode {
        get {
            if let raw = UserDefaults.standard.string(forKey: scrollModeKey),
               let mode = ScrollMode(rawValue: raw) {
                return mode
            }
            return .paginated
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: scrollModeKey) }
    }
    
    var lineSpacing: Double {
        get { UserDefaults.standard.double(forKey: lineSpacingKey) == 0 ? 1.5 : UserDefaults.standard.double(forKey: lineSpacingKey) }
        set { UserDefaults.standard.set(newValue, forKey: lineSpacingKey) }
    }
}
