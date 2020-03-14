//
//  APIServices.swift
//  Workshop
//
//  Created by Jorge Armando Torres Perez on 3/14/20.
//

import Foundation

class APIServices {
    public static let shared = APIServices()
    private let defaultSession = URLSession(configuration: .default)
    private var dataTask: URLSessionDataTask?

    private enum _URLS {
        static let baseURLCity = "http://api.citybik.es"
        static let cityBikeNetworks = "/v2/networks"
        static let filterLocation = "?fields=location,href"
        static let URL_NETWORKS = baseURLCity + cityBikeNetworks + filterLocation
    }
    
    func getNetwork(completion: @escaping (_ result: [Network]?) -> Void) {
        dataTask?.cancel()
        guard let url = URL(string: _URLS.URL_NETWORKS) else { return completion(nil) }
        dataTask = defaultSession.dataTask(with: url) { [weak self] data, response, error in
            defer {
                self?.dataTask = nil
            }
            guard error == nil else { return completion(nil) }
            if let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 {
                do {
                    let jsonResponse = try JSONSerialization.jsonObject(with: data, options: [])
                    guard let networks = jsonResponse as? [String: Any] else { return completion(nil) }
                    guard let jsonArray = networks["networks"] as? [[String: Any]] else { return completion(nil) }
                    var model = [Network]()
                    for dic in jsonArray {
                        model.append(Network(dic))
                    }
                    DispatchQueue.main.async {
                      completion(model)
                    }
                }
                catch let parsingError {
                    print("Error", parsingError)
                    completion(nil)
                }
            }
          }
        dataTask?.resume()
    }

    func getBicycles(href: String, completion: @escaping (_ result: Network?) -> Void) {
        dataTask?.cancel()
        guard let url = URL(string: _URLS.baseURLCity + href) else { return completion(nil) }
        dataTask = defaultSession.dataTask(with: url) { [weak self] data, response, error in
            defer {
                self?.dataTask = nil
            }
            guard error == nil else { return completion(nil) }
            if let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 {
                do {
                    let jsonResponse = try JSONSerialization.jsonObject(with: data, options: [])
                    guard let networks = jsonResponse as? [String: Any] else { return completion(nil) }
                    guard let jsonArray = networks["network"] as? [String: Any] else { return completion(nil) }
                      completion(Network(jsonArray))
                }
                catch let parsingError {
                    print("Error", parsingError)
                    completion(nil)
                }
            }
          }
        dataTask?.resume()
    }

}

enum HttpMethod: String {
    case get
    case post
    case put
    case patch
    case delete
}
