//
//  AppContainer.swift
//  PlayCover
//
//  Created by Александр Дорофеев on 07.12.2021.
//

import Darwin
import Foundation

struct AppContainer {

    private static let containersURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library")
        .appendingPathComponent("Containers")

    let bundleId: String

    private static var shouldApplyPreM4Workarounds: Bool {
        var size = 0
        guard sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0) == 0,
              size > 0 else {
            return false
        }

        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname("machdep.cpu.brand_string", &buffer, &size, nil, 0) == 0 else {
            return false
        }

        let brand = String(cString: buffer)
        return brand.contains("Apple M1")
            || brand.contains("Apple M2")
            || brand.contains("Apple M3")
    }

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

    private var preservedLaunchCacheFiles: [String] {
        [
            "itop_login.txt",
            "jwt_token.txt",
            "web_ticket.txt"
        ]
    }

    public func clearVolatileLaunchState() -> [String: Data] {
        guard bundleId == "com.tencent.cdnf",
              AppContainer.shouldApplyPreM4Workarounds else { return [:] }

        let preservedFiles = preservedLaunchCacheFiles.reduce(into: [String: Data]()) { result, fileName in
            let fileUrl = cachesUrl.appendingPathComponent(fileName)

            if let data = try? Data(contentsOf: fileUrl) {
                result[fileName] = data
            }
        }

        FileManager.default.delete(at: cachesUrl)

        return preservedFiles
    }

    public func restoreVolatileLaunchState(_ files: [String: Data]) {
        guard bundleId == "com.tencent.cdnf",
              AppContainer.shouldApplyPreM4Workarounds,
              !files.isEmpty else { return }

        do {
            try FileManager.default.createDirectory(
                at: cachesUrl,
                withIntermediateDirectories: true
            )

            for (fileName, data) in files {
                try data.write(
                    to: cachesUrl.appendingPathComponent(fileName),
                    options: .atomic
                )
            }
        } catch {
            Log.shared.error(error)
        }
    }

    public func doesExist() -> Bool {
        FileManager.default.fileExists(atPath: containerUrl.path)
    }
}
