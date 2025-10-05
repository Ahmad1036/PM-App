//
//  OnboardingViewController.swift
//  PM-App
//
//  Simple 3-step onboarding shown on first launch
//

import UIKit

class OnboardingViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let pageControl = UIPageControl()
    
    // Background gradient decorative elements
    private let gradientOrb1 = UIView()
    private let gradientOrb2 = UIView()
    private let gradientOrb3 = UIView()
    
    private let ctaButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Let's Go", for: .normal)
        btn.titleLabel?.font = Typography.bodyMedium()
        btn.setTitleColor(.pmBlack, for: .normal)
        return btn
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Your comprehensive project management companion"
        label.font = Typography.body()
        label.textColor = .pmTextSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        label.alpha = 0.8
        return label
    }()
    
    private let pages = [
        ("📚", "Welcome to PM-App", "Explore, compare, and generate guidance from PMBOK, PRINCE2, and ISO standards"),
        ("🔍", "Explore Standards", "Browse and read standards with powerful search, bookmarks, and text-to-speech"),
        ("⚖️", "Compare & Generate", "Compare standards side-by-side and get tailored process recommendations")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .pmBackground
        setupDecorativeBackground()
        setupPages()
        setupControls()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.addExcitingGradientBackground()
        // Bring orbs and UI elements to front
        view.bringSubviewToFront(gradientOrb1)
        view.bringSubviewToFront(gradientOrb2)
        view.bringSubviewToFront(gradientOrb3)
        view.bringSubviewToFront(scrollView)
        view.bringSubviewToFront(subtitleLabel)
        view.bringSubviewToFront(pageControl)
        view.bringSubviewToFront(ctaButton)
    }
    
    private func setupDecorativeBackground() {
        // Create sophisticated gradient orbs in background
        [gradientOrb1, gradientOrb2, gradientOrb3].forEach { orb in
            view.addSubview(orb)
            orb.translatesAutoresizingMaskIntoConstraints = false
        }
        
        // Orb 1 - Top left with coral tint
        gradientOrb1.backgroundColor = .pmCoral.withAlphaComponent(0.12)
        gradientOrb1.layer.cornerRadius = 120
        NSLayoutConstraint.activate([
            gradientOrb1.widthAnchor.constraint(equalToConstant: 240),
            gradientOrb1.heightAnchor.constraint(equalToConstant: 240),
            gradientOrb1.topAnchor.constraint(equalTo: view.topAnchor, constant: -80),
            gradientOrb1.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -60)
        ])
        
        // Orb 2 - Bottom right with coral tint
        gradientOrb2.backgroundColor = .pmCoral.withAlphaComponent(0.12)
        gradientOrb2.layer.cornerRadius = 100
        NSLayoutConstraint.activate([
            gradientOrb2.widthAnchor.constraint(equalToConstant: 200),
            gradientOrb2.heightAnchor.constraint(equalToConstant: 200),
            gradientOrb2.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 40),
            gradientOrb2.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 20)
        ])
        
        // Orb 3 - Middle right with gold tint
        gradientOrb3.backgroundColor = .pmGold.withAlphaComponent(0.08)
        gradientOrb3.layer.cornerRadius = 80
        NSLayoutConstraint.activate([
            gradientOrb3.widthAnchor.constraint(equalToConstant: 160),
            gradientOrb3.heightAnchor.constraint(equalToConstant: 160),
            gradientOrb3.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            gradientOrb3.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 30)
        ])
        
        // Apply blur to orbs for liquid effect
        [gradientOrb1, gradientOrb2, gradientOrb3].forEach { orb in
            orb.layer.shadowColor = orb.backgroundColor?.cgColor
            orb.layer.shadowRadius = 40
            orb.layer.shadowOpacity = 0.6
            orb.layer.shadowOffset = .zero
        }
    }
    
    private func setupPages() {
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: 500)
        ])
        
        for (index, page) in pages.enumerated() {
            let pageView = createPage(icon: page.0, title: page.1, desc: page.2)
            scrollView.addSubview(pageView)
            pageView.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                pageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
                pageView.widthAnchor.constraint(equalTo: view.widthAnchor),
                pageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
                pageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: CGFloat(index) * view.bounds.width)
            ])
        }
        
        scrollView.contentSize = CGSize(width: view.bounds.width * CGFloat(pages.count), height: 500)
    }
    
    private func createPage(icon: String, title: String, desc: String) -> UIView {
        let container = UIView()
        
        let iconLabel = UILabel()
        iconLabel.text = icon
        iconLabel.font = .systemFont(ofSize: 80)
        iconLabel.textAlignment = .center
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = Typography.title1()
        titleLabel.textColor = .pmTextPrimary
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        
        let descLabel = UILabel()
        descLabel.text = desc
        descLabel.font = Typography.body()
        descLabel.textColor = .pmTextSecondary
        descLabel.textAlignment = .center
        descLabel.numberOfLines = 0
        
        let stack = UIStackView(arrangedSubviews: [iconLabel, titleLabel, descLabel])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        
        container.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -32)
        ])
        
        return container
    }
    
    private func setupControls() {
        pageControl.numberOfPages = pages.count
        pageControl.currentPageIndicatorTintColor = .pmCoral
        pageControl.pageIndicatorTintColor = .pmCoral.withAlphaComponent(0.3)
        
        view.addSubview(subtitleLabel)
        view.addSubview(pageControl)
        view.addSubview(ctaButton)
        
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Apply liquid glass effect to button (no green tint)
        LiquidGlassStyle.applyToButton(ctaButton, tintColor: .pmCoral.withAlphaComponent(0.12))
        
        ctaButton.addTarget(self, action: #selector(complete), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            subtitleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            
            pageControl.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 24),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            ctaButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            ctaButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            ctaButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            ctaButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    @objc private func complete() {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        dismiss(animated: true)
    }
}

extension OnboardingViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        pageControl.currentPage = Int(round(scrollView.contentOffset.x / view.frame.width))
    }
}
