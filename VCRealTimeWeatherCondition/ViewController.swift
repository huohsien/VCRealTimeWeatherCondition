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
        wkWebView2 = WKWebView(frame: CGRect(x: 0.0, y: view.bounds.size.height * (1.0 - webViewRatio), width: view.bounds.size.width, height: view.bounds.size.height * webViewRatio))
        wkWebView2.navigationDelegate = self
        wkWebView2.alpha = 0.0
        self.view.addSubview(wkWebView2)
        guard let url2 = URL(string: Constants.baseUrl2) else {
            print("failed to create url")
            return
        }
        let urlRequest2 = URLRequest(url: url2)
        wkWebView2.load(urlRequest2)
        loadingPageIndicator.startAnimating()
    }
    
    //MARK: - webkit callbacks
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        if webView == wkWebView {
            print("callback didFinish from wkWebView")
            fetchAndUpdateData()
        } else if webView == wkWebView2 {
            print("callback didFinish from wkWebView2")
            fetchAndUpdateData2()
        }
    }
    
    //MARK: - html parser
    
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
    
    func fetchAndUpdateData2() {
        
        // get the result of the requested page
        wkWebView2.evaluateJavaScript("document.documentElement.outerHTML.toString()") { (result, error) in
            
            self.html = result as? String
            
            // parsing
            do {
                let doc = try HTML(html: self.html, encoding: .utf8)
                for data in doc.xpath("//*[@id=\"tableData\"]//*[.=\"臺灣大學 (A0A01)\"]/../../td[3]") {
                    guard let rainfallString: String = data.text else {continue}
                        print(rainfallString)
                    if rainfallString == "-" {
                        self.rainfallLabel.text = "0.0"
                    } else if rainfallString == "X" {
                        
                        // if the data mearured at NTU site is not available, try to get the data at Daan forest Park
                        //
                        for data in doc.xpath("//*[@id=\"tableData\"]//*[.=\"大安森林 (CAAH6)\"]/../../td[3]") {
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

