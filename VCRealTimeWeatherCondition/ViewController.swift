//
//  ViewController.swift
//  VCRealTimeWeatherCondition
//
//  Created by victor on 2018/4/17.
//  Copyright © 2018 VHHC Studio. All rights reserved.
//

import UIKit
import WebKit
import Kanna

class ViewController: UIViewController, WKNavigationDelegate {

    @IBOutlet weak var tempLabel: UILabel!
    
    @IBOutlet weak var relHumidLabel: UILabel!
    
    @IBOutlet weak var loadingPageIndicator: UIActivityIndicatorView!
    
    var wkWebView: WKWebView!
    
    var html: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loadWKWebView()
    }

    // MARK: - webkit functions
    
    func loadWKWebView() {
        
        let webViewRatio: CGFloat = 0.35
        wkWebView = WKWebView(frame: CGRect(x: 0.0, y: view.bounds.size.height * (1.0 - webViewRatio), width: view.bounds.size.width, height: view.bounds.size.height * webViewRatio))
        wkWebView.navigationDelegate = self
        wkWebView.alpha = 0.0
        self.view.addSubview(wkWebView)
        guard let url = URL(string: Constants.baseUrl) else {
            print("failed to create url")
            return
        }
        let urlRequest = URLRequest(url: url)
        wkWebView.load(urlRequest)
        loadingPageIndicator.startAnimating()
    }
    
    //MARK: - webkit callbacks
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingPageIndicator.stopAnimating()
        loadingPageIndicator.hidesWhenStopped = true
        wkWebView.alpha = 1.0
        
        currentTemperature()
    }
    
    //MARK: - html parser
    
    func currentTemperature() {
        
//        guard let url = URL(string: Constants.baseUrl) else {
//            print("Error: \(Constants.baseUrl) is not a valid URL")
//            return
//        }
//
//        do {
//            let htmlString = try String(contentsOf: url, encoding: .utf8)
//            html = htmlString
//        } catch let error {
//            print("Error: \(error)")
//        }

        
        wkWebView.evaluateJavaScript("document.documentElement.outerHTML.toString()") { (result, error) in
            print(result)
            self.html = result as! String
            
            if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                
                let fileURL = dir.appendingPathComponent("weather.txt")
                
                //writing
                do {
                    try self.html.write(to: fileURL, atomically: false, encoding: .utf8)
                }
                catch {/* error handling here */}
            }
        }
        
        
    }
}

