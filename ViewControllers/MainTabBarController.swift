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
        view.backgroundColor = .pmBackground // Use mint background
        tabBar.tintColor = .pmMint
        tabBar.unselectedItemTintColor = .pmTextSecondary
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


    // In MainTabBarController.swift

    // In MainTabBarController.swift

    private func setupTabs() {
        // 1. Create instances of our view controllers
        let exploreVC = ExploreViewController()
        let compareVC = CompareViewController()
        let generateVC = GenerateViewController()

        // 2. Define the target size for our tab bar icons
        let iconSize = CGSize(width: 25, height: 25)

        // 3. Load, resize, and set the rendering mode for each icon
        // THE FIX: We chain our new `.resize()` function before setting the rendering mode.
        let exploreIcon = UIImage(named: "Folder 2")?
            .resize(to: iconSize)?
            .withRenderingMode(.alwaysOriginal)
        
        let compareIcon = UIImage(named: "Magnifier 1")?
            .resize(to: iconSize)?
            .withRenderingMode(.alwaysOriginal)
        
        let generateIcon = UIImage(named: "Bookmark")?
            .resize(to: iconSize)?
            .withRenderingMode(.alwaysOriginal)

        // 4. Configure the tab bar item for each view controller
        exploreVC.tabBarItem = UITabBarItem(title: "Explore", image: exploreIcon, selectedImage: exploreIcon)
        compareVC.tabBarItem = UITabBarItem(title: "Compare", image: compareIcon, selectedImage: compareIcon)
        generateVC.tabBarItem = UITabBarItem(title: "Generate", image: generateIcon, selectedImage: generateIcon)

        // 5. Embed each view controller in its own navigation controller
        let exploreNav = UINavigationController(rootViewController: exploreVC)
        let compareNav = UINavigationController(rootViewController: compareVC)
        let generateNav = UINavigationController(rootViewController: generateVC)
        
        // 6. Set the navigation controllers as the view controllers for the tab bar
        setViewControllers([exploreNav, compareNav, generateNav], animated: false)
        
        // 7. Set initial selected tab
        selectedIndex = 0
    }
}
extension UIImage {
    func resize(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        self.draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
}
