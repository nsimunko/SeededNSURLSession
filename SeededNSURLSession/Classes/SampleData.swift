//
//  SampleData.swift
//
//  Created by Michael Hayman on 2016-05-18.

@objc open class SampleData: NSObject {
    open class func retrieveDataFromBundleWithName(bundle bundleName: String, resource: String) -> Data? {
        let bundle = Bundle.main

        guard let bundlePath = bundle.path(forResource: bundleName, ofType: "bundle") else { return nil }
        guard let jsonBundle = Bundle(path: bundlePath) else { return nil }
        guard let path = jsonBundle.path(forResource: resource, ofType: "json") else { return nil }

        return (try? Data(contentsOf: URL(fileURLWithPath: path)))
    }
}
