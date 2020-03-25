//
// Copyright © 2020 Daniel Farrelly & Curtis Herbert
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

class IconView: UIView {

	let icon: Icon

	let size: CGFloat

	let borderWidth: CGFloat

	var unselectedStrokeColor: UIColor? {
		didSet {
			updateUnselectedBorder()
		}
	}

	internal let borderView: UIView = BorderView()

	internal let imageView: UIImageView = ImageView()

	internal let label = UILabel()

	private var strokeWidth: CGFloat = 0.0

	init(icon: Icon, size: CGFloat, borderWidth: CGFloat) {
		self.icon = icon
		self.size = size
		self.borderWidth = borderWidth
		self.labelHeightConstraint = label.heightAnchor.constraint(equalToConstant: 0)

		super.init(frame: CGRect(x: 0, y: 0, width: size + (borderWidth * 2), height: size + (borderWidth * 2)))

		backgroundColor = UIColor.clear
		clipsToBounds = false
		layoutMargins = UIEdgeInsets(top: borderWidth, left: borderWidth, bottom: borderWidth, right: borderWidth)
		translatesAutoresizingMaskIntoConstraints = false
		accessibilityLabel = icon.localizedName ?? icon.name
		accessibilityTraits = .button
		isAccessibilityElement = true

		borderView.clipsToBounds = true
		borderView.layer.masksToBounds = true
		borderView.backgroundColor = UIColor.clear
		borderView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(borderView)

		imageView.image = icon[size]
		imageView.clipsToBounds = true
		imageView.contentMode = .scaleAspectFit
		imageView.layer.masksToBounds = true
		imageView.translatesAutoresizingMaskIntoConstraints = false
		borderView.addSubview(imageView)

		label.text = icon.localizedName ?? icon.name
		label.font = UIFont.systemFont(ofSize: labelFontSize(for: traitCollection.preferredContentSizeCategory))
		label.textAlignment = .center
		label.translatesAutoresizingMaskIntoConstraints = false
		label.allowsDefaultTighteningForTruncation = true
		label.adjustsFontForContentSizeCategory = false
		addSubview(label)

		if #available(iOS 13.4, *) {
			addInteraction(UIPointerInteraction(delegate: self))
		}

