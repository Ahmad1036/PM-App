//
//  MainTabBarController.swift
//  PM-App
//
//  Created by usear on 10/4/25.
//
import UIKit

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configureTabBarAppearance()
        setupTabs()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        // Force tab bar to use correct layout on first appearance
        tabBar.invalidateIntrinsicContentSize()
    }
    
    private func configureTabBarAppearance() {
        // Configure tab bar appearance before adding items
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = .systemBackground
        
        // Configure selected item appearance
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.systemBlue
        ]
        appearance.stackedLayoutAppearance.selected.iconColor = .systemBlue
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttributes
        
        // Configure normal item appearance
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.systemGray2
        ]
        appearance.stackedLayoutAppearance.normal.iconColor = .systemGray2
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttributes
        
        // Apply appearance
        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
        
        // Set tint colors
        tabBar.tintColor = .systemBlue
        tabBar.unselectedItemTintColor = .systemGray2
    }

    private func setupTabs() {
        // 1. Create instances of our view controllers
        let exploreVC = ExploreViewController()
        let compareVC = CompareViewController()
        let generateVC = GenerateViewController()

        // 2. Configure the tab bar item for each view controller
        exploreVC.tabBarItem = UITabBarItem(title: "Explore", image: UIImage(systemName: "book.closed"), selectedImage: UIImage(systemName: "book.closed.fill"))
        compareVC.tabBarItem = UITabBarItem(title: "Compare", image: UIImage(systemName: "square.split.2x1"), selectedImage: UIImage(systemName: "square.split.2x1.fill"))
        generateVC.tabBarItem = UITabBarItem(title: "Generate", image: UIImage(systemName: "doc.text.magnifyingglass"), selectedImage: UIImage(systemName: "doc.text.magnifyingglass"))

        // 3. Embed each view controller in its own navigation controller
        // This gives us a navigation bar at the top for free (for titles, etc.)
        let exploreNav = UINavigationController(rootViewController: exploreVC)
        let compareNav = UINavigationController(rootViewController: compareVC)
        let generateNav = UINavigationController(rootViewController: generateVC)
        
        // 4. Set the navigation controllers as the view controllers for the tab bar
        setViewControllers([exploreNav, compareNav, generateNav], animated: false)
        
        // 5. Set initial selected tab
        selectedIndex = 0
        
        // 6. Force immediate layout
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
}
