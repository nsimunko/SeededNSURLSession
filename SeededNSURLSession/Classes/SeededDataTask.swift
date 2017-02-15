//
//  SeededDataTask.swift
//
//  Created by Michael Hayman on 2016-05-18.

public typealias DataCompletion = (Data?, URLResponse?, NSError?) -> Void

@objc open class SeededDataTask: URLSessionDataTask {
    fileprivate let url: URL
    fileprivate let completion: DataCompletion
    var data: Data?
    var nextError: NSError?
    var nextResponse: HTTPURLResponse?

    init(url: URL, completion: @escaping DataCompletion) {
        self.url = url
        self.completion = completion
        self.data = nil
    }

    override open func resume() {
        completion(data, nextResponse, nextError)
    }
}
