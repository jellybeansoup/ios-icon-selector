//
// Copyright © 2021 Daniel Farrelly & Curtis Herbert
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// *	Redistributions of source code must retain the above copyright notice, this list
//		of conditions and the following disclaimer.
// *	Redistributions in binary form must reproduce the above copyright notice, this
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

import Foundation
import UIKit

/// An app Icon, as defined in the `Info.plist`
public struct Icon {

	// MARK: Public Properties

	/// Gets the name of this icon
	/// - Note: If the name is `nil`, it is safe to assume
	///         this is the default icon.
	public let name: String?

	/// The name used to reference the app icon within the app's asset catalog.
	/// - Note: The default value of this property reflects the Info.plist value with the key `CFBundleIconName`.
	public let assetName: String?

	/// Gets an array of the files associated with this icon
	public let files: [String]

	/// Gets a flag indicating if this icon has been prerendered or not
	public let isPrerendered: Bool

	/// The `Bundle` this icon is found in
	private weak var bundle: Bundle?

	/// Gets a flag indicating whether or not this is the currently selected icon
	@available(iOSApplicationExtension, unavailable)
	public var isCurrent: Bool {
		let application = UIApplication.shared

		guard application.supportsAlternateIcons else {
			return name == nil
		}

		return name == application.alternateIconName
	}

	/// Creates an `Icon` using the given name and `Bundle`
	/// - Parameters:
	///   - named: Name of the icon to create
	///   - bundle: Optional `Bundle` to find the icon within;
	///             defaults to the `main` bundle.
	public init?(named: String, bundle: Bundle = .main) {
		let icons: [Icon]
		if bundle == .main {
			icons = Icon.main
		}
		else {
			icons = Icon.options(for: bundle)
		}

		guard let icon = icons.first(where: { $0.name == named }) else {
			return nil
		}

		self = icon
	}

	// MARK: Parsing the Info.plist

	/// Gets the `Icon`s for the `main` `Bundle`
	public static let main = options(for: .main)

	/// Gets the default `Icon`, if possible
	public static var `default`: Icon? = {
		let bundle = Bundle.main

		guard let iconDictionary = bundle.infoDictionary?["CFBundleIcons"] as? [String: Any] else {
			return nil
		}

		guard let primary = iconDictionary["CFBundlePrimaryIcon"] as? [String: Any] else {
			return nil
		}

		return Icon(key: nil, dictionary: primary, bundle: bundle)
	}()

	/// Gets the `Icon`s defined in the given `Bundle`
	/// - Parameter bundle: The `Bundle` to load from
	public static func options(for bundle: Bundle) -> [Icon] {
		guard let iconDictionary = bundle.infoDictionary?["CFBundleIcons"] as? [String: Any] else {
			return []
		}

		var icons: [Icon] = []

		if let primary = iconDictionary["CFBundlePrimaryIcon"] as? [String: Any] {
			icons.append(Icon(key: nil, dictionary: primary, bundle: bundle))
		}

		if let alternate = iconDictionary["CFBundleAlternateIcons"] as? [String: [String: Any]] {
			icons.append(contentsOf: alternate.sorted(by: { $0.key > $1.key }).map { Icon(key: $0, dictionary: $1, bundle: bundle) })
		}

		return icons
	}

	private init(key: String?, dictionary: [String: Any], bundle: Bundle) {
		self.name = key
		self.assetName = dictionary["CFBundleIconName"] as? String
		self.files = dictionary["CFBundleIconFiles"] as? [String] ?? []
		self.isPrerendered = dictionary["UIPrerenderedIcon"] as? Bool ?? false
		self.bundle = bundle

		if let assetName = dictionary["CFBundleIconName"] as? String {
			self.displayNameProvider = { assetName }
		}
	}

	// MARK: Accessing images

	private static let numberFormatter: NumberFormatter = {
		let formatter = NumberFormatter()
		formatter.minimumFractionDigits = 0
		formatter.maximumFractionDigits = 1
		return formatter
	}()

	public subscript(_ name: String) -> UIImage? {
		guard let bundle = bundle, files.contains(name) else {
			return nil
		}

		for scale in stride(from: UIScreen.main.scale, through: 1, by: -1) {
			if let path = bundle.path(forResource: "\(name)@\(Int(scale))x", ofType: "png") {
				let url = URL(fileURLWithPath: path)
				if let data = try? Data(contentsOf: url) {
					return UIImage(data: data)
				}
			}
		}

		return nil
	}

	public subscript(_ size: CGFloat) -> UIImage? {
		guard let string = Icon.numberFormatter.string(from: NSNumber(value: Double(size))) else {
			return nil
		}

		guard let file = files.first(where: { $0.hasSuffix("\(string)x\(string)") || $0.hasSuffix("-\(string)") }) else {
			return nil
		}

		return self[file]
	}

	// MARK: Display Name Modifiers

	/// An string that can be used to represent the current `Icon` to the user.
	public var displayName: String? {
		if let provider = displayNameProvider {
			return provider()
		}
		else if let name = assetName {
			return name
		}
		else if let name = name {
			return name
		}

		return nil
	}

