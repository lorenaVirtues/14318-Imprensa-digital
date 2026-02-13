//
//  Extension.swift
//  zueira
//
//  Created by Virtues25 on 21/01/26.
//

import Foundation
import SwiftUI
import Combine

extension Bundle {
    /// Ex.: "1.0.2"
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
    }

    /// Ex.: "42"
    var appBuild: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "-"
    }

    /// Ex.: "1.0.2 (42)"
    var appVersionBuild: String {
        "\(appVersion) (\(appBuild))"
    }
}
extension Notification.Name {
    static let appShouldStopRadio = Notification.Name("appShouldStopRadio")
    static let appShouldStopExternalPlayer = Notification.Name("appShouldStopExternalPlayer")
}
