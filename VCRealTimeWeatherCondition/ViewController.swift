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
    
    @IBOutlet weak var rainfallLabel: UILabel!
    
    @IBOutlet weak var locationNameLabel: UILabel!
    
    var wkWebView: WKWebView!
    var wkWebView2: WKWebView!
    var isTempHumidDataRetrieved: Bool!
    var isRainfallDataRetrieved: Bool!

    var html: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        isTempHumidDataRetrieved = false
        isRainfallDataRetrieved = false

        removeWKWebViewCookies()
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
        
        // for getting rainfall
        //
//        wkWebView2 = WKWebView(frame: CGRect(x: 0.0, y: view.bounds.size.height * (1.0 - webViewRatio), width: view.bounds.size.width, height: view.bounds.size.height * webViewRatio))
//        wkWebView2.navigationDelegate = self
//        wkWebView2.alpha = 0.0
//        self.view.addSubview(wkWebView2)
//        guard let url2 = URL(string: Constants.baseUrl2) else {
//            print("failed to create url")
//            return
//        }
//        let urlRequest2 = URLRequest(url: url2)
//        wkWebView2.load(urlRequest2)
//        loadingPageIndicator.startAnimating()
    }
    
    //MARK: - webkit callbacks
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        if webView == wkWebView {
            print("callback didFinish from wkWebView")
//            fetchAndUpdateData()
            parseHtml()
            
        } else if webView == wkWebView2 {
            print("callback didFinish from wkWebView2")
//            fetchAndUpdateData2()
        }
    }
    
    //MARK: - html parser
    func parseHtml() {
        DispatchQueue.main.async {
            self.wkWebView.evaluateJavaScript("document.documentElement.outerHTML.toString()") { (result, error) in
                if error != nil {
                    print("error: #1")
                    return
                }
                self.html = result as? String
                print("html length:\(self.html.count)")

                // parsing
                do {
                    let doc = try HTML(html: self.html, encoding: .utf8)
                    
                    let trs = doc.xpath("//tbody/tr")
//                    let trs = doc.xpath("/html/body//main/div/div[1]").first?.text

                    
                    if trs.count == 0 {
                        print("ERROR: page failed to be loaded completely")
                        self.parseHtml()
                    }
                    for tr in trs {
                        let th = tr.xpath("./th")
                        
                        guard let locationNameString: String = th.first?.text else {continue}
                        print(locationNameString)
                        if locationNameString != "臺灣大學" && locationNameString != "大安森林" && locationNameString != "信義" {
                            continue
                        }

                        var dateTime = tr.xpath("./td[1]/span").first
                        if dateTime == nil {
                            dateTime = tr.xpath("./td[1]").first
                        }

                        if let dateTimeString: String = dateTime?.content {

                            if dateTimeString.contains("儀器") || dateTimeString.contains("-")  {
                                continue
                            }
                            
                            self.tempLabel.text = tr.xpath("./td[2]").first?.content
                            self.relHumidLabel.text = tr.xpath("./td[8]").first?.content
                            
                            self.dateTimeLabel.text = dateTimeString
                            self.locationLabel.text = locationNameString
                            self.isTempHumidDataRetrieved = true
                            
                            self.loadingPageIndicator.stopAnimating()
                            self.loadingPageIndicator.hidesWhenStopped = true
                            return
                        }
                        
                    }
                    
                } catch let error {
                    print("Error:\(error.localizedDescription)")
                }
                
            }
                
        }
    }
    
    func fetchAndUpdateData() {

        // get the result of the requested page
        wkWebView.evaluateJavaScript("document.documentElement.outerHTML.toString()") { (result, error) in

            self.html = result as? String
            
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

                                    if dateTimeString.contains("儀器") || dateTimeString.contains("-")  {
                                        continue
                                    }
                                    
                                    let temperature = tr.xpath("./td[4]")
                                    
                                    if let node = temperature.first {
                                        if let temperatureString: String = node.content {

                                            if temperatureString.contains("儀器") || temperatureString.contains("-")  {
                                                continue
                                            }
                                            self.tempLabel.text = temperatureString
                                        }
                                    }
                                    
                                    let td13 = tr.xpath("./td[13]")
                                    
                                    if let node = td13.first {
                                        if let humidityString: String = node.content {
                                            
                                            if humidityString.contains("儀器") || humidityString.contains("-")  {
                                                continue
                                            }
                                            self.relHumidLabel.text = humidityString
                                        }
                                    }
                                    
                                    self.dateTimeLabel.text = dateTimeString
                                    self.locationLabel.text = locationNameString
                                    self.isTempHumidDataRetrieved = true
                                    if self.isRainfallDataRetrieved {
                                        self.loadingPageIndicator.stopAnimating()
                                        self.loadingPageIndicator.hidesWhenStopped = true
                                    }
                                    return
                                }
                            }
                        }
                        
                    }
                }
                

            } catch let error {
                print("Error:\(error.localizedDescription)")
            }
        }
    }
    
    func fetchAndUpdateData2() {
        
        // get the result of the requested page
        wkWebView2.evaluateJavaScript("document.documentElement.outerHTML.toString()") { (result, error) in
            
            self.html = result as? String
            
            // parsing
            do {
                let doc = try HTML(html: self.html, encoding: .utf8)
                for data in doc.xpath("//*[@id=\"tableData\"]//*[.=\"臺灣大學 (A0A01)\"]/../../td[4]") {
                    guard let rainfallString: String = data.text else {continue}
                        print(rainfallString)
                    if rainfallString == "-" {
                        self.rainfallLabel.text = "0.0"
                    } else if rainfallString == "X" {
                        
                        // if the data mearured at NTU site is not available, try to get the data at Daan forest Park
                        //
                        for data in doc.xpath("//*[@id=\"tableData\"]//*[.=\"大安森林 (CAAH6)\"]/../../td[4]") {
                            guard let rainfallString: String = data.text else {continue}
//                            print(rainfallString)
                            if rainfallString == "-" {
                                self.rainfallLabel.text = "0.0"
                            } else if rainfallString == "X" {
                                self.rainfallLabel.text = "Unknown"
                            } else {
                                self.rainfallLabel.text = rainfallString
                            }
                        }
                    } else {
                        self.rainfallLabel.text = rainfallString
                    }
                }

            } catch {/* error handling here */}
            self.isRainfallDataRetrieved = true
            if self.isTempHumidDataRetrieved {
                self.loadingPageIndicator.stopAnimating()
                self.loadingPageIndicator.hidesWhenStopped = true
            }
        }
    }
    // MARK: - helper functions
    
    func removeWKWebViewCookies() {
        
        //iOS9.0以上使用的方法
        if #available(iOS 9.0, *) {
            let dataStore = WKWebsiteDataStore.default()
            dataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), completionHandler: { (records) in
                for record in records{
                    //清除本站的cookie
                    if record.displayName.contains("sina.com"){//这个判断注释掉的话是清理所有的cookie
                        WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {
                            //清除成功
                            print("清除成功\(record)")
                        })
                    }
                }
            })
        } else {
            //ios8.0以上使用的方法
            let libraryPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.libraryDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first
            let cookiesPath = libraryPath! + "/Cookies"
            try!FileManager.default.removeItem(atPath: cookiesPath)
        }
    }
}

