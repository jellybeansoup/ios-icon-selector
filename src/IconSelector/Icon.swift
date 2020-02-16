//
// Copyright © 2019 Daniel Farrelly & Curtis Herbert
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

	/// The user-visible display name for the icon, which is displayed under the icon (and used as the spoken
	/// accessibility text) if `IconSelector.shouldDisplayLabels` is set to `true`.
	/// - Note: The default value of this property reflects the Info.plist value with the key `CFBundleIconName`.
	public var localizedName: String?

	/// Gets an array of the files associated with this icon
	public let files: [String]
	
	/// Gets a flag indicating if this icon has been prerendered or not
	public let isPrerendered: Bool
	
	/// The `Bundle` this icon is found in
	private weak var bundle: Bundle?
	
	/// Gets a flag indicating whether or not this is the currently selected icon
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
		self.localizedName = dictionary["CFBundleIconName"] as? String
		self.files = dictionary["CFBundleIconFiles"] as? [String] ?? []
		self.isPrerendered = dictionary["UIPrerenderedIcon"] as? Bool ?? false
		self.bundle = bundle
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

	// MARK: Making copies

	/// Creates a copy of the receiver with the given `localizedName`.
	/// - Parameter localizedName: The user-visible display name to give the icon.
	public func with(localizedName: String) -> Icon {
		var icon = self
		icon.localizedName = localizedName
		return icon
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

