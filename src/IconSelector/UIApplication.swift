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

extension UIApplication {
	
	/// Gets or sets an alternate icon to use
	public var alternateIcon: Icon? {
		get {
			let application = UIApplication.shared

			guard application.supportsAlternateIcons, let name = application.alternateIconName else {
				return Icon.default
			}

			return Icon(named: name)
		}
		set {
			setAlternateIcon(newValue, completionHandler: nil)
		}
	}
	
	/// Sets a new alternate icon
	/// - Parameters:
	///   - icon: Icon to set; use `nil` to restore the default
	///   - completionHandler: optional completion handler
	public func setAlternateIcon(_ icon: Icon?, completionHandler: ((_ error: Swift.Error?) -> Void)? = nil) {
		let application = UIApplication.shared

		guard application.supportsAlternateIcons else {
			return
		}

		application.setAlternateIconName(icon?.name, completionHandler: completionHandler)
	}

}

