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

    var cachesUrl: URL {
        libraryUrl.appendingPathComponent("Caches")
    }

    var libraryUrl: URL {
        containerUrl.appendingPathComponent("Data")
            .appendingPathComponent("Library")
    }

    init(bundleId: String) {
        self.bundleId = bundleId
    }

    public func clear() {
        FileManager.default.delete(at: containerUrl)
    }

    public func clearVolatileLaunchState() {
        guard bundleId == "com.tencent.cdnf" else { return }

        let preservedCacheFiles = Set([
            "itop_login.txt",
            "jwt_token.txt",
            "web_ticket.txt"
        ])

        do {
            let cacheItems = try FileManager.default.contentsOfDirectory(
                at: cachesUrl,
                includingPropertiesForKeys: nil
            )

            for item in cacheItems where !preservedCacheFiles.contains(item.lastPathComponent) {
                try FileManager.default.removeItem(at: item)
            }
        } catch CocoaError.fileReadNoSuchFile {
            return
        } catch {
            Log.shared.error(error)
        }
    }

    public func doesExist() -> Bool {
        FileManager.default.fileExists(atPath: containerUrl.path)
    }
}
