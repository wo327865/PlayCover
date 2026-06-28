//
//  AppContainer.swift
//  PlayCover
//
//  Created by Александр Дорофеев on 07.12.2021.
//

import Foundation

struct AppContainer {

    private static let containersURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library")
        .appendingPathComponent("Containers")

    let bundleId: String
    var containerUrl: URL {
        AppContainer.containersURL.appendingPathComponent(bundleId)
    }

    var userPrefsUrl: URL {
        containerUrl.appendingPathComponent("Data")
            .appendingPathComponent("Library")
            .appendingPathComponent("Preferences")
            .appendingPathComponent(bundleId)
            .appendingPathExtension("plist")
    }

    var savedApplicationStateUrl: URL {
        containerUrl.appendingPathComponent("Data")
            .appendingPathComponent("Library")
            .appendingPathComponent("Saved Application State")
            .appendingPathComponent("\(bundleId)~iosmac")
            .appendingPathExtension("savedState")
    }

    init(bundleId: String) {
        self.bundleId = bundleId
    }

    public func clear() {
        FileManager.default.delete(at: containerUrl)
    }

    public func disableSavedApplicationState() {
        var preferences = NSDictionary(contentsOf: userPrefsUrl) as? [String: Any] ?? [:]

        let ignoresState = preferences["ApplePersistenceIgnoreState"] as? Bool == true
        let closesWindows = preferences["NSQuitAlwaysKeepsWindows"] as? Bool == false

        if !ignoresState || !closesWindows {
            preferences["ApplePersistenceIgnoreState"] = true
            preferences["NSQuitAlwaysKeepsWindows"] = false

            do {
                try FileManager.default.createDirectory(
                    at: userPrefsUrl.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                let data = try PropertyListSerialization.data(
                    fromPropertyList: preferences,
                    format: .binary,
                    options: 0
                )
                try data.write(to: userPrefsUrl, options: .atomic)
            } catch {
                Log.shared.error(error)
            }
        }

        FileManager.default.delete(at: savedApplicationStateUrl)
    }

    public func doesExist() -> Bool {
        FileManager.default.fileExists(atPath: containerUrl.path)
    }
}
