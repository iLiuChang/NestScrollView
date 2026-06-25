//
//  ScrollViewDelegateProxy.swift
//  Demo
//
//  Created by LC on 2026/6/25.
//

import UIKit

final class ScrollViewDelegateProxy: NSObject, UIScrollViewDelegate {

    weak var originalDelegate: UIScrollViewDelegate?

    var didScrollHandler: ((UIScrollView) -> Void)?

    func scrollViewDidScroll(_ scrollView: UIScrollView) {

        didScrollHandler?(scrollView)

        originalDelegate?.scrollViewDidScroll?(scrollView)
    }

    override func responds(to aSelector: Selector!) -> Bool {
        if originalDelegate?.responds(to: aSelector) == true {
            return true
        }
        return super.responds(to: aSelector)
    }
    
    override func forwardingTarget(for aSelector: Selector!) -> Any? {

        if originalDelegate?.responds(to: aSelector) == true {
            return originalDelegate
        }

        return super.forwardingTarget(for: aSelector)
    }
}
