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
        setupTabs()
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
        
        // 6. Style the tab bar for a clean, academic look
        tabBar.tintColor = .systemBlue
        tabBar.unselectedItemTintColor = .systemGray2
    }
}
