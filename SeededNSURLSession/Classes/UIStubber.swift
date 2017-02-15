//
//  SeededDataTask.swift
//
//  Created by Michael Hayman on 2016-05-18.

@objc open class UIStubber: NSObject {
    open class func session() -> URLSession {
        if isRunningAutomationTests() {
            return stubAPICallsSession()
        } else {
            return URLSession.shared
        }
    }

    open class func isRunningAutomationTests() -> Bool {
        if ProcessInfo.processInfo.arguments.contains("RUNNING_AUTOMATION_TESTS") {
            return true
        }
        return false
    }

    open class func stubAPICallsSession() -> URLSession {
        // e.g. if 'STUB_API_CALLS_stubsTemplate_addresses' is received as argument
        // we globally stub the app using the 'stubsTemplate_addresses.bundle'
        let stubPrefix = "STUB_API_CALLS_"

        let stubPrefixForPredicate = stubPrefix + "*";

        let predicate = NSPredicate(format: "SELF like %@", stubPrefixForPredicate)

        let filteredArray = ProcessInfo.processInfo.arguments.filter { predicate.evaluate(with: $0) }

        let bundleName = filteredArray.first?.replacingOccurrences(of: stubPrefix, with: "")

        if let bundleName = bundleName {
            return SeededURLSession(jsonBundle: bundleName)
        } else {
            return URLSession.shared
        }
    }
}
