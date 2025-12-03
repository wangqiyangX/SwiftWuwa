import Foundation
import OSLog
import SwiftSoup
import WebKit

/// Generic web scraper that uses WKWebView to render JavaScript-heavy pages
/// and SwiftSoup to parse the HTML content. Includes caching to avoid triggering
/// anti-scraping policies.
///
/// The generic type `T` can be any type - single objects, arrays, or custom types.
class WebScraper<T>: NSObject, WKNavigationDelegate {
    private let logger: Logger
    private var webView: WKWebView?
    private var completion: ((T) -> Void)?
    private let parseStrategy: (Document, Logger) throws -> T
    private let renderDelay: TimeInterval

    // Cache storage: URL -> (results, timestamp)
    private var cache: [URL: (results: T, timestamp: Date)] = [:]
    private let cacheQueue = DispatchQueue(
        label: "com.swiftwuwa.webscraper.cache", attributes: .concurrent)

    /// Initialize a WebScraper with a custom parsing strategy
    /// - Parameters:
    ///   - category: Logger category for debugging
    ///   - renderDelay: Time to wait for JavaScript rendering (default: 3.0 seconds)
    ///   - parseStrategy: Closure that takes a SwiftSoup Document and returns parsed result of type T
    init(
        category: String,
        renderDelay: TimeInterval = 3.0,
        parseStrategy: @escaping (Document, Logger) throws -> T
    ) {
        self.logger = Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "SwiftWuwa",
            category: category
        )
        self.renderDelay = renderDelay
        self.parseStrategy = parseStrategy
        super.init()
    }

    /// Fetch and parse content from a URL
    /// - Parameters:
    ///   - url: The URL to scrape
    ///   - forceRefresh: If true, bypass cache and fetch fresh data. Default is false.
    ///   - completion: Completion handler with parsed result
    func fetch(from url: URL, forceRefresh: Bool = false, completion: @escaping (T) -> Void) {
        // Check cache first if not forcing refresh
        if !forceRefresh {
            if let cachedData = getCachedData(for: url) {
                logger.info("Returning cached data for: \(url.absoluteString)")
                completion(cachedData)
                return
            }
        }

        // Fetch fresh data
        self.completion = { [weak self] result in
            self?.cacheData(result, for: url)
            completion(result)
        }

        DispatchQueue.main.async {
            self.logger.info(
                "Starting fetch with WKWebView from: \(url.absoluteString) (forceRefresh: \(forceRefresh))"
            )
            let config = WKWebViewConfiguration()
            self.webView = WKWebView(frame: .zero, configuration: config)
            self.webView?.navigationDelegate = self
            self.webView?.load(URLRequest(url: url))
        }
    }

    /// Clear all cached data
    func clearCache() {
        cacheQueue.async(flags: .barrier) {
            self.cache.removeAll()
            self.logger.info("Cache cleared")
        }
    }

    /// Clear cached data for a specific URL
    /// - Parameter url: The URL to clear from cache
    func clearCache(for url: URL) {
        cacheQueue.async(flags: .barrier) {
            self.cache.removeValue(forKey: url)
            self.logger.info("Cache cleared for: \(url.absoluteString)")
        }
    }

    /// Get cache statistics
    /// - Returns: Dictionary with cache info (count, URLs)
    func getCacheInfo() -> [String: Any] {
        var info: [String: Any] = [:]
        cacheQueue.sync {
            info["count"] = cache.count
            info["urls"] = cache.keys.map { $0.absoluteString }
            info["timestamps"] = cache.mapValues { $0.timestamp }
        }
        return info
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        logger.info(
            "WebView finished navigation, waiting \(self.renderDelay)s for content to render...")

        DispatchQueue.main.asyncAfter(deadline: .now() + renderDelay) { [weak self] in
            guard let self = self else { return }

            webView.evaluateJavaScript("document.documentElement.outerHTML") { result, error in
                if let error = error {
                    self.logger.error("Error getting HTML: \(error.localizedDescription)")
                    self.handleError()
                    return
                }

                if let html = result as? String {
                    self.parseHTML(html)
                } else {
                    self.logger.error("Failed to cast HTML result")
                    self.handleError()
                }
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        logger.error("WebView navigation failed: \(error.localizedDescription)")
        handleError()
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        logger.error("WebView provisional navigation failed: \(error.localizedDescription)")
        handleError()
    }

    // MARK: - Private Methods

    private func parseHTML(_ html: String) {
        do {
            let doc = try SwiftSoup.parse(html)
            logger.debug("Parsed HTML length: \(html.count)")

            let result = try parseStrategy(doc, logger)
            logger.info("Successfully parsed content")
            completion?(result)

        } catch {
            logger.error("Parsing error: \(error)")
            handleError()
        }
        cleanup()
    }

    private func handleError() {
        // For error handling, we can't provide a default value for generic T
        // The caller should handle nil/error cases appropriately
        cleanup()
    }

    private func cleanup() {
        webView = nil
        completion = nil
    }

    // MARK: - Cache Management

    private func getCachedData(for url: URL) -> T? {
        var cachedResult: T?
        cacheQueue.sync {
            if let cached = cache[url] {
                cachedResult = cached.results
            }
        }
        return cachedResult
    }

    private func cacheData(_ data: T, for url: URL) {
        cacheQueue.async(flags: .barrier) {
            self.cache[url] = (results: data, timestamp: Date())
            self.logger.debug("Cached data for: \(url.absoluteString)")
        }
    }
}