	var displayNameProvider: (() -> String)?

	/// Creates a copy of the receiver the provided `content` as its `displayName`.
	/// - Parameter content: A string to use without localization.
	public func displayName(_ content: String) -> Icon {
		var icon = self
		icon.displayNameProvider = { content }
		return icon
	}

	/// Creates a copy of the receiver with a `displayName` matching the given parameters.
	/// - Parameters:
	///   - localized: The key for a string in the specified table.
	///   - table: The name of the table containing the key-value pairs. Also, the suffix
	///   		for the strings file (a file with the `.strings` extension) to store the
	///   		localized string. This defaults to the table in `Localizable.strings` when
	///   		`table` is `nil` or an empty string.
	///   - bundle: The bundle containing the table’s strings file. The main bundle is
	///   		used if one isn’t specified.
	///   - comment: The comment to place above the key-value pair in the strings file.
	///   		This parameter provides the translator with some context about the
	///   		localized string’s presentation to the user.
	public func displayName(localized: String, table: String? = nil, bundle: Bundle = .main, comment: String = "") -> Icon {
		var icon = self
		icon.displayNameProvider = { NSLocalizedString(localized, tableName: table, bundle: bundle, comment: comment) }
		return icon
	}

	/// Creates a copy of the receiver with a `displayName` matching the given localization resource.
	/// - Parameter localized: A localization resource.
	@available(iOS 16, *)
	public func displayName(localized: LocalizedStringResource) -> Icon {
		var icon = self
		icon.displayNameProvider = { String(localized: localized) }
		return icon
	}

	// MARK: Display Image Modifiers

	/// An image that can be used to preview the current Icon.
	public var displayImage: UIImage? {
		if let provider = displayImageProvider, let image = provider() {
			return image
		}
		else if let image = self[60] {
			return image
		}
		else if let name = assetName, let image = UIImage(named: name) {
			return image
		}

		return nil
	}

	var displayImageProvider: (() -> UIImage?)?

	/// Creates a copy of the receiver with a `displayImage` matching the given parameters.
	/// - Parameters:
	///   - name: The name of the image asset or file.
	///   - bundle: The bundle containing the image file or asset catalog.
	///   - configuration: The traits associated with the intended environment for the
	///   		image. Use this parameter to ensure that the system loads the correct
	///   		variant of the image. If you specify `nil`, this method uses the traits
	///   		associated with the main screen.
	public func displayImage(_ name: String, bundle: Bundle = .main, compatibleWith traitCollection: UITraitCollection? = nil) -> Icon {
		var icon = self
		icon.displayImageProvider = { UIImage(named: name, in: bundle, compatibleWith: traitCollection) }
		return icon
	}

	/// Creates a copy of the receiver with a `displayImage` matching the given parameters.
	/// - Parameters:
	///   - name: The name of the image asset or file.
	///   - bundle: The bundle containing the image file or asset catalog.
	///   - configuration: The image configuration that you want. Use this parameter to
	///   		specify traits and other details that define which variant of the image
	///   		you want.
	@available(iOS 13.0, *)
	public func displayImage(_ name: String, bundle: Bundle = .main, with configuration: UIImage.Configuration?) -> Icon {
		var icon = self
		icon.displayImageProvider = { UIImage(named: name, in: bundle, with: configuration) }
		return icon
	}

	/// Creates a copy of the receiver with a `displayImage` matching the given `resource`.
	/// - Parameter resource: An image resource.
	@available(iOS 17.0, *)
	public func displayImage(_ resource: ImageResource) -> Icon {
		var icon = self
		icon.displayImageProvider = { UIImage(resource: resource) }
		return icon
	}

	// MARK: Deprecated
	
	/// The user-visible display name for the icon, which is displayed under the icon (and used as the spoken
	/// accessibility text) if `IconSelector.shouldDisplayLabels` is set to `true`.
	/// - Note: The default value of this property reflects the Info.plist value with the key `CFBundleIconName`.
	public var localizedName: String? {
		get {
			displayNameProvider?() ?? assetName
		}
		set {
			if let newValue {
				displayNameProvider = { newValue }
			} else {
				displayNameProvider = nil
			}
		}
	}

	/// Creates a copy of the receiver with the given `localizedName`.
	/// - Parameter localizedName: The user-visible display name to give the icon.
	@available(*, deprecated, message: "Use displayName(_:) instead.")
	public func with(localizedName: String) -> Icon {
		displayName(localizedName)
	}

}

extension Icon: Equatable {

	public static func == (lhs: Icon, rhs: Icon) -> Bool {
		return lhs.name == rhs.name
	}

}

extension Icon: CustomDebugStringConvertible {

	public var debugDescription: String {
		let prerendered = isPrerendered ? "; prerendered": ""

		if let key = name {
			return "<Icon \"\(key)\"; \(files.count) file(s)\(prerendered)>"
		}
		else {
			return "<Icon (default); \(files.count) file(s)\(prerendered)>"
		}
	}

}

