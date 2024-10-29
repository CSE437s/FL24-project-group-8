//
//  LearnSessionViewController.swift
//  swiftFrontEnd
//
//  Created by Mohammed Ali on 9/24/24.
//

import UIKit
import WebKit

class LearnSessionViewController: UIViewController {

    @IBOutlet weak var secondVideo: WKWebView!
    @IBOutlet weak var firstVideo: WKWebView!
    override func viewDidLoad() {
        super.viewDidLoad()
        loadYoutubeVideo()
        loadSecondYoutubeVideo()

        // Do any additional setup after loading the view.
    }
    
    func loadYoutubeVideo() {
           let videoURL = "https://www.youtube.com/embed/0FcwzMq4iWg"
           if let url = URL(string: videoURL) {
               let request = URLRequest(url: url)
               firstVideo.load(request) // Load the URL in the WKWebView
           } else {
               print("Invalid URL")
           }
       }
    
    func loadSecondYoutubeVideo() {
           let videoURL = "https://www.youtube.com/embed/4Ll3OtqAzyw"
           if let url = URL(string: videoURL) {
               let request = URLRequest(url: url)
               secondVideo.load(request) // Load the URL in the WKWebView
           } else {
               print("Invalid URL")
           }
       }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
