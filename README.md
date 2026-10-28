# NestScrollView

![Swift](https://img.shields.io/badge/Swift-5.0%2B-orange.svg)
![Platform](https://img.shields.io/badge/Platform-iOS%2011.0%2B-lightgrey.svg)
![Version](https://img.shields.io/badge/Version-1.1.0-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)
![SPM](https://img.shields.io/badge/SPM-supported-brightgreen.svg)
![CocoaPods](https://img.shields.io/badge/CocoaPods-supported-blueviolet.svg)

## Overview

A nested scrolling container for iOS. Built as a `UIScrollView` with a collapsible header and a content area that hosts an inner scroll view (`UITableView`, `UICollectionView`, or any `UIScrollView`):

- **Outer scroll** — collapses the header until it reaches `headerMinHeight`
- **Inner scroll** — takes over once the header is fully collapsed, and hands control back when scrolled to the top

## Features

- **Collapsible Header** — expand / collapse between `headerMaxHeight` and `headerMinHeight`
- **Hand-off Scrolling** — seamless transition between the outer and inner scroll views
- **Any Inner Scroll View** — track a `UITableView`, `UICollectionView`, or plain `UIScrollView`
- **Progress Callback** — receive header progress through `NestScrollViewDelegate` (`< 0` overscroll, `0` expanded, `1` collapsed)
- **Simultaneous Gestures** — only recognizes simultaneously with the tracked inner scroll view
- **Pull-to-Refresh Friendly** — when `bounces` is `false`, the inner scroll view can still pull down at the top

## Requirements

- iOS 11.0+
- Swift 5.0+

## Installation

### CocoaPods

```ruby
pod 'NestScrollView'
```

Then run:

```bash
pod install
```

### Swift Package Manager

In Xcode: **File → Add Packages…** and enter:

```
https://github.com/iLiuChang/NestScrollView.git
```

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/iLiuChang/NestScrollView.git", from: "1.1.0")
]
```

### Manual

1. Download the files in the `Sources` folder
2. Drag them into your Xcode project

## Usage

### Basic Setup

```swift
import NestScrollView

let nestScrollView = NestScrollView()
nestScrollView.contentInsetAdjustmentBehavior = .never
nestScrollView.headerMaxHeight = 200
nestScrollView.headerMinHeight = 44
nestScrollView.nestDelegate = self
view.addSubview(nestScrollView)

// Put custom content into the header
nestScrollView.headerView.addSubview(profileView)

// Put the list (or a paging container) into the content area
nestScrollView.containerView.addSubview(tableView)

// Tell NestScrollView which inner scroll view to coordinate with
nestScrollView.trackedInnerScrollView = tableView
```

### Collapse Progress

`progress` is `contentOffset.y / (headerMaxHeight - headerMinHeight)`:

| Value | Meaning |
|---|---|
| `< 0` | Pulled past the fully expanded position (outer bounce / overscroll) |
| `0` | Fully expanded |
| `1` | Fully collapsed |

```swift
extension ViewController: NestScrollViewDelegate {
    func nestScrollView(_ scrollView: NestScrollView, didChangeCollapseProgress progress: CGFloat) {
        scrollView.headerView.alpha = min(max(1.0 - progress, 0.3), 1.0)

        // Stretch the header background while overscrolling
        if progress < 0 {
            let pull = -progress * (scrollView.headerMaxHeight - scrollView.headerMinHeight)
            let height = headerBackground.bounds.height
            let scale = (height + pull) / max(height, 1)
            headerBackground.transform = CGAffineTransform(a: scale, b: 0, c: 0, d: scale, tx: 0, ty: -pull / 2)
        } else {
            headerBackground.transform = .identity
        }
    }
}
```

### Switch Inner Scroll View

When the visible page changes (for example with a paging menu), update the tracked scroll view:

```swift
nestScrollView.trackedInnerScrollView = currentTableView
```

### Disable Outer Bounce

By default `bounces` is `true`, so pulling down while the header is fully expanded bounces the outer scroll view.

Set `bounces` to `false` when you want that pull-down to go to the inner scroll view instead — for example to drive a pull-to-refresh on the list:

```swift
nestScrollView.bounces = false
```

With `bounces = false`:

- The outer scroll view no longer rubber-bands past the top
- When the header is fully expanded, a downward pull is handled by `trackedInnerScrollView` (so its refresh header can trigger)
- Collapsing and expanding the header still works the same way once you scroll up

### Layout Notes

- Put header content in `headerView`, and the main content in `containerView`
- `containerView` height is `bounds.height - headerMinHeight`, so the list stays fully visible when the header is collapsed
- Set `contentInsetAdjustmentBehavior = .never` if the nest scroll view extends under the navigation bar or status bar

## API Reference

### NestScrollView

| Property / Method | Description |
|---|---|
| `headerView` | The collapsible header. Add your header content as its subviews. |
| `containerView` | The content area below the header. Add the list or paging container here. |
| `headerMaxHeight` | Header height when fully expanded. Changing it triggers a layout update. |
| `headerMinHeight` | Header height when fully collapsed. Defaults to `0`. |
| `trackedInnerScrollView` | The inner `UIScrollView` whose scrolling is coordinated with the outer scroll view. |
| `nestDelegate` | Receives collapse progress updates. |

### NestScrollViewDelegate

| Method | Description |
|---|---|
| `nestScrollView(_:didChangeCollapseProgress:)` | Optional. Called when header progress changes. `< 0` overscroll, `0` fully expanded, `1` fully collapsed. |

## Architecture

`NestScrollView` is a `UIScrollView` that owns a vertical stack of `headerView` and `containerView`. Scrolling is gated by two flags:

- While the header is collapsing, the outer scroll view moves and the inner scroll view is locked at offset `0`
- After the outer offset reaches `headerMaxHeight - headerMinHeight`, the outer scroll view locks and the inner scroll view is free to scroll
- When the inner scroll view reaches the top again, control returns to the outer scroll view so the header can expand

`trackedInnerScrollView` is observed through KVO on `contentOffset`. Simultaneous recognition is limited to that scroll view’s pan gesture, so horizontal paging gestures are not affected.

## Example

Open `Demo/Demo.xcodeproj` and run the demo target. The sample combines `NestScrollView` with [PagingMenu](https://github.com/iLiuChang/PagingMenu) for a collapsible header plus a multi-page list, and uses negative progress to stretch the header gradient on pull-down.

## License

MIT License. See [LICENSE](LICENSE) for details.
