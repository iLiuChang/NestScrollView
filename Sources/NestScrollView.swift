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
            innerContentOffset?.invalidate()
            innerContentOffset = nil
            guard let scrollView = trackedInnerScrollView else {
                return
            }
            
            innerContentOffset = scrollView.observe(\.contentOffset, options: .new) { [weak self] scrollView, _ in
                self?.innerScrollViewDidScroll(scrollView)
            }
        }
    }

    /// Maximum header height (height when fully expanded)
    open var headerMaxHeight: CGFloat = 0 {
        didSet { reloadLayout() }
    }

    /// Minimum header height (height when fully collapsed, default 0)
    open var headerMinHeight: CGFloat = 0 {
        didSet { reloadLayout() }
    }

    // MARK: Private

    private let contentView = UIView()
    private var outerCanScroll = true
    private var innerCanScroll = false
    private var isUpdatingInnerContentOffset = false
    private var innerContentOffset: NSKeyValueObservation?
    private var lastProgress: CGFloat = -1

    private var criticalOffset: CGFloat {
        max(headerMaxHeight - headerMinHeight, 0)
    }

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
    
    deinit {
        innerContentOffset?.invalidate()
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

        guard bounds.width > 0 else {
            return
        }

        let width = bounds.width
        let maxH = max(headerMaxHeight, 0)
        let minH = min(max(headerMinHeight, 0), maxH)

        // Visible area for container when header is fully collapsed
        let containerH = max(bounds.height - minH, 0)
        let totalH = maxH + containerH

        let contentFrame = CGRect(x: 0, y: 0, width: width, height: totalH)
        let headerFrame = CGRect(x: 0, y: 0, width: width, height: maxH)
        let containerFrame = CGRect(x: 0, y: maxH, width: width, height: containerH)

        if contentView.frame != contentFrame {
            contentView.frame = contentFrame
        }
        if headerView.frame != headerFrame {
            headerView.frame = headerFrame
        }
        if containerView.frame != containerFrame {
            containerView.frame = containerFrame
        }
        if contentSize != contentFrame.size {
            contentSize = contentFrame.size
        }
    }

    func notifyProgress(_ progress: CGFloat) {
        guard progress != lastProgress else { return }
        lastProgress = progress
        nestDelegate?.nestScrollView?(self, didChangeCollapseProgress: progress)
    }
}

extension NestScrollView: UIScrollViewDelegate {

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let criticalOffset = criticalOffset
        guard criticalOffset > 0 else { return }

        // Bounce-back: reset inner scroll when outer bounces past top
        if contentOffset.y < 0 {
            if let inner = trackedInnerScrollView, inner.contentOffset.y != 0 {
                inner.contentOffset = .zero
            }
        }

        // Outer locked: hold position at criticalOffset
        if !outerCanScroll {
            if contentOffset.y != criticalOffset {
                contentOffset.y = criticalOffset
            }
            return
        }

        let clampedOffset = min(max(contentOffset.y, 0), criticalOffset)
        notifyProgress(clampedOffset / criticalOffset)

        // Header fully collapsed: lock outer, unlock inner
        if contentOffset.y >= criticalOffset {
            outerCanScroll = false
            innerCanScroll = true
            if contentOffset.y != criticalOffset {
                contentOffset.y = criticalOffset
            }
        }
    }
}

extension NestScrollView {
    private func innerScrollViewDidScroll(_ inner: UIScrollView) {
        guard !isUpdatingInnerContentOffset else {
            return
        }
        // No collapsible header: inner scrolls freely
        guard criticalOffset > 0 else {
            return
        }
        isUpdatingInnerContentOffset = true
        defer { isUpdatingInnerContentOffset = false }

        // Inner locked: force contentOffset to zero
        if !innerCanScroll {
            // Outer can't bounce and header fully expanded: let inner handle pull-down (e.g. refresh)
            if !bounces && contentOffset.y <= 0 && inner.contentOffset.y < 0 {
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
            if inner.contentOffset.y != 0 {
                inner.contentOffset = .zero
            }
        }
    }
}

// MARK: - UIGestureRecognizerDelegate

extension NestScrollView: UIGestureRecognizerDelegate {

    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        guard gestureRecognizer === panGestureRecognizer,
              let inner = trackedInnerScrollView else {
            return false
        }
        return otherGestureRecognizer === inner.panGestureRecognizer
    }
}
