////
////  TranslateInputViewController.swift
////  swiftFrontEnd
////
////  Created by Mohammed Ali on 9/24/24.
////
//
//import UIKit
//import AVKit
//
//class TranslateInputViewController: UIViewController {
//    
//    var videoNameWithoutExtension: String?
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        fetchVideoName()
//        // Do any additional setup after loading the view.
//    }
//    
//    @IBAction func getContent(_ sender: UIButton) {
//        downloadVideo()
//    }
//    @IBAction func testKnowledgeTapped(_ sender: UIButton) {
//        presentImagePicker(tag: 1)
//    }
//    
//
//    func downloadVideo() {
//            let url = URL(string: "http://127.0.0.1:8000/daily-video/")!
//            let destinationURL = FileManager.default.temporaryDirectory.appendingPathComponent("video1.mov")
//            
//            var request = URLRequest(url: url)
//            request.httpMethod = "POST"
//            
//            let task = URLSession.shared.downloadTask(with: request) { localURL, response, error in
//                if let error = error {
//                    print("Download error: \(error)")
//                    return
//                }
//                
//                guard let localURL = localURL else {
//                    print("No file URL received.")
//                    return
//                }
//                
//                do {
//                    // Remove file if it exists
//                    if FileManager.default.fileExists(atPath: destinationURL.path) {
//                        try FileManager.default.removeItem(at: destinationURL)
//                    }
//                    
//                    // Move downloaded file to destination
//                    try FileManager.default.moveItem(at: localURL, to: destinationURL)
//                    print("Video downloaded to \(destinationURL)")
//                    
//                    // Display the downloaded video
//                    DispatchQueue.main.async {
//                        self.playVideo(at: destinationURL)
//                    }
//                    
//                } catch {
//                    print("File error: \(error)")
//                }
//            }
//            
//            task.resume()
//        }
//        
//        func playVideo(at url: URL) {
//            let player = AVPlayer(url: url)
//            let playerViewController = AVPlayerViewController()
//            playerViewController.player = player
//            
//            present(playerViewController, animated: true) {
//                player.play()
//            }
//        }
//    func fetchVideoName() {
//            let url = URL(string: "http://127.0.0.1:8000/get-video-name/")!
//            
//            var request = URLRequest(url: url)
//            request.httpMethod = "GET"
//            
//            let task = URLSession.shared.dataTask(with: request) { data, response, error in
//                if let error = error {
//                    print("Error fetching video name: \(error)")
//                    return
//                }
//                
//                guard let data = data else {
//                    print("No data received.")
//                    return
//                }
//                
//                do {
//                    // Decode JSON response
//                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String],
//                       let videoName = json["video_name"] {
//                        
//                        // Remove the .MOV extension
//                        self.videoNameWithoutExtension = videoName.replacingOccurrences(of: ".MOV", with: "")
//                        print("Video name without extension: \(self.videoNameWithoutExtension ?? "")")
//                        
//                        // Do something with videoNameWithoutExtension if needed
//                    }
//                } catch {
//                    print("JSON decoding error: \(error)")
//                }
//            }
//            task.resume()
//        }
//    }
//    
//        
//        
//    
//
//
//  TranslateInputViewController.swift
//  swiftFrontEnd
//
//  Created by Mohammed Ali on 9/24/24.
//

import UIKit
import AVKit

class TranslateInputViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var videoNameWithoutExtension: String?
    var selectedImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchVideoName()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func getContent(_ sender: UIButton) {
        downloadVideo()
    }
    
    @IBAction func testKnowledgeTapped(_ sender: UIButton) {
        presentImagePicker(tag: 1)
    }
    
    func downloadVideo() {
        let url = URL(string: "http://127.0.0.1:8000/daily-video/")!
        let destinationURL = FileManager.default.temporaryDirectory.appendingPathComponent("video1.mov")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let task = URLSession.shared.downloadTask(with: request) { localURL, response, error in
            if let error = error {
                print("Download error: \(error)")
                return
            }
            
            guard let localURL = localURL else {
                print("No file URL received.")
                return
            }
            
            do {
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                
                try FileManager.default.moveItem(at: localURL, to: destinationURL)
                print("Video downloaded to \(destinationURL)")
                
                DispatchQueue.main.async {
                    self.playVideo(at: destinationURL)
                }
                
            } catch {
                print("File error: \(error)")
            }
        }
        
        task.resume()
    }
    
    func playVideo(at url: URL) {
        let player = AVPlayer(url: url)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        
        present(playerViewController, animated: true) {
            player.play()
        }
    }
    
    func fetchVideoName() {
        let url = URL(string: "http://127.0.0.1:8000/get-video-name/")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching video name: \(error)")
                return
            }
            
            guard let data = data else {
                print("No data received.")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String],
                   let videoName = json["video_name"] {
                    
                    self.videoNameWithoutExtension = videoName.replacingOccurrences(of: ".MOV", with: "")
                    print("Video name without extension: \(self.videoNameWithoutExtension ?? "")")
                    
                }
            } catch {
                print("JSON decoding error: \(error)")
            }
        }
        print(self.videoNameWithoutExtension)
        task.resume()
    }
    
    func presentImagePicker(tag: Int) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = false
        imagePickerController.view.tag = tag
        
        let alert = UIAlertController(title: "Choose Image", message: "Select the source", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                imagePickerController.sourceType = .camera
                self.present(imagePickerController, animated: true)
            } else {
                self.showAlert("Error", message: "Camera is not available.")
            }
        }))
        alert.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
            imagePickerController.sourceType = .photoLibrary
            self.present(imagePickerController, animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            selectedImage = image
            print("Image selected.")
            uploadImageForPrediction()
        }
        picker.dismiss(animated: true)
    }
    
    func uploadImageForPrediction() {
        guard let selectedImage = selectedImage else {
            showAlert("Error", message: "No image selected.")
            return
        }
        
        let url = URL(string: "http://127.0.0.1:8000/predict-letter/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        guard let imageData = selectedImage.jpegData(compressionQuality: 0.8) else {
            print("Failed to convert image to data.")
            return
        }
        
        var body = Data()
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Upload error: \(error)")
                return
            }
            
            guard let data = data else {
                print("No data received.")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String],
                   let predictedCharacter = json["predicted_character"] {
                    
                    DispatchQueue.main.async {
                        if predictedCharacter.lowercased() == self.videoNameWithoutExtension?.lowercased() {
                            self.showAlert("Success", message: "The predicted character matches the video name.")
                        } else {
                            self.showAlert("Try Again", message: "The predicted character does not match the video name.")
                        }
                    }
                }
            } catch {
                print("JSON decoding error: \(error)")
            }
        }
        
        task.resume()
    }

    
    func showAlert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }
}
