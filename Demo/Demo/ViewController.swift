//
//  ViewController.swift
//  Demo
//
//  Created by ABC on 2026/6/25.
//

import UIKit
import PagingMenu

class ViewController: UIViewController {

    private let nestScrollView = NestScrollView()
    private let pagingMenu = PagingMenuController()
    private let menuTitles = ["推荐", "热门", "最新"]
    private var tableViews: [UITableView] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        edgesForExtendedLayout = .all
        extendedLayoutIncludesOpaqueBars = true

        setupNestScrollView()
        setupHeaderView()
        setupPagingMenu()
    }

    // MARK: - NestScrollView

    private func setupNestScrollView() {
        nestScrollView.contentInsetAdjustmentBehavior = .never
        nestScrollView.headerMaxHeight = 200
        nestScrollView.headerMinHeight = 62
        nestScrollView.nestDelegate = self
        nestScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nestScrollView)

        NSLayoutConstraint.activate([
            nestScrollView.topAnchor.constraint(equalTo: view.topAnchor),
            nestScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            nestScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            nestScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Header

    private func setupHeaderView() {
        let header = nestScrollView.headerView
        header.backgroundColor = .clear

        let gradient = CAGradientLayer()
        gradient.colors = [UIColor.systemBlue.cgColor, UIColor.systemPurple.cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)

        let gradientView = GradientView()
        gradientView.gradientLayer = gradient
        gradientView.translatesAutoresizingMaskIntoConstraints = false
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
            gradientView.topAnchor.constraint(equalTo: header.topAnchor),
            gradientView.leadingAnchor.constraint(equalTo: header.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: header.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: header.bottomAnchor),

            titleLabel.centerXAnchor.constraint(equalTo: header.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: header.centerYAnchor, constant: -10),
            subtitleLabel.centerXAnchor.constraint(equalTo: header.centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8)
        ])
    }

    // MARK: - PagingMenu

    private func setupPagingMenu() {
        let container = nestScrollView.containerView
        container.backgroundColor = .systemGroupedBackground

        let indicator = UIView()
        let line = UIView()
        line.backgroundColor = .systemBlue
        line.layer.cornerRadius = 1.5
        indicator.addSubview(line)
        line.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            line.bottomAnchor.constraint(equalTo: indicator.bottomAnchor),
            line.centerXAnchor.constraint(equalTo: indicator.centerXAnchor),
            line.widthAnchor.constraint(equalToConstant: 24),
            line.heightAnchor.constraint(equalToConstant: 3)
        ])

        pagingMenu.barHeight = 44
        pagingMenu.barAlignment = .center
        pagingMenu.barItemSpacing = 40
        pagingMenu.barItemNormalStyle = PagingBarItemStyle(
            color: .secondaryLabel,
            font: .systemFont(ofSize: 15, weight: .regular)
        )
        pagingMenu.barItemSelectedStyle = PagingBarItemStyle(
            color: .systemBlue,
            font: .systemFont(ofSize: 15, weight: .semibold)
        )
        pagingMenu.barItemSelectedBackgroundView = indicator
        pagingMenu.bounces = false
        pagingMenu.delegate = self

        tableViews = menuTitles.enumerated().map { index, _ in
            makeTableView(tag: index)
        }
        pagingMenu.items = (menuTitles, tableViews)

        addChild(pagingMenu)
        pagingMenu.view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(pagingMenu.view)
        pagingMenu.didMove(toParent: self)

        NSLayoutConstraint.activate([
            pagingMenu.view.topAnchor.constraint(equalTo: container.topAnchor),
            pagingMenu.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            pagingMenu.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            pagingMenu.view.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        nestScrollView.trackedInnerScrollView = tableViews.first
    }

    private func makeTableView(tag: Int) -> UITableView {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .systemGroupedBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tag = tag
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        return tableView
    }
}

// MARK: - GradientView

private final class GradientView: UIView {
    var gradientLayer: CAGradientLayer? {
        didSet {
            oldValue?.removeFromSuperlayer()
            if let gradientLayer {
                layer.insertSublayer(gradientLayer, at: 0)
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer?.frame = bounds
    }
}

// MARK: - PagingMenuControllerDelegate

extension ViewController: PagingMenuControllerDelegate {

    func pagingMenuController(
        _ pagingMenuController: PagingMenuController,
        didSelectAt index: Int,
        actionBehavior: PagingMenuController.ActionBehavior
    ) {
        guard index >= 0, index < tableViews.count else { return }
        nestScrollView.trackedInnerScrollView = tableViews[index]
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension ViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        30 + tableView.tag * 10
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = "\(menuTitles[tableView.tag]) - 第 \(indexPath.row + 1) 行"
        cell.textLabel?.font = .systemFont(ofSize: 15)
        cell.backgroundColor = .systemBackground
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        50
    }
}

// MARK: - NestScrollViewDelegate

extension ViewController: NestScrollViewDelegate {

    func nestScrollView(_ scrollView: NestScrollView, didChangeCollapseProgress progress: CGFloat) {
        scrollView.headerView.alpha = max(1.0 - progress, 0.3)
    }
}
