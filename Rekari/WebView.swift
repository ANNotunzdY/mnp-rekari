//
//  WebView.swift
//  Rekari
//
//  Created by development on 2024/06/15.
//

import SwiftUI

import WebKit

var latestUrl: String? = nil

struct WebView: NSViewRepresentable {
    let url: String
    let webView = WKWebView()
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        if url != latestUrl, let urlObj = URL(string: url) {
            latestUrl = url
            let request = URLRequest(url: urlObj)
            nsView.load(request)
        }
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
         var parent: WebView

         init(_ parent: WebView) {
             self.parent = parent
         }
         
         func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
             DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                 let script = """
                         (function() {
                             var items = [];
                             var listItems = document.querySelectorAll('li > a');
                             listItems.forEach(function(item) {
                                 var h2 = item.querySelector('h2');
                                 items.push({
                                     url: item.href,
                                     title: h2 ? h2.innerText : ''
                                 });
                             });
                             return items;
                         })();
                         """
                 webView.evaluateJavaScript(script) { (result, error) in
                     if let error = error {
                         print("JavaScript error: \(error)")
                     }
                     if let links = result as? [[String: String]] {
                         var videos = [[String]]()
                         
                         for item in links {
                             if let url = item["url"], let title = item["title"], url.hasPrefix("https://www.nicovideo.jp/watch_tmp/") {
                                 let id = String(url.dropFirst("https://www.nicovideo.jp/watch_tmp/".count))
                                 videos.append([id, title])
                             }
                         }
                         
                         // JSONに変換
                         guard let jsonData = try? JSONSerialization.data(withJSONObject: videos, options: []) else {
                             print("Error: Could not convert videos to JSON")
                             return
                         }

                         // URLを設定
                         let url = URL(string: "https://g4bvjgz8cj.execute-api.ap-northeast-1.amazonaws.com/Prod/add")!
                         var request = URLRequest(url: url)
                         request.httpMethod = "POST"
                         request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                         request.httpBody = jsonData

                         // POSTリクエストを送信
                         let task = URLSession.shared.dataTask(with: request) { data, response, error in
                             if let error = error {
                                 print("Error: \(error)")
                                 return
                             }
                             
                             guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                                 print("Error: Invalid response")
                                 return
                             }
                             
                             if let data = data, let responseString = String(data: data, encoding: .utf8) {
                                 // print("Response: \(responseString)")
                             }
                         }

                         task.resume()
                     }
                 }
             }
         }
     }
}
