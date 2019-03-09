//
// Copyright © 2019 Daniel Farrelly
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// *    Redistributions of source code must retain the above copyright notice, this list
//        of conditions and the following disclaimer.
// *    Redistributions in binary form must reproduce the above copyright notice, this
//        list of conditions and the following disclaimer in the documentation and/or
//        other materials provided with the distribution.
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
import IconSelector

public class IconSelector2: UIControl, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    
    public let icons: [Icon]
    
    private let scrollView = UIScrollView()
    
    private let containerView = UIView()
    
    private var iconViews: [IconView] = []
    
    private let gestureRecognizer = GestureRecognizer()
    
    public init(frame: CGRect, icons: [Icon]) {
        self.icons = icons
        super.init(frame: frame)
        initialize()
    }
    
    public convenience init(frame: CGRect, bundle: Bundle = .main) {
        self.init(frame: frame, icons: Icon.options(for: bundle))
    }
    
    public convenience init(icons: [Icon]) {
        self.init(frame: .zero, icons: icons)
    }
    
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
    
    public var iconSize: CGFloat = 60.0 {
        didSet { setNeedsUpdateConstraints() }
    }
    
    public var selectionStrokeWidth: CGFloat = 2.0 {
        didSet { setNeedsUpdateConstraints() }
    }
    
    public var unselectedStrokeColor: UIColor? {
        didSet {
            iconViews.forEach({ $0.unselectedStrokeColor = unselectedStrokeColor})
        }
    }
    
    public var adjustHeightToFitContent: Bool = false {
        didSet { setNeedsUpdateConstraints() }
    }
    
    private var minimumSpacing: CGFloat = 20.0
    
    private var iconsPerRow = 4
    
    private var internalConstraints: [NSLayoutConstraint]?
    
    override public func layoutSubviews() {
        prepareIconViews()
        
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
        var currentYAnchor: NSLayoutYAxisAnchor?
        var previousXAnchor: NSLayoutXAxisAnchor?
        var previousYAnchor: NSLayoutYAxisAnchor?
        var spacerXDimension: NSLayoutDimension?
        var spacerYDimension: NSLayoutDimension?
        
        containerView.subviews.forEach { $0.removeFromSuperview() }
        
        for (i, iconView) in iconViews.enumerated() {
            containerView.addSubview(iconView)
            
            if let anchor = currentYAnchor {
                newConstraints.append(iconView.topAnchor.constraint(equalTo: anchor))
            }
            else if let anchor = previousYAnchor {
                let spacer = UIView()
                spacer.alpha = 0
                spacer.translatesAutoresizingMaskIntoConstraints = false
                containerView.addSubview(spacer)
                
                newConstraints.append(spacer.leadingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.leadingAnchor))
                newConstraints.append(spacer.topAnchor.constraint(equalTo: anchor))
                newConstraints.append(spacer.widthAnchor.constraint(equalToConstant: 0))
                newConstraints.append(spacer.heightAnchor.constraint(greaterThanOrEqualToConstant: minimumSpacing))
                newConstraints.append(iconView.topAnchor.constraint(equalTo: spacer.bottomAnchor))
                
                if let spacerYDimension = spacerYDimension {
                    newConstraints.append(spacer.heightAnchor.constraint(equalTo: spacerYDimension))
                }
                else {
                    spacerYDimension = spacer.heightAnchor
                }
                
                currentYAnchor = spacer.bottomAnchor
                previousYAnchor = iconView.bottomAnchor
            }
            else {
                newConstraints.append(iconView.topAnchor.constraint(equalTo: containerView.layoutMarginsGuide.topAnchor))
                
                currentYAnchor = iconView.topAnchor
                previousYAnchor = iconView.bottomAnchor
            }
            
            if let anchor = currentXAnchors[i % iconsPerRow] {
                newConstraints.append(iconView.leadingAnchor.constraint(equalTo: anchor))
            }
            else if let anchor = previousXAnchor {
                let spacer = UIView()
                spacer.alpha = 0
                spacer.translatesAutoresizingMaskIntoConstraints = false
                containerView.addSubview(spacer)
                
                newConstraints.append(spacer.leadingAnchor.constraint(equalTo: anchor))
                newConstraints.append(spacer.topAnchor.constraint(equalTo: containerView.layoutMarginsGuide.topAnchor))
                newConstraints.append(spacer.widthAnchor.constraint(greaterThanOrEqualToConstant: minimumSpacing))
                newConstraints.append(spacer.heightAnchor.constraint(equalToConstant: 0))
                newConstraints.append(iconView.leadingAnchor.constraint(equalTo: spacer.trailingAnchor))
                
                if let spacerXDimension = spacerXDimension {
                    newConstraints.append(spacer.widthAnchor.constraint(equalTo: spacerXDimension))
                }
                else {
                    spacerXDimension = spacer.widthAnchor
                }
                
                currentXAnchors[i] = spacer.trailingAnchor
            }
            else {
                newConstraints.append(iconView.leadingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.leadingAnchor))
            }
            
            previousXAnchor = iconView.trailingAnchor
            
            if i == iconViews.count - 1 { // Last in array
                newConstraints.append(iconView.bottomAnchor.constraint(equalTo: containerView.layoutMarginsGuide.bottomAnchor))
            }
            
            if i % iconsPerRow == iconsPerRow - 1 { // Last in row
                previousXAnchor = nil
                currentYAnchor = nil
                
                newConstraints.append(iconView.trailingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.trailingAnchor))
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
    
    // MARK: Fitting dimensions to size
    
    class IconView: UIView {
        
        let icon: Icon
        
        let size: CGFloat
        
        let borderWidth: CGFloat
        
        var unselectedStrokeColor: UIColor? {
            didSet {
                updateMasks()
            }
        }
        
        internal let imageView = UIImageView()
        
        private var borderLayer = CAShapeLayer()
        
        private var outerShapeLayer = CAShapeLayer()
        
        private var innerShapeLayer = CAShapeLayer()
        
        private var strokeWidth: CGFloat = 0.0
        
        init(icon: Icon, size: CGFloat, borderWidth: CGFloat) {
            self.icon = icon
            self.size = size
            self.borderWidth = borderWidth
            self.isSelected = icon.isCurrent
            
            super.init(frame: CGRect(x: 0, y: 0, width: size + (borderWidth * 2), height: size + (borderWidth * 2)))
            
            layoutMargins = UIEdgeInsets(top: borderWidth, left: borderWidth, bottom: borderWidth, right: borderWidth)
            backgroundColor = UIColor.clear
            clipsToBounds = false
            
            imageView.image = icon[size]
            imageView.clipsToBounds = true
            imageView.contentMode = .scaleAspectFit
            imageView.layer.masksToBounds = true
            addSubview(imageView)
            imageView.layer.mask = innerShapeLayer
            
            borderLayer.lineWidth = 1.0 / UIScreen.main.scale
            borderLayer.fillColor = UIColor.clear.cgColor
            
            imageView.layer.addSublayer(borderLayer)
            
            layer.mask = outerShapeLayer
            
            translatesAutoresizingMaskIntoConstraints = false
            heightAnchor.constraint(equalToConstant: size + (borderWidth * 2)).isActive = true
            widthAnchor.constraint(equalToConstant: size + (borderWidth * 2)).isActive = true
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            updateMasks()
            
            imageView.frame = bounds.inset(by: layoutMargins)
            highlightedView?.frame = bounds
            
            borderLayer.frame = imageView.bounds
        }
        
        private func updateMasks() {
            let outerFrame =  CGRect(origin: .zero, size: bounds.size)
            let innerFrame = CGRect(origin: .zero, size: bounds.inset(by: layoutMargins).size)
            
            borderLayer.path = innerShapeLayer.path
            borderLayer.strokeColor = isSelected ? UIColor.clear.cgColor : unselectedStrokeColor?.cgColor ?? UIColor.clear.cgColor
            
            outerShapeLayer.path = UIBezierPath(roundedRect: outerFrame, cornerRadius: outerFrame.size.width * 0.225).cgPath
            innerShapeLayer.path = UIBezierPath(roundedRect: innerFrame, cornerRadius: innerFrame.size.width * 0.225).cgPath
        }
        
        override func tintColorDidChange() {
            guard isSelected else {
                return
            }
            
            backgroundColor = tintColor
        }
        
        // MARK: Selection
        
        var isSelected: Bool {
            didSet {
                backgroundColor = isSelected ? tintColor : UIColor.clear
                updateMasks()
            }
        }
        
        // MARK: Highlighting
        
        var isHighlighted: Bool {
            get { return highlightedView != nil }
            set {
                if newValue {
                    let view = HighlightedView(frame: bounds.insetBy(dx: -borderWidth, dy: -borderWidth))
                    addSubview(view)
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
            }
            
            required init?(coder aDecoder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
            
        }
        
    }
    
}
