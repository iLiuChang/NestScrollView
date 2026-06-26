//
//  NestScrollView.swift
//  Demo
//
//  Created by LC on 2026/6/25.
//

import UIKit

@objc public protocol NestScrollViewDelegate: AnyObject {
    @objc optional func nestScrollView(_ scrollView: NestScrollView, didChangeCollapseProgress progress: CGFloat)
}

open class NestScrollView: UIScrollView {

    // MARK: Public

    public let headerView = UIView()
    public let containerView = UIView()

    open weak var nestDelegate: NestScrollViewDelegate?
    
    open weak var trackedInnerScrollView: UIScrollView? {
        didSet {
            guard let scrollView = trackedInnerScrollView else {
                self.proxy = nil
                return
            }
            if let oldProxy = oldValue?.delegate as? ScrollViewDelegateProxy {
                oldValue?.delegate = oldProxy.originalDelegate
            }
            let proxy = ScrollViewDelegateProxy()
            proxy.originalDelegate = scrollView.delegate
            proxy.didScrollHandler = { [weak self] scrollView in
                self?.innerScrollViewDidScroll(scrollView)
            }
            self.proxy = proxy
            scrollView.delegate = proxy
        }
    }

    /// Maximum header height (height when fully expanded)
    open var headerMaxHeight: CGFloat = 0 {
        didSet { reloadLayout() }
    }

    /// Minimum header height (height when fully collapsed, default 0)
    open var headerMinHeight: CGFloat = 0

    // MARK: Private

    private let contentView = UIView()
    private var outerCanScroll = true
    private var innerCanScroll = false

    private var proxy: ScrollViewDelegateProxy?
    // MARK: Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        reloadLayout()
    }
}

private extension NestScrollView {

    func setup() {

        delegate = self

        alwaysBounceVertical = true
        showsVerticalScrollIndicator = false

        addSubview(contentView)

        contentView.addSubview(headerView)
        contentView.addSubview(containerView)
    }

    func reloadLayout() {

        guard bounds.width > 0, headerMaxHeight > 0 else {
            return
        }

        let maxH = headerMaxHeight

        let effectiveContainerH: CGFloat = bounds.height

        contentView.frame = CGRect(
            x: 0,
            y: 0,
            width: bounds.width,
            height: maxH + effectiveContainerH
        )

        headerView.frame = CGRect(
            x: 0,
            y: 0,
            width: bounds.width,
            height: maxH
        )

        containerView.frame = CGRect(
            x: 0,
            y: maxH,
            width: bounds.width,
            height: effectiveContainerH
        )

        contentSize = CGSize(
            width: bounds.width,
            height: maxH + effectiveContainerH
        )
    }
}

extension NestScrollView: UIScrollViewDelegate {

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let criticalOffset = max(headerMaxHeight - headerMinHeight, 0)
        guard criticalOffset > 0 else { return }

        // Bounce-back: reset inner scroll when outer bounces past top
        if contentOffset.y < 0 {
            if let inner = trackedInnerScrollView, inner.contentOffset.y != 0 {
                inner.contentOffset = .zero
            }
        }

        // Outer locked: hold position at criticalOffset
        if !outerCanScroll {
            contentOffset.y = criticalOffset
            return
        }

        let clampedOffset = min(max(contentOffset.y, 0), criticalOffset)

        // Collapse header: shift it up so bottom edge stays flush with container
        let collapse = clampedOffset
        let progress = collapse / criticalOffset
        headerView.frame.origin.y = -collapse

        // Notify delegate
        nestDelegate?.nestScrollView?(self, didChangeCollapseProgress: progress)

        // Header fully collapsed: lock outer, unlock inner
        if contentOffset.y >= criticalOffset {
            contentOffset.y = criticalOffset
            outerCanScroll = false
            innerCanScroll = true
        }
    }
}

extension NestScrollView {
    private func innerScrollViewDidScroll(_ inner: UIScrollView) {
        // Inner locked: force contentOffset to zero
        if !innerCanScroll {
            if !bounces && headerView.frame.origin.y == 0 {
                return
            }
            if inner.contentOffset.y != 0 {
                inner.contentOffset = .zero
            }
            return
        }

        // Inner reached top: lock inner, unlock outer
        if inner.contentOffset.y <= 0 {
            innerCanScroll = false
            outerCanScroll = true
            inner.contentOffset = .zero
        }
    }
}

// MARK: - UIGestureRecognizerDelegate

extension NestScrollView: UIGestureRecognizerDelegate {

    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }
}
