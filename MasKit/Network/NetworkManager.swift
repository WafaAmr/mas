//
//  NetworkManager.swift
//  MasKit
//
//  Created by Ben Chatelain on 1/5/19.
//  Copyright © 2019 mas-cli. All rights reserved.
//

import Foundation

/// Network abstraction
public class NetworkManager {
    enum NetworkError: Error {
        case timeout
    }

    private let session: NetworkSession

    /// Designated initializer
    ///
    /// - Parameter session: A networking session.
    public init(session: NetworkSession = URLSession(configuration: .ephemeral)) {
        self.session = session

        // Older releases allowed URLSession to write a cache. We clean it up here.
        do {
            let url = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Caches/com.mphys.mas-cli")
            try FileManager.default.removeItem(at: url)
        } catch {}
    }

    /// Loads data asynchronously.
    ///
    /// - Parameters:
    ///   - url: URL to load data from.
    ///   - completionHandler: Closure where result is delivered.
    func loadData(from url: URL, completionHandler: @escaping (NetworkResult) -> Void) {
        session.loadData(from: url) { (data: Data?, error: Error?) in
            let result: NetworkResult =
                data != nil
                ? .success(data!)
                : .failure(error!)
            completionHandler(result)
        }
    }

    /// Loads data synchronously.
    ///
    /// - Parameter url: URL to load data from.
    /// - Returns: Network result containing either Data or an Error.
    func loadDataSync(from url: URL) -> NetworkResult {
        var syncResult: NetworkResult?
        let semaphore = DispatchSemaphore(value: 0)

        loadData(from: url) { asyncResult in
            syncResult = asyncResult
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .distantFuture)

        guard let result = syncResult else {
            return .failure(NetworkError.timeout)
        }

        return result
    }
}
