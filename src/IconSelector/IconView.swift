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
			updateMasks()
		}
	}

	internal let borderView = UIView()

	internal let imageView = UIImageView()

	internal let label = UILabel()

	private var borderLayer = CAShapeLayer()

	private var outerShapeLayer = CAShapeLayer()

	private var innerShapeLayer = CAShapeLayer()

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

		borderLayer.lineWidth = 1.0 / UIScreen.main.scale
		borderLayer.fillColor = UIColor.clear.cgColor

		imageView.layer.addSublayer(borderLayer)

		prepareConstraints()
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func prepareConstraints() {
		borderView.centerXAnchor.constraint(equalTo: label.centerXAnchor).isActive = true
		borderView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor).isActive = true
		borderView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor).isActive = true
		borderView.topAnchor.constraint(equalTo: topAnchor).isActive = true
		borderView.bottomAnchor.constraint(equalTo: label.topAnchor, constant: -5).isActive = true

		imageView.widthAnchor.constraint(equalToConstant: size).isActive = true
		imageView.heightAnchor.constraint(equalToConstant: size).isActive = true
		imageView.leadingAnchor.constraint(equalTo: borderView.leadingAnchor, constant: borderWidth).isActive = true
		imageView.trailingAnchor.constraint(equalTo: borderView.trailingAnchor, constant: -borderWidth).isActive = true
		imageView.topAnchor.constraint(equalTo: borderView.topAnchor, constant: borderWidth).isActive = true
		imageView.bottomAnchor.constraint(equalTo: borderView.bottomAnchor, constant: -borderWidth).isActive = true

		label.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
		label.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
		label.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
	}

	override func layoutSubviews() {
		super.layoutSubviews()

		updateMasks()
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

	private func updateMasks() {
		let outerFrame =  CGRect(origin: .zero, size: borderView.bounds.size)
		let innerFrame = CGRect(origin: .zero, size: imageView.bounds.size)

		borderLayer.path = innerShapeLayer.path
		borderLayer.strokeColor = isSelected ? UIColor.clear.cgColor : unselectedStrokeColor?.cgColor ?? UIColor.clear.cgColor

		outerShapeLayer.path = UIBezierPath(roundedRect: outerFrame, cornerRadius: outerFrame.size.width * 0.225).cgPath
		borderView.layer.mask = outerShapeLayer

		innerShapeLayer.path = UIBezierPath(roundedRect: innerFrame, cornerRadius: innerFrame.size.width * 0.225).cgPath
		imageView.layer.mask = innerShapeLayer
	}

	override func tintColorDidChange() {
		guard isSelected else {
			return
		}

		borderView.backgroundColor = tintColor
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
			return borderView.backgroundColor != .clear
		}
		set {
			borderView.backgroundColor = newValue ? tintColor : UIColor.clear

			updateMasks()
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
