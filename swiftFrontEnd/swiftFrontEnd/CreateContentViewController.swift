//
//  CreateContentViewController.swift
//  swiftFrontEnd
//
//  Created by Mohammed Ali on 9/24/24.
//

//import AVKit
//import UIKit
//import CoreVideo
//
//
//class CreateContentViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
//    var selectedVideoURL: URL?
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        // Do any additional setup after loading the view.
//    }
//    @IBAction func captureVideoButtonTapped(_ sender: UIButton) {
//        presentMediaPicker(tag: 1)
//    }
//    @IBAction func createContentButtonTapped(_ sender: UIButton) {
//        uploadVideo(videoURL: URL, word: <#T##String#>)
//    }
//
//    func presentMediaPicker(tag: Int) {
//        let mediaPickerController = UIImagePickerController()
//        mediaPickerController.delegate = self
//        mediaPickerController.allowsEditing = false
//        mediaPickerController.view.tag = tag
//        mediaPickerController.mediaTypes = ["public.movie"] // Allows only video selection
//
//        let alert = UIAlertController(title: "Choose Video", message: "Select the source", preferredStyle: .actionSheet)
//        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
//            if UIImagePickerController.isSourceTypeAvailable(.camera) {
//                mediaPickerController.sourceType = .camera
//                mediaPickerController.cameraCaptureMode = .video // Set to capture video
//                self.present(mediaPickerController, animated: true)
//            } else {
//                self.showAlert("Error", message: "Camera is not available.")
//            }
//        }))
//        alert.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
//            mediaPickerController.sourceType = .photoLibrary
//            self.present(mediaPickerController, animated: true)
//        }))
//        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
//
//        present(alert, animated: true)
//    }
//
//    func showAlert(_ title: String, message: String) {
//        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "OK", style: .default))
//        self.present(alert, animated: true)
//    }
//    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//            if let videoURL = info[.mediaURL] as? URL {
//                // This is the URL where the video is temporarily stored
//                print("Video URL: \(videoURL)")
//                
//                // You can now use the URL to play, upload, or save the video
//                saveVideoToDocumentsDirectory(videoURL)
//            }
//            
//            picker.dismiss(animated: true)
//        }
//        
//        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
//            picker.dismiss(animated: true)
//        }
//        
//        func saveVideoToDocumentsDirectory(_ videoURL: URL) {
//            let fileManager = FileManager.default
//            let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
//            let destinationURL = documentsDirectory.appendingPathComponent(videoURL.lastPathComponent)
//            
//            do {
//                if fileManager.fileExists(atPath: destinationURL.path) {
//                    try fileManager.removeItem(at: destinationURL) // Remove if file already exists
//                }
//                try fileManager.copyItem(at: videoURL, to: destinationURL)
//                print("Video saved to Documents directory: \(destinationURL)")
//            } catch {
//                print("Error saving video: \(error)")
//            }
//        }
//    }
//    func uploadVideo(videoURL: URL, word: String) {
//        let word = "test"
//        let url = URL(string: "http://127.0.0.1:8000/upload-video/")!
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        
//        let boundary = UUID().uuidString
//        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
//        
//        let videoData = try? Data(contentsOf: videoURL)
//        guard let videoData = videoData else {
//            print("Could not retrieve video data.")
//            return
//        }
//        
//        // Create the multipart form data
//        var body = Data()
//        
//        // Add the 'word' parameter
//        body.append("--\(boundary)\r\n".data(using: .utf8)!)
//        body.append("Content-Disposition: form-data; name=\"word\"\r\n\r\n".data(using: .utf8)!)
//        body.append("\(word)\r\n".data(using: .utf8)!)
//        
//        // Add the video file parameter
//        let filename = "daily_video.mov"
//        let mimetype = "video/quicktime"
//        
//        body.append("--\(boundary)\r\n".data(using: .utf8)!)
//        body.append("Content-Disposition: form-data; name=\"video\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
//        body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: .utf8)!)
//        body.append(videoData)
//        body.append("\r\n".data(using: .utf8)!)
//        
//        // End the multipart form data
//        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
//        
//        request.httpBody = body
//        
//        // Create and start the upload task
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//            if let error = error {
//                print("Upload error: \(error)")
//                return
//            }
//            
//            if let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) {
//                print("Video uploaded successfully.")
//            } else {
//                print("Server error or invalid response.")
//            }
//        }
//        
//        task.resume()
//    }

import AVKit
import UIKit
import CoreVideo

class CreateContentViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var selectedVideoURL: URL? // Store the selected video URL
    @IBOutlet weak var text: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func captureVideoButtonTapped(_ sender: UIButton) {
        presentMediaPicker(tag: 1)
    }
    
    @IBAction func createContentButtonTapped(_ sender: UIButton) {
        guard let videoURL = selectedVideoURL else {
            showAlert("Error", message: "No video selected.")
            return
        }
        
        // Get the text from the UITextField
        let word = text.text ?? "" // Default to an empty string if nil
        
        uploadVideo(videoURL: videoURL, word: word) { response, error in
            DispatchQueue.main.async {
                if let error = error {
                    // Show an alert with the error message
                    self.showAlert("Upload Failed", message: error)
                } else if let response = response {
                    // Show a success alert with the server response
                    self.showAlert("Success", message: response)
                }
            }
        }
    }
    
    func presentMediaPicker(tag: Int) {
        let mediaPickerController = UIImagePickerController()
        mediaPickerController.delegate = self
        mediaPickerController.allowsEditing = false
        mediaPickerController.view.tag = tag
        mediaPickerController.mediaTypes = ["public.movie"] // Allows only video selection

        let alert = UIAlertController(title: "Choose Video", message: "Select the source", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                mediaPickerController.sourceType = .camera
                mediaPickerController.cameraCaptureMode = .video // Set to capture video
                self.present(mediaPickerController, animated: true)
            } else {
                self.showAlert("Error", message: "Camera is not available.")
            }
        }))
        alert.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
            mediaPickerController.sourceType = .photoLibrary
            self.present(mediaPickerController, animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alert, animated: true)
    }

    func showAlert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let videoURL = info[.mediaURL] as? URL {
            print("Video URL: \(videoURL)")
            selectedVideoURL = videoURL // Store the video URL for later use
        }
        
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func uploadVideo(videoURL: URL, word: String, completion: @escaping (String?, String?) -> Void) {
        guard let username = UserSession.shared.username else {
            completion(nil, "Username not found in UserSession.")
            return
        }
        
        let url = URL(string: "http://127.0.0.1:8000/upload-video-to-folder/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let videoData = try? Data(contentsOf: videoURL)
        guard let videoData = videoData else {
            print("Could not retrieve video data.")
            return
        }
        
        // Create the multipart form data
        var body = Data()
        
        // Add the 'name' parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"name\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(username)\r\n".data(using: .utf8)!)
        
        // Add the 'word' parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"word\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(word)\r\n".data(using: .utf8)!)
        
        // Add the video file parameter
        let filename = videoURL.lastPathComponent
        let mimetype = "video/quicktime"
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"video\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: .utf8)!)
        body.append(videoData)
        body.append("\r\n".data(using: .utf8)!)
        
        // End the multipart form data
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        // Create and start the upload task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Upload error: \(error)")
                return
            }
            
            if let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) {
                print("Video uploaded successfully.")
                self.increaseUserPoints()
                
            } else {
                print("Server error or invalid response.")
            }
        }
        
        task.resume()
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