		prepareConstraints()
		updateUnselectedBorder()
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func prepareConstraints() {
		borderView.centerXAnchor.constraint(equalTo: label.centerXAnchor).isActive = true
		borderView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor).isActive = true
		borderView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor).isActive = true
		borderView.topAnchor.constraint(equalTo: topAnchor).isActive = true

		imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor).isActive = true
		imageView.leadingAnchor.constraint(equalTo: borderView.leadingAnchor, constant: borderWidth).isActive = true
		imageView.trailingAnchor.constraint(equalTo: borderView.trailingAnchor, constant: -borderWidth).isActive = true
		imageView.topAnchor.constraint(equalTo: borderView.topAnchor, constant: borderWidth).isActive = true
		imageView.bottomAnchor.constraint(equalTo: borderView.bottomAnchor, constant: -borderWidth).isActive = true
		imageView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -borderWidth).isActive = true

		label.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
		label.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
		label.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

		// We allow the following constraints to be broken as needed to stop the auto layout system from chucking a
		// tanty when the selector is contained within a table view cell.

		let width = imageView.widthAnchor.constraint(equalToConstant: size)
		width.priority = UILayoutPriority(rawValue: UILayoutPriority.required.rawValue - 10)
		width.isActive = true

		let spacing = borderView.bottomAnchor.constraint(equalTo: label.topAnchor, constant: -5)
		spacing.priority = UILayoutPriority(rawValue: UILayoutPriority.required.rawValue - 10)
		spacing.isActive = true
	}

	override func layoutSubviews() {
		super.layoutSubviews()

		updateUnselectedBorder()
	}

	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)

		if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
			label.font = label.font?.withSize(labelFontSize(for: traitCollection.preferredContentSizeCategory))
		}
	}

	private func labelFontSize(for contentSizeCategory: UIContentSizeCategory) -> CGFloat {
		switch contentSizeCategory {
		case .extraSmall: return 11.0
		case .small: return 11.5
		case .medium: return 12.0
		case .large: return 12.5
		case .extraLarge: return 13.0
		case .extraExtraLarge: return 13.5
		case .extraExtraExtraLarge: return 14.0
		case .accessibilityMedium: return 14.5
		case .accessibilityLarge: return 15.0
		case .accessibilityExtraLarge: return 15.5
		case .accessibilityExtraExtraLarge: return 16.0
		case .accessibilityExtraExtraExtraLarge: return 16.5
		default: return 12.0
		}
	}

	private func updateUnselectedBorder() {
		if !isSelected, let color = unselectedStrokeColor {
			(imageView as? ImageView)?.borderLayer.strokeColor = color.cgColor
		}
		else {
			(imageView as? ImageView)?.borderLayer.strokeColor = UIColor.clear.cgColor
		}
	}

	override func tintColorDidChange() {
		guard isSelected else {
			return
		}

		borderView.backgroundColor = tintColor
	}

	private class BorderView: UIView {

		private var shapeMask = CAShapeLayer()

		override func layoutSubviews() {
			super.layoutSubviews()

			shapeMask.path = UIBezierPath(roundedRect: bounds, cornerRadius: bounds.size.width * 0.225).cgPath
			layer.mask = shapeMask
		}

	}

	private class ImageView: UIImageView {

		private var shapeMask = CAShapeLayer()

		var borderLayer: CAShapeLayer = {
			let layer = CAShapeLayer()
			layer.strokeColor = UIColor.clear.cgColor
			layer.fillColor = UIColor.clear.cgColor
			return layer
		}()

		override func layoutSubviews() {
			super.layoutSubviews()

			let path = UIBezierPath(roundedRect: bounds, cornerRadius: bounds.size.width * 0.225)

			borderLayer.lineWidth = 2.0 / (window?.screen ?? .main).scale
			borderLayer.path = path.cgPath
			layer.addSublayer(borderLayer)

			shapeMask.path = path.cgPath
			layer.mask = shapeMask
		}

	}

	// MARK: Displaying labels

	private var labelHeightConstraint: NSLayoutConstraint

	var shouldDisplayLabel: Bool {
		get { return !labelHeightConstraint.isActive  }
		set {
			label.alpha = newValue ? 1 : 0
			labelHeightConstraint.isActive = !newValue
		}
	}

	// MARK: Selection

	var isSelected: Bool {
		get {
			return accessibilityTraits.contains(.selected)
		}
		set {
			if newValue {
				borderView.backgroundColor = tintColor
				accessibilityTraits.insert(.selected)
			}
			else {
				borderView.backgroundColor = UIColor.clear
				accessibilityTraits.remove(.selected)
			}

			updateUnselectedBorder()
		}
	}

	// MARK: Highlighting

	var isHighlighted: Bool {
		get { return highlightedView != nil }
		set {
			if newValue {
				let view = HighlightedView(frame: bounds.insetBy(dx: -borderWidth, dy: -borderWidth))
				borderView.addSubview(view)
				highlightedView = view
			}
			else {
				highlightedView?.removeFromSuperview()
				highlightedView = nil
			}
		}
	}

	private var highlightedView: HighlightedView?

	private class HighlightedView: UIView {

		override init(frame: CGRect) {
			super.init(frame: frame)

			backgroundColor = UIColor(white: 0, alpha: 0.6)
			layer.masksToBounds = true
		}

		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}

	}

}

@available(iOS 13.4, *)
extension IconView: UIPointerInteractionDelegate {

	func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
		return UIPointerStyle(effect: .lift(UITargetedPreview(view: borderView)))
	}

}
