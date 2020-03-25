//
// Copyright © 2019 Daniel Farrelly & Curtis Herbert
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// *    Redistributions of source code must retain the above copyright notice, this list
//		of conditions and the following disclaimer.
// *    Redistributions in binary form must reproduce the above copyright notice, this
//		list of conditions and the following disclaimer in the documentation and/or
//		other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
// IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
// INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
// BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
// LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
// OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

import UIKit

/** A control that presents available icons and allows selection.

	This control will **not** actually perform any updates
    based on the user's selection. It is the responsibility
	of the parent `UIViewController` to perform the update.
    There are two methods to perform the actual updates.
    - Read the `selectedIcon` upon the user indicating they're done
    - Use `addTarget(_:action:for:)` to enroll in updates for the
      `.valueChanged` event.
*/
public class IconSelector: UIControl, UIScrollViewDelegate, UIGestureRecognizerDelegate {

	public let icons: [Icon]

	private let scrollView = UIScrollView()

	private let containerView = UIView()

	private var iconViews: [IconView] = []

	private let gestureRecognizer = GestureRecognizer()
	
	/// Creates an `IconSelector` in the given frame, with the given icons.
	/// - Parameters:
	///   - frame: Frame to put this control within
	///   - icons: Icons to display
	public init(frame: CGRect, icons: [Icon]) {
		self.icons = icons
		super.init(frame: frame)
		initialize()
	}
	
	/// Creates an `IconSelector` in the given frame, with the given `Bundle`.
	/// - Parameters:
	///   - frame: Frame to put this control within
	///   - bundle: `Bundle` to pull icons from; defaults to the `main` bundle.
	public convenience init(frame: CGRect, bundle: Bundle = .main) {
		self.init(frame: frame, icons: Icon.options(for: bundle))
	}
	
	/// Creates an `IconSelector` with the given icons
	/// - Parameter icons: Icons to display
	public convenience init(icons: [Icon]) {
		self.init(frame: .zero, icons: icons)
	}

	/// Creates an `IconSelector` for the given `Bundle`
	/// - Parameter bundle: `Bundle` to load the icons from; defaults to the `main` bundle.
	public convenience init(bundle: Bundle = .main) {
		self.init(frame: .zero, bundle: bundle)
	}

	required init?(coder aDecoder: NSCoder) {
		icons = Icon.options(for: Bundle.main)
		super.init(coder: aDecoder)
		initialize()
	}

	private func initialize() {
		addSubview(scrollView)
		scrollView.addSubview(containerView)

		scrollView.translatesAutoresizingMaskIntoConstraints = false
		containerView.translatesAutoresizingMaskIntoConstraints = false

		let viewsDictionary: [String: UIView] = ["rootView": self, "scrollView": scrollView, "containerView": containerView]
		addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[scrollView]|", options: [], metrics: nil, views: viewsDictionary))
		addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[scrollView]|", options: [], metrics: nil, views: viewsDictionary))
		scrollView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[containerView]|", options: [], metrics: nil, views: viewsDictionary))
		scrollView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[containerView]|", options: [], metrics: nil, views: viewsDictionary))
		scrollView.addConstraint(scrollView.widthAnchor.constraint(equalTo: containerView.widthAnchor))

		scrollView.delegate = self
		containerView.layoutMargins = .zero

		gestureRecognizer.delaysTouchesBegan = true
		gestureRecognizer.isEnabled = true
		gestureRecognizer.delegate = self
		gestureRecognizer.addTarget(self, action: #selector(handleGestureRecognizer(_:)))
		containerView.addGestureRecognizer(gestureRecognizer)

		prepareIconViews()
	}
	
	/// Gets the currently selected icon.
	public var selectedIcon: Icon? {
		didSet {
			for iconView in iconViews {
				if iconView.icon == selectedIcon {
					iconView.isSelected = true
				}
				else if iconView.isSelected {
					iconView.isSelected = false
				}
			}
		}
	}

	override public var isEnabled: Bool {
		didSet {
			containerView.alpha = isEnabled ? 1 : 0.5
			containerView.isUserInteractionEnabled = isEnabled

			iconViews.forEach {
				if isEnabled {
					$0.accessibilityTraits.remove(.notEnabled)
				}
				else {
					$0.accessibilityTraits.insert(.notEnabled)
				}
			}
		}
	}

	override public var layoutMargins: UIEdgeInsets {
		get { return containerView.layoutMargins }
		set {
			containerView.layoutMargins = newValue
			setNeedsUpdateConstraints()
		}
	}

	// MARK: Tracking interaction

	private func iconView(at point: CGPoint) -> IconView? {
		for subview in containerView.subviews {
			let locationInRow = subview.convert(point, from: containerView)

			guard subview.bounds.contains(locationInRow), let iconView = subview as? IconView else {
				continue
			}

			return iconView
		}

		return nil
	}

	@objc private func handleGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
		let location = gestureRecognizer.location(in: containerView)
		let highlighted = iconViews.first(where: { $0.isHighlighted })

		guard isEnabled, bounds.contains(containerView.convert(location, to: self)), let iconView = iconView(at: location) else {
			highlighted?.isHighlighted = false
			gestureRecognizer.isEnabled = false
			gestureRecognizer.isEnabled = true

			return
		}

		switch gestureRecognizer.state {
		case .began, .changed:
			guard highlighted == nil || highlighted!.icon.name == iconView.icon.name else {
				highlighted?.isHighlighted = false
				gestureRecognizer.isEnabled = false
				gestureRecognizer.isEnabled = true
				return
			}

			guard !iconView.isSelected else {
				return
			}

			if highlighted?.icon.name != iconView.icon.name {
				highlighted?.isHighlighted = false
				iconView.isHighlighted = true
				UISelectionFeedbackGenerator().selectionChanged()
			}

		case .possible, .cancelled, .failed:
			highlighted?.isHighlighted = false

		case .ended:
			highlighted?.isHighlighted = false

			guard selectedIcon != iconView.icon else {
				return
			}

			selectedIcon = iconView.icon
			sendActions(for: .valueChanged)

			UISelectionFeedbackGenerator().selectionChanged()

		@unknown default:
			return
		}
	}

