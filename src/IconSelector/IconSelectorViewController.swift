//
// Copyright © 2021 Daniel Farrelly & Curtis Herbert
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

/// A very simple view controller implementation of the `IconSelector`, which can be instantiated to display a custom
/// collection of icons, or pull the complete list from a given bundle.
@available(iOSApplicationExtension, unavailable)
open class IconSelectorViewController: UITableViewController {

	/// The icons displayed by the receiver.
	public let icons: [Icon]

	/// Creates an `IconSelectorViewController` with the given `icons`.
	/// - Parameter icons: Icons to display
	public init(icons: [Icon]) {
		self.icons = icons
		super.init(nibName: nil, bundle: nil)
	}

	/// Creates an `IconSelectorViewController` with icons from the given `bundle`.
	/// Icons should be defined within the `CFBundleIcons` value of the given `bundle`'s Info.plist.
	/// - Parameter bundle: The `Bundle` to source icons from. Defaults to the `main` bundle.
	public convenience init(bundle: Bundle = .main) {
		self.init(icons: Icon.options(for: bundle))
	}

	public required convenience init?(coder: NSCoder) {
		self.init()
	}

	// MARK: View life cycle

	/// Returns the icon selector managed by the controller object.
	public var iconSelector: IconSelector? {
		return view as? IconSelector
	}

	public override func loadView() {
		let iconSelector = IconSelector(icons: icons)
		iconSelector.backgroundColor = UIColor.white
		iconSelector.layoutMargins = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
		iconSelector.adjustHeightToFitContent = false
		iconSelector.anchorHorizontalEdges = false
		iconSelector.shouldDisplayLabels = true
		iconSelector.scrollView.alwaysBounceVertical = true
		iconSelector.addTarget(self, action: #selector(didSelectIcon(_:)), for: .valueChanged)
		view = iconSelector
	}

	/// Method called when the icon selector is interacted with.
	@objc private func didSelectIcon(_ sender: IconSelector) {
		guard let selectedIcon = sender.selectedIcon else {
			return
		}

		self.iconSelector(sender, didChangeValue: selectedIcon)
	}

	// MARK: Responding to selection

	/// Method called when the icon is selected within the view controller.
	///
	/// - Note: The default implementation validates that alternate icons are supported, and that the application is in
	/// 	an active state before attempting to change the selected icon. If the application is not in an active state,
	/// 	the application will loop until it is.
	/// - Parameters:
	///   - iconSelector: The `IconSelector` that the `selectedIcon` was selected in.
	///   - selectedIcon: The `Icon` that was selected.
	open func iconSelector(_ iconSelector: IconSelector, didChangeValue selectedIcon: Icon) {
		guard UIApplication.shared.supportsAlternateIcons else {
			return
		}

		guard UIApplication.shared.applicationState == .active else {
			DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
				self.iconSelector(iconSelector, didChangeValue: selectedIcon)
			}

			return
		}

		UIApplication.shared.setAlternateIcon(selectedIcon) { error in
			guard let error = error else {
				return
			}

			self.iconSelector(iconSelector, didFailWith: error)
		}
	}

	/// Method called when the application throws an error upon attempting to select an icon.
	///
	/// - Note: The default implementation does nothing, which is a mostly valid option. The only errors really thrown
	/// 	are to indicate that an invalid icon was selected, so as long as the icons you provide during init are
	/// 	sourced from the Info.plist (the default option), you're golden.
	/// - Parameters:
	///   - iconSelector: The `IconSelector` that the `selectedIcon` was selected in.
	///   - error: The `Error` that was thrown by the system.
	open func iconSelector(_ iconSelector: IconSelector, didFailWith error: Swift.Error) {

	}

}
