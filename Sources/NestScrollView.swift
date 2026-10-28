//
//  NestScrollView.swift
//  Demo
//
//  Created by LC on 2026/6/25.
//

import UIKit

/// Receives scroll progress updates from a ``NestScrollView``.
@objc public protocol NestScrollViewDelegate: AnyObject {

    /// Called when the header collapse progress changes.
    ///
    /// - Parameters:
    ///   - scrollView: The nest scroll view whose progress changed.
    ///   - progress: Header offset divided by (`headerMaxHeight` − `headerMinHeight`).
    ///     - `< 0`: pulled past the fully expanded position (outer bounce / overscroll)
    ///     - `0`: fully expanded
    ///     - `1`: fully collapsed
    @objc optional func nestScrollView(_ scrollView: NestScrollView, didChangeCollapseProgress progress: CGFloat)
}

/// A nested scroll view that coordinates an outer scroll view with an inner one,
/// so a header can collapse before the inner list scrolls.
///
/// Place header content in ``headerView`` and the main content (for example a
/// table or paging container) in ``containerView``. Assign the currently visible
/// inner scroll view to ``trackedInnerScrollView``.
open class NestScrollView: UIScrollView {

    // MARK: Public

    /// Collapsible header container. Add your header content as its subviews.
    public let headerView = UIView()

    /// Content area below the header. Add the list or paging container here.
    ///
    /// Height is `bounds.height - headerMinHeight`, so the list stays fully
    /// visible when the header is collapsed.
    public let containerView = UIView()

    /// Delegate that receives header collapse progress updates.
    open weak var nestDelegate: NestScrollViewDelegate?

    /// The inner scroll view whose scrolling is coordinated with this view.
    ///
    /// Update this when the visible page changes (for example with a paging menu).
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

    /// Header height when fully expanded. Changing it triggers a layout update.
    open var headerMaxHeight: CGFloat = 0 {
        didSet { reloadLayout() }
    }

    /// Header height when fully collapsed. Defaults to `0`. Changing it triggers a layout update.
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

        let clampedOffset = min(contentOffset.y, criticalOffset)
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
