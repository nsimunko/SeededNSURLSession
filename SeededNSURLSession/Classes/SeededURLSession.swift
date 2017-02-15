//
//  SeededURLSession.swift
//
//  Created by Michael Hayman on 2016-05-18.

let MappingFilename = "stubRules"
let MatchingURL = "matching_url"
let JSONFile = "json_file"
let StatusCode = "status_code"
let HTTPMethod = "http_method"
let InlineResponse = "inline_response"

@objc open class SeededURLSession: URLSession {
    let jsonBundle: String!

    public init(jsonBundle named: String) {
        self.jsonBundle = named
    }

    open class func defaultSession(_ queue: OperationQueue = OperationQueue.main) -> URLSession {
        if UIStubber.isRunningAutomationTests() {
            return UIStubber.stubAPICallsSession()
        }
        let session = URLSession(
            configuration: URLSessionConfiguration.default,
            delegate: nil,
            delegateQueue: queue)

        return session
    }

    override open func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        guard let url = request.url else { return errorTask(request.url, reason: "No URL specified", completionHandler: completionHandler) }
        guard let bundle = retrieveBundle(bundleName: jsonBundle) else { return errorTask(url, reason: "No such bundle '\(jsonBundle)' found.", completionHandler: completionHandler) }

        let mappings = retrieveMappingsForBundle(bundle: bundle)

        let mapping = mappings?.filter({ (mapping) -> Bool in
            let httpMethodMatch = request.httpMethod == mapping[HTTPMethod] as? String
            let urlMatch = findMatch(path: mapping.object(forKey: MatchingURL) as AnyObject?, url: url.absoluteString)
            return urlMatch && httpMethodMatch
        }).first

        if let mapping = mapping,
            let jsonFileName = mapping[JSONFile] as? String,
            let statusString = mapping[StatusCode] as? String,
            let statusCode = Int(statusString) {

            var data: Data?
            if let path = bundle.path(forResource: jsonFileName, ofType: "json") {
                data = try? Data(contentsOf: URL(fileURLWithPath: path))
            } else {
                if let response = mapping[InlineResponse] as? String {
                    data = response.data(using: String.Encoding.utf8)
                }
            }

            let task = SeededDataTask(url: url, completion: completionHandler)

            if statusCode == 422 || statusCode == 500 {
                let error = NSError(domain: NSURLErrorDomain, code: Int(CFNetworkErrors.cfurlErrorCannotLoadFromNetwork.rawValue), userInfo: nil)
                task.nextError = error
            }

            let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)

            task.data = data
            task.nextResponse = response
            return task
        } else {
            return errorTask(url, reason: "No mapping found.", completionHandler: completionHandler)
        }
    }

    open func findMatch(path: AnyObject?, url: String) -> Bool {
        guard let regexPattern = path as? String else { return false }

        let modifiedPattern = regexPattern + "$"

        if let _ = url.range(of: modifiedPattern, options: .regularExpression) {
            return true
        }

        return false
    }

    func retrieveBundle(bundleName: String) -> Bundle? {
        guard let bundlePath = Bundle.main.path(forResource: bundleName, ofType: "bundle") else { return nil }
        let bundle = Bundle(path: bundlePath)
        return bundle
    }

    func retrieveMappingsForBundle(bundle: Bundle) -> [NSDictionary]? {
        guard let mappingFilePath = bundle.path(forResource: MappingFilename, ofType: "plist") else { return nil }
        guard let mappings = NSArray(contentsOfFile: mappingFilePath) as? [NSDictionary] else { return nil }
        return mappings
    }
}

// MARK - Error cases
extension SeededURLSession {
    func errorTask(_ url: URL?, reason: String, completionHandler: @escaping DataCompletion) -> SeededDataTask {
        let assignedUrl: URL! = url == nil ? URL(string: "http://www.example.com/") : url

        let task = SeededDataTask(url: assignedUrl, completion: completionHandler)
        task.nextError = NSError(reason: reason)
        return task
    }
}

extension NSError {
    convenience init(reason: String) {
        let errorInfo = [
            NSLocalizedDescriptionKey: reason,
            NSLocalizedFailureReasonErrorKey: reason,
            NSLocalizedRecoverySuggestionErrorKey: ""
        ]
        self.init(domain: "SeededURLSession", code: 55, userInfo: errorInfo)
    }
}
