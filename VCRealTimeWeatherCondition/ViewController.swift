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
    
    @IBOutlet weak var locationLabel: UILabel!
    
    @IBOutlet weak var dateTimeLabel: UILabel!
    
    @IBOutlet weak var locationNameLabel: UILabel!
    
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
//        wkWebView.alpha = 1.0
        
        fetchAndUpdateData()
    }
    
    //MARK: - html parser
    
    func fetchAndUpdateData() {

        // get the result of the requested page
        wkWebView.evaluateJavaScript("document.documentElement.outerHTML.toString()") { (result, error) in

            self.html = result as! String
            
            // parsing
            do {
                let doc = try HTML(html: self.html, encoding: .utf8)
              
                for tr in doc.xpath("//tbody/tr") {
                    for td in tr.xpath("./td") {
                        guard let locationNameString: String = td.text else {continue}
//                        print(locationNameString)
                        if locationNameString == "臺灣大學" || locationNameString == "大安森林" {
                            
                            
                            let dateTime = tr.xpath("./td[3]")
                            
                            if let node = dateTime.first {
                                if let dateTimeString: String = node.content {

                                    if dateTimeString.contains("儀器")  {
                                        continue
                                    }
                                    self.dateTimeLabel.text = dateTimeString
                                    
                                    self.locationLabel.text = locationNameString
                                    
                                    let temp1 = tr.xpath("./td[4]")
                                    
                                    if let node = temp1.first {
                                        if let tempString: String = node.content {
                                            self.tempLabel.text = tempString
                                        }
                                    }
                                    
                                    let td13 = tr.xpath("./td[13]")
                                    
                                    if let node = td13.first {
                                        if let humidityString: String = node.content {
                                            self.relHumidLabel.text = humidityString
                                        }
                                    }
                                    return
                                }
                            }
                        }
                        
                    }
                }
                
//                let temp1 = doc.xpath("//tbody/tr[2]/td[@class='temp1']")
//
//                if let node = temp1.first {
//                    if let tempString: String = node.content {
//                        self.tempLabel.text = tempString
//                    }
//                }
//
//                let td8 = doc.xpath("//tbody/tr[2]/td[8]")
//
//                if let node = td8.first {
//                    if let humidityString: String = node.content {
//                        self.relHumidLabel.text = humidityString
//                    }
//                }
            } catch {/* error handling here */}
        }
    }
}

