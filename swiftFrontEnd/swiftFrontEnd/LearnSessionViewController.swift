//
//  LearnSessionViewController.swift
//  swiftFrontEnd
//
//  Created by Mohammed Ali on 9/24/24.
//

import UIKit
import WebKit

class LearnSessionViewController: UIViewController {

    
    @IBOutlet weak var scrollView: UIScrollView!
    
    private var webViews: [WKWebView] = []
    private var descriptionLabels: [UILabel] = []
    private var actionButtons: [UIButton] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebViews()
        layoutUIElements()
    }
    
    private func setupWebViews() {
        let videoIds = ["0FcwzMq4iWg", "4Ll3OtqAzyw", "bFv_mLwBvHc"] // Add more video IDs here

        for videoId in videoIds {
            let webView = WKWebView()
            webView.translatesAutoresizingMaskIntoConstraints = false
            loadYoutubeVideo(webView: webView, videoId: videoId)
            webViews.append(webView)
            scrollView.addSubview(webView)

            // Setup the description label for each video
            let descriptionLabel = UILabel()
            descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
            descriptionLabel.text = "Description for video \(videoId)"
            descriptionLabel.numberOfLines = 0 // Allow multiple lines
            scrollView.addSubview(descriptionLabel)
            descriptionLabels.append(descriptionLabel)

            // Setup the action button for each video
            let actionButton = UIButton(type: .system)
            actionButton.translatesAutoresizingMaskIntoConstraints = false
            actionButton.setTitle("Mark as Watched", for: .normal) // Change title here
            actionButton.tag = webViews.count - 1 // Set tag to identify the button
            actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
            scrollView.addSubview(actionButton)
            actionButtons.append(actionButton)
        }
    }
    
    private func layoutUIElements() {
        let webViewHeight: CGFloat = 200
        let descriptionHeight: CGFloat = 50
        let buttonHeight: CGFloat = 40
        let spacing: CGFloat = 15
        
        for index in 0..<webViews.count {
            let webView = webViews[index]
            let descriptionLabel = descriptionLabels[index]
            let actionButton = actionButtons[index]
            
            // Set constraints for web views
            NSLayoutConstraint.activate([
                webView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: CGFloat(index) * (webViewHeight + descriptionHeight + buttonHeight + spacing * 3) + spacing),
                webView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
                webView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
                webView.heightAnchor.constraint(equalToConstant: webViewHeight)
            ])
            
            // Set constraints for description labels
            NSLayoutConstraint.activate([
                descriptionLabel.topAnchor.constraint(equalTo: webView.bottomAnchor, constant: spacing),
                descriptionLabel.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: spacing),
                descriptionLabel.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -spacing),
                descriptionLabel.heightAnchor.constraint(equalToConstant: descriptionHeight)
            ])
            
            // Set constraints for action buttons
            NSLayoutConstraint.activate([
                actionButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: spacing),
                actionButton.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
                actionButton.heightAnchor.constraint(equalToConstant: buttonHeight)
            ])
        }
        
        // Update the last button's bottom constraint to scroll view bottom
        if let lastButton = actionButtons.last {
            NSLayoutConstraint.activate([
                lastButton.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -spacing)
            ])
        }
    }
    
    private func loadYoutubeVideo(webView: WKWebView, videoId: String) {
        let videoURL = "https://www.youtube.com/embed/\(videoId)"
        if let url = URL(string: videoURL) {
            let request = URLRequest(url: url)
            webView.load(request)
        } else {
            print("Invalid URL")
        }
    }
    
    @objc private func actionButtonTapped(sender: UIButton) {
        let videoIndex = sender.tag // Get the index from the button's tag
               let videoId = ["0FcwzMq4iWg", "4Ll3OtqAzyw", "bFv_mLwBvHc"][videoIndex]

               // Change button title to "Done"
               sender.setTitle("Done", for: .normal)
               
               // Show alert to confirm action
               let alert = UIAlertController(title: "Video Watched", message: "You have marked video \(videoId) as watched.", preferredStyle: .alert)
               alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
               present(alert, animated: true, completion: nil)
        increaseUserPoints()
    }
    
    
    func increaseUserPoints() {
        // Step 1: Fetch the current points of the user
        getCurrentPoints { [weak self] currentPoints, error in
            // Handle errors if the points could not be fetched
            if let error = error {
                print("Error fetching points: \(error)")
                return
            }
            
            // Ensure currentPoints is available
            guard let currentPoints = currentPoints else {
                print("Failed to fetch current points.")
                return
            }
            
            // Step 2: Increase the points by 1
            let newPoints = currentPoints + 1
            
            // Step 3: Update the points on the backend
            self?.updatePoints(currentPoints: newPoints) { success, message in
                if success {
                    // Successfully updated points
                    print("Success: \(message ?? "")")
                } else {
                    // Error updating points
                    print("Error updating points: \(message ?? "")")
                }
            }
        }
    }


    
    func getCurrentPoints(completion: @escaping (Int?, String?) -> Void) {
        guard let username = UserSession.shared.username else {
            completion(nil, "Username not found in UserSession.")
            return
        }
        
        let urlString = "http://127.0.0.1:8000/user/get-points/?username=\(username)"
        guard let url = URL(string: urlString) else {
            completion(nil, "Invalid URL.")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(nil, "Request failed with error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                completion(nil, "No data received.")
                return
            }
            
            do {
                if let responseJson = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let points = responseJson["points"] as? Int {
                    completion(points, nil)  // Successfully retrieved points
                } else {
                    completion(nil, "Invalid response format.")
                }
            } catch {
                completion(nil, "Failed to parse response data.")
            }
        }
        
        task.resume()
    }

    
    
    func updatePoints(currentPoints: Int, completion: @escaping (Bool, String?) -> Void) {
        guard let username = UserSession.shared.username else {
            completion(false, "Username not found in UserSession.")
            return
        }
        
        let urlString = "http://127.0.0.1:8000/user/update-points/"
        guard let url = URL(string: urlString) else {
            completion(false, "Invalid URL.")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "username": username,
            "points": currentPoints  // Send updated points value
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
            request.httpBody = jsonData
        } catch {
            completion(false, "Failed to serialize request body.")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false, "Request failed with error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                completion(false, "No data received.")
                return
            }
            
            do {
                if let responseJson = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let message = responseJson["message"] as? String {
                    if message == "Points updated successfully." {
                        completion(true, "Points updated successfully.")
                    } else {
                        completion(false, "Failed to update points.")
                    }
                } else {
                    completion(false, "Invalid response format.")
                }
            } catch {
                completion(false, "Failed to parse response data.")
            }
        }
        
        task.resume()
    }

}

    
    
    
//    @IBOutlet weak var secondVideo: WKWebView!
//    @IBOutlet weak var firstVideo: WKWebView!
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        loadYoutubeVideo()
//        loadSecondYoutubeVideo()
//
//        // Do any additional setup after loading the view.
//    }
//    
//    func loadYoutubeVideo() {
//           let videoURL = "https://www.youtube.com/embed/0FcwzMq4iWg"
//           if let url = URL(string: videoURL) {
//               let request = URLRequest(url: url)
//               firstVideo.load(request) // Load the URL in the WKWebView
//           } else {
//               print("Invalid URL")
//           }
//       }
//    
//    func loadSecondYoutubeVideo() {
//           let videoURL = "https://www.youtube.com/embed/4Ll3OtqAzyw"
//           if let url = URL(string: videoURL) {
//               let request = URLRequest(url: url)
//               secondVideo.load(request) // Load the URL in the WKWebView
//           } else {
//               print("Invalid URL")
//           }
//       }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */


