//
// Copyright © 2019 Daniel Farrelly
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

public struct Icon {

	public let name: String?

	public let files: [String]

	public let isPrerendered: Bool

	private weak var bundle: Bundle?

	public var isCurrent: Bool {
		let application = UIApplication.shared

		guard application.supportsAlternateIcons else {
			return name == nil
		}

		return name == application.alternateIconName
	}

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

	public static let main = options(for: .main)

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

		return UIImage(named: name, in: bundle, compatibleWith: nil)
	}

	public subscript(_ size: CGFloat) -> UIImage? {
		guard let bundle = bundle, let string = Icon.numberFormatter.string(from: NSNumber(value: Double(size))) else {
			return nil
		}

		guard let file = files.first(where: { $0.hasSuffix("\(string)x\(string)") || $0.hasSuffix("-\(string)") }) else {
			return nil
		}

		return UIImage(named: file, in: bundle, compatibleWith: nil)
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
