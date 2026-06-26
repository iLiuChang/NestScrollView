//
//  ViewController.swift
//  Demo
//
//  Created by ABC on 2026/6/25.
//

import UIKit

class ViewController: UIViewController {
    
    private var nestScrollView: NestScrollView!
    
    // 分页菜单相关
    private let menuBar = UIView()
    private let menuBarHeight: CGFloat = 44
    private let menuTitles = ["推荐", "热门", "最新"]
    private var menuButtons: [UIButton] = []
    private var menuIndicator = UIView()
    private var pagingScrollView: UIScrollView!
    private var tableViews: [UITableView] = []
    private var currentPage = 0
    
    private var isLayoutConfigured = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "分页菜单示例"
        
        edgesForExtendedLayout = .all
        extendedLayoutIncludesOpaqueBars = true
        
        setupNestScrollView()
    }
    
    // MARK: - 初始化
    
    private func setupNestScrollView() {
        // 1. 创建 NestScrollView
        nestScrollView = NestScrollView(frame: view.bounds)
//        nestScrollView.bounces = false
        nestScrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        nestScrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(nestScrollView)
        
        // 2. 配置头部高度
        nestScrollView.headerMaxHeight = 200
        
        // 3. 配置头部视图
        setupHeaderView()
        
        // 4. 强制布局以确保 container 有正确的 bounds
        nestScrollView.layoutIfNeeded()
        
        // 5. 配置容器内容：菜单栏 + 分页 + 多个 TableView
        setupContainerContent()
        
        // 6. 设置代理
        nestScrollView.nestDelegate = self
        
        // 7. 初始追踪第一个 TableView
        nestScrollView.trackedInnerScrollView = tableViews.first
    }
    
    // MARK: - 头部视图
    
    private func setupHeaderView() {
        nestScrollView.headerMinHeight = 62
        let header = nestScrollView.headerView
        header.backgroundColor = .clear
        
        // 渐变背景
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor.systemBlue.cgColor, UIColor.systemPurple.cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        
        let gradientView = UIView()
        gradientView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        gradientView.layer.addSublayer(gradient)
        gradient.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 200)
        header.addSubview(gradientView)
        
        let titleLabel = UILabel()
        titleLabel.text = "分页菜单示例"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 26)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(titleLabel)
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "左右切换页面 · 每个页面独立滚动"
        subtitleLabel.font = UIFont.systemFont(ofSize: 14)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: header.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: header.centerYAnchor, constant: -10),
            subtitleLabel.centerXAnchor.constraint(equalTo: header.centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8)
        ])
    }
    
    // MARK: - 容器内容：菜单栏 + 分页滚动 + 多个 TableView
    
    private func setupContainerContent() {
        let container = nestScrollView.containerView
        container.backgroundColor = .systemGroupedBackground
        
        // ---- 菜单栏 ----
        menuBar.frame = CGRect(x: 0, y: 0, width: container.bounds.width, height: menuBarHeight)
        menuBar.autoresizingMask = [.flexibleWidth]
        menuBar.backgroundColor = .systemBackground
        container.addSubview(menuBar)
        
        let buttonWidth = container.bounds.width / CGFloat(menuTitles.count)
        for (i, title) in menuTitles.enumerated() {
            let btn = UIButton(type: .system)
            btn.frame = CGRect(x: CGFloat(i) * buttonWidth, y: 0, width: buttonWidth, height: menuBarHeight)
            btn.setTitle(title, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 15, weight: i == 0 ? .semibold : .regular)
            btn.setTitleColor(i == 0 ? .systemBlue : .secondaryLabel, for: .normal)
            btn.tag = i
            btn.addTarget(self, action: #selector(menuTapped(_:)), for: .touchUpInside)
            menuBar.addSubview(btn)
            menuButtons.append(btn)
        }
        
        // 底部指示条
        menuIndicator.frame = CGRect(x: 0, y: menuBarHeight - 3, width: buttonWidth, height: 3)
        menuIndicator.backgroundColor = .systemBlue
        menuIndicator.layer.cornerRadius = 1.5
        menuBar.addSubview(menuIndicator)
        
        // 分隔线
        let separator = UIView(frame: CGRect(x: 0, y: menuBarHeight - 0.5, width: container.bounds.width, height: 0.5))
        separator.autoresizingMask = [.flexibleWidth]
        separator.backgroundColor = .separator
        menuBar.addSubview(separator)
        
        // ---- 分页滚动视图 ----
        let pagingY = menuBarHeight
        let pagingH = container.bounds.height - pagingY
        pagingScrollView = UIScrollView(frame: CGRect(x: 0, y: pagingY, width: container.bounds.width, height: pagingH))
        pagingScrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        pagingScrollView.isPagingEnabled = true
        pagingScrollView.showsHorizontalScrollIndicator = false
        pagingScrollView.bounces = false
        pagingScrollView.delegate = self
        
        let totalWidth = container.bounds.width * CGFloat(menuTitles.count)
        pagingScrollView.contentSize = CGSize(width: totalWidth, height: pagingH)
        
        // ---- 创建每页的 TableView ----
        for i in 0..<menuTitles.count {
            let tv = UITableView(frame: CGRect(
                x: CGFloat(i) * container.bounds.width,
                y: 0,
                width: container.bounds.width,
                height: pagingH
            ), style: .plain)
            tv.backgroundColor = .systemGroupedBackground
            tv.dataSource = self
            tv.delegate = self
            tv.tag = i
            tv.register(UITableViewCell.self, forCellReuseIdentifier: "Cell_\(i)")
            pagingScrollView.addSubview(tv)
            tableViews.append(tv)
        }
        
        // 直接添加到 containerView
        nestScrollView.containerView.addSubview(pagingScrollView)
    }
    
    // MARK: - 布局更新
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // 确保 TableView 和分页视图的 frame 与最终布局一致
        guard let paging = pagingScrollView, paging.bounds.height > 0 else { return }
        let pagingH = paging.bounds.height
        let pageW = paging.bounds.width
        for (i, tv) in tableViews.enumerated() {
            let newFrame = CGRect(x: CGFloat(i) * pageW, y: 0, width: pageW, height: pagingH)
            if tv.frame != newFrame {
                tv.frame = newFrame
            }
        }
    }
        
    // MARK: - 菜单交互
    
    @objc private func menuTapped(_ sender: UIButton) {
        let page = sender.tag
        guard page != currentPage else { return }
        currentPage = page
        pagingScrollView.setContentOffset(
            CGPoint(x: CGFloat(page) * pagingScrollView.bounds.width, y: 0),
            animated: true
        )
        updateActivePage()
    }
    
    private func updateActivePage() {
        // 更新追踪的 TableView
        if currentPage < tableViews.count {
            nestScrollView.trackedInnerScrollView = tableViews[currentPage]
        }
        
        // 更新菜单按钮样式
        let buttonWidth = pagingScrollView.bounds.width / CGFloat(menuTitles.count)
        for (i, btn) in menuButtons.enumerated() {
            btn.titleLabel?.font = .systemFont(ofSize: 15, weight: i == currentPage ? .semibold : .regular)
            btn.setTitleColor(i == currentPage ? .systemBlue : .secondaryLabel, for: .normal)
        }
        
        // 移动指示条
        UIView.animate(withDuration: 0.25) {
            self.menuIndicator.frame.origin.x = CGFloat(self.currentPage) * buttonWidth
        }
    }
}

// MARK: - UIScrollViewDelegate（监听分页滑动）

extension ViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView === pagingScrollView else { return }
        let page = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        guard page != currentPage, page >= 0, page < menuTitles.count else { return }
        currentPage = page
        updateActivePage()
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // 不同页面显示不同行数，方便区分
        return 30 + tableView.tag * 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell_\(tableView.tag)", for: indexPath)
        cell.textLabel?.text = "\(menuTitles[tableView.tag]) - 第 \(indexPath.row + 1) 行"
        cell.textLabel?.font = .systemFont(ofSize: 15)
        cell.backgroundColor = .systemBackground
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
}

// MARK: - NestScrollViewDelegate

extension ViewController: NestScrollViewDelegate {
    
    func nestScrollView(_ scrollView: NestScrollView, didChangeCollapseProgress progress: CGFloat) {
        let alpha = 1.0 - progress
        scrollView.headerView.alpha = max(alpha, 0.3)
    }
}