	class GestureRecognizer: UIGestureRecognizer {

		override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
			state = .began
		}

		override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
			state = .changed
		}

		override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
			state = .ended
		}

		override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
			state = .cancelled
		}

	}

	public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		let gestureRecognizerType = type(of: otherGestureRecognizer)
		return scrollView.gestureRecognizers?.contains { type(of: $0) == gestureRecognizerType } ?? false
	}

	public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
		gestureRecognizer.state = .failed
	}

	// MARK: Laying out content
	
	/// Gets or sets the size of the icons to display
	public var iconSize: CGFloat = 60.0 {
		didSet { setNeedsUpdateConstraints() }
	}
	
	/// Gets or sets the width of the selection stroke
	public var selectionStrokeWidth: CGFloat = 2.0 {
		didSet { setNeedsUpdateConstraints() }
	}

	/// Gets or sets the stroke color for **un**selected icons
	public var unselectedStrokeColor: UIColor? {
		didSet { iconViews.forEach({ $0.unselectedStrokeColor = unselectedStrokeColor}) }
	}

	/// Flag to indicate if icon labels should be displayed. Defaults to `false`.
	public var shouldDisplayLabels: Bool = false {
		didSet { iconViews.forEach({ $0.shouldDisplayLabel = shouldDisplayLabels}) }
	}

	/// Flag to indicate if the icons are lined up with the leading and trailing edges of the `IconSelector` view.
	///
	/// When `true`, the spacing between the horizontal edges of the parent view is fixed, pinning the respective edges
	/// of the icons within the first and last columns to the `IconSelector` view. This is useful when lining the
	/// horizontal edges of the `IconSelector` up with other edges, such as displaying within a table view, as the
	/// visual edges are fixed.
	///
	/// When `false` the spacing between the horizontal edges of the parent view is flexible, and sized to match the
	/// space between the icons themselves. This is useful when pinning the `IconSelector` itself to the edges of the
	/// device's screen, as it ensures even spacing for the icons, replicating the look of the iOS springboard layout.
	///
	/// - Note: The width of icon labels (if enabled) cannot exceed the width of the icons themselves if this setting is
	/// enabled, and will be truncated as required. If edges are not anchored, icon labels can fill the available space
	/// as needed, similar to how they would be displayed on the iOS springboard.
	public var anchorHorizontalEdges: Bool = true {
		didSet { setNeedsUpdateConstraints() }
	}

	/// Gets or sets a flag to have this control adjust
	/// its height to fit the content it is displaying.
	public var adjustHeightToFitContent: Bool = false {
		didSet { setNeedsUpdateConstraints() }
	}

	private var minimumSpacing: CGFloat = 20.0

	private var iconsPerRow = 4

	private var internalConstraints: [NSLayoutConstraint]?

	override public func layoutSubviews() {
		prepareIconViews()

		scrollView.clipsToBounds = !adjustHeightToFitContent
		scrollView.isScrollEnabled = !adjustHeightToFitContent

		let width = bounds.size.width - (containerView.layoutMargins.left + containerView.layoutMargins.right)
		minimumSpacing = iconSize / 3
		iconsPerRow = max(1, Int(floor(width / (iconSize + minimumSpacing))))

		setNeedsUpdateConstraints()

		super.layoutSubviews()
	}

	private func prepareIconViews() {
		if let first = iconViews.first, first.size == iconSize, first.borderWidth == selectionStrokeWidth {
			return
		}

		iconViews = icons.map { icon in
			let view = IconView(icon: icon, size: iconSize, borderWidth: selectionStrokeWidth)
			view.unselectedStrokeColor = unselectedStrokeColor
			view.shouldDisplayLabel = shouldDisplayLabels
			view.isSelected = icon.isCurrent
			return view
		}

		setNeedsUpdateConstraints()
	}

	private func prepareConstraints() {
		var newConstraints: [NSLayoutConstraint] = []

		if adjustHeightToFitContent {
			newConstraints.append(contentsOf: [
				containerView.topAnchor.constraint(equalTo: topAnchor),
				containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
			])
		}

		var currentXAnchors: [Int: NSLayoutXAxisAnchor] = [:]
		var currentYAnchors: (top: NSLayoutYAxisAnchor, bottom: NSLayoutYAxisAnchor)?
		var previousXAnchor: NSLayoutXAxisAnchor?
		var previousYAnchor: NSLayoutYAxisAnchor?
		var spacerXDimension: NSLayoutDimension?
		var spacerYDimension: NSLayoutDimension?
		var iconXDimension: NSLayoutDimension?

		containerView.subviews.forEach { $0.removeFromSuperview() }

		let edgeXAnchors: (leading: NSLayoutXAxisAnchor, trailing: NSLayoutXAxisAnchor)
		if anchorHorizontalEdges {
			edgeXAnchors = (containerView.layoutMarginsGuide.leadingAnchor, containerView.layoutMarginsGuide.trailingAnchor)
		}
		else if let firstIconView = iconViews.first {
			let widthSpacer = UIView()
			widthSpacer.alpha = 0
			widthSpacer.translatesAutoresizingMaskIntoConstraints = false
			containerView.addSubview(widthSpacer)

			let leadingSpacer = UIView()
			leadingSpacer.alpha = 0
			leadingSpacer.translatesAutoresizingMaskIntoConstraints = false
			containerView.addSubview(leadingSpacer)

			let trailingSpacer = UIView()
			trailingSpacer.alpha = 0
			trailingSpacer.translatesAutoresizingMaskIntoConstraints = false
			containerView.addSubview(trailingSpacer)

			newConstraints.append(widthSpacer.leadingAnchor.constraint(equalTo: firstIconView.leadingAnchor))
			newConstraints.append(widthSpacer.trailingAnchor.constraint(equalTo: firstIconView.imageView.leadingAnchor))
			newConstraints.append(widthSpacer.topAnchor.constraint(equalTo: containerView.layoutMarginsGuide.topAnchor))
			newConstraints.append(widthSpacer.heightAnchor.constraint(equalToConstant: 0))

			newConstraints.append(leadingSpacer.leadingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.leadingAnchor))
			newConstraints.append(leadingSpacer.topAnchor.constraint(equalTo: containerView.layoutMarginsGuide.topAnchor))
			newConstraints.append(leadingSpacer.heightAnchor.constraint(equalToConstant: 0))
			newConstraints.append(leadingSpacer.widthAnchor.constraint(equalTo: widthSpacer.widthAnchor))

			newConstraints.append(trailingSpacer.trailingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.trailingAnchor))
			newConstraints.append(trailingSpacer.topAnchor.constraint(equalTo: containerView.layoutMarginsGuide.topAnchor))
			newConstraints.append(trailingSpacer.heightAnchor.constraint(equalToConstant: 0))
			newConstraints.append(trailingSpacer.widthAnchor.constraint(equalTo: widthSpacer.widthAnchor))

			edgeXAnchors = (leadingSpacer.trailingAnchor, trailingSpacer.leadingAnchor)
		}
		else {
			return // No need to continue, we don't have any icons anyway.
		}

		for (i, iconView) in iconViews.enumerated() {
			containerView.addSubview(iconView)

			if let (topAnchor, bottomAnchor) = currentYAnchors {
				// Vertical constraints for subsequent (_not_ first/leading) icons within the current row

				newConstraints.append(iconView.topAnchor.constraint(equalTo: topAnchor))
				newConstraints.append(iconView.bottomAnchor.constraint(equalTo: bottomAnchor))
			}
			else if let anchor = previousYAnchor {
				// Vertical constraints for first (leading) icon in subsequent (_not_ first/top) rows

				let spacer = UIView() // Vertical spacer
				spacer.alpha = 0
				spacer.translatesAutoresizingMaskIntoConstraints = false
				containerView.addSubview(spacer)

				newConstraints.append(spacer.leadingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.leadingAnchor))
				newConstraints.append(spacer.topAnchor.constraint(equalTo: anchor))
				newConstraints.append(spacer.widthAnchor.constraint(equalToConstant: 0))
				newConstraints.append(iconView.topAnchor.constraint(equalTo: spacer.bottomAnchor))

				let spacerHeight = spacer.heightAnchor.constraint(greaterThanOrEqualToConstant: minimumSpacing)
				spacerHeight.priority = UILayoutPriority(rawValue: UILayoutPriority.required.rawValue - 10)
				newConstraints.append(spacerHeight)

				if let spacerYDimension = spacerYDimension {
					newConstraints.append(spacer.heightAnchor.constraint(equalTo: spacerYDimension))
				}
				else {
					spacerYDimension = spacer.heightAnchor
				}

				currentYAnchors = (top: spacer.bottomAnchor, bottom: iconView.bottomAnchor)
				previousYAnchor = iconView.bottomAnchor
			}
			else {
				// Vertical constraints for first (leading) icon in first (top) row

				newConstraints.append(iconView.topAnchor.constraint(equalTo: containerView.layoutMarginsGuide.topAnchor))

				currentYAnchors = (top: iconView.topAnchor, bottom: iconView.bottomAnchor)
				previousYAnchor = iconView.bottomAnchor
			}

			if let anchor = currentXAnchors[i % iconsPerRow] {
				// Horizontal constraints for subsequent (_not_ first/top) icons within the current column

				newConstraints.append(iconView.leadingAnchor.constraint(equalTo: anchor))
			}
			else if let anchor = previousXAnchor {
				// Horizontal constraints for for first (top) icon in subsequent (_not_ first/leading) columns

				let spacer = UIView() // Horizontal spacer
				spacer.alpha = 0
				spacer.translatesAutoresizingMaskIntoConstraints = false
				containerView.addSubview(spacer)

				newConstraints.append(spacer.leadingAnchor.constraint(equalTo: anchor))
				newConstraints.append(spacer.topAnchor.constraint(equalTo: containerView.layoutMarginsGuide.topAnchor))
				newConstraints.append(spacer.heightAnchor.constraint(equalToConstant: 0))
				newConstraints.append(iconView.leadingAnchor.constraint(equalTo: spacer.trailingAnchor))

				if anchorHorizontalEdges {
					newConstraints.append(spacer.widthAnchor.constraint(greaterThanOrEqualToConstant: minimumSpacing))
				}
				else {
					newConstraints.append(spacer.widthAnchor.constraint(equalToConstant: 0))
				}

				if let spacerXDimension = spacerXDimension {
					newConstraints.append(spacer.widthAnchor.constraint(equalTo: spacerXDimension))
				}
				else {
					spacerXDimension = spacer.widthAnchor
				}

				currentXAnchors[i] = spacer.trailingAnchor
			}
			else {
				// Vertical constraints for first (top) icon in first (leading) column

				newConstraints.append(iconView.leadingAnchor.constraint(equalTo: edgeXAnchors.leading))

				iconXDimension = iconView.widthAnchor
			}

			previousXAnchor = iconView.trailingAnchor

			if let dimension = iconXDimension { // Match widths to first icon
				newConstraints.append(iconView.widthAnchor.constraint(equalTo: dimension))
			}

			if i == iconViews.count - 1 { // Last in array
				newConstraints.append(iconView.bottomAnchor.constraint(equalTo: containerView.layoutMarginsGuide.bottomAnchor))
			}

			if i % iconsPerRow == iconsPerRow - 1 { // Last in row
				previousXAnchor = nil
				currentYAnchors = nil

				newConstraints.append(iconView.trailingAnchor.constraint(equalTo: edgeXAnchors.trailing))
			}
		}

		NSLayoutConstraint.activate(newConstraints)
		internalConstraints = newConstraints
	}

	override public func updateConstraints() {
		if let internalConstraints = internalConstraints {
			NSLayoutConstraint.deactivate(internalConstraints)
		}

		prepareConstraints()

		super.updateConstraints()
	}

}
