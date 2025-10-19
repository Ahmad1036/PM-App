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
    
    private let ctaButton = UIButton(type: .system)
    
    private let pages = [
        ("📚", "Welcome to PM-App", "Explore, compare, and generate guidance from PMBOK, PRINCE2, and ISO standards."),
        ("🔍", "Explore Standards", "Browse and read standards with powerful search, bookmarks, and text-to-speech."),
        ("⚖️", "Compare & Generate", "Compare standards side-by-side and get tailored process recommendations.")
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
        view.bringSubviewToFront(gradientOrb1)
        view.bringSubviewToFront(gradientOrb2)
        view.bringSubviewToFront(scrollView)
        view.bringSubviewToFront(pageControl)
        view.bringSubviewToFront(ctaButton)
    }
    
    private func setupDecorativeBackground() {
        [gradientOrb1, gradientOrb2].forEach { orb in
            view.addSubview(orb)
            orb.translatesAutoresizingMaskIntoConstraints = false
            orb.layer.shadowColor = orb.backgroundColor?.cgColor
            orb.layer.shadowRadius = 40
            orb.layer.shadowOpacity = 0.6
            orb.layer.shadowOffset = .zero
        }
        
        gradientOrb1.backgroundColor = .pmCoral.withAlphaComponent(0.12)
        gradientOrb1.layer.cornerRadius = 120
        NSLayoutConstraint.activate([
            gradientOrb1.widthAnchor.constraint(equalToConstant: 240),
            gradientOrb1.heightAnchor.constraint(equalToConstant: 240),
            gradientOrb1.topAnchor.constraint(equalTo: view.topAnchor, constant: -80),
            gradientOrb1.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -60)
        ])
        
        gradientOrb2.backgroundColor = .pmGold.withAlphaComponent(0.08)
        gradientOrb2.layer.cornerRadius = 100
        NSLayoutConstraint.activate([
            gradientOrb2.widthAnchor.constraint(equalToConstant: 200),
            gradientOrb2.heightAnchor.constraint(equalToConstant: 200),
            gradientOrb2.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 40),
            gradientOrb2.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 20)
        ])
    }
    
    private func setupPages() {
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        scrollView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        for page in pages {
            let pageView = createPage(icon: page.0, title: page.1, desc: page.2)
            stackView.addArrangedSubview(pageView)
            pageView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        }
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: pageControl.topAnchor, constant: -Spacing.lg),
            
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
        ])
    }
    
    private func createPage(icon: String, title: String, desc: String) -> UIView {
        let container = UIView()
        let iconLabel = UILabel()
        iconLabel.text = icon
        iconLabel.font = .systemFont(ofSize: 80)
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = Typography.title1()
        titleLabel.textColor = .pmTextPrimary
        
        let descLabel = UILabel()
        descLabel.text = desc
        descLabel.font = Typography.body()
        descLabel.textColor = .pmTextSecondary
        
        [titleLabel, descLabel].forEach { $0.textAlignment = .center; $0.numberOfLines = 0 }
        
        let stack = UIStackView(arrangedSubviews: [iconLabel, titleLabel, descLabel])
        stack.axis = .vertical
        stack.spacing = Spacing.md
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
        
        ctaButton.setTitle("Let's Go", for: .normal)
        PrimaryButtonStyle.applyTo(ctaButton) // APPLYING NEW STYLE
        ctaButton.addTarget(self, action: #selector(complete), for: .touchUpInside)
        
        view.addSubview(pageControl)
        view.addSubview(ctaButton)
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            pageControl.bottomAnchor.constraint(equalTo: ctaButton.topAnchor, constant: -Spacing.lg),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            ctaButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.lg),
            ctaButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.lg),
            ctaButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Spacing.md),
            ctaButton.heightAnchor.constraint(equalToConstant: 52)
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
