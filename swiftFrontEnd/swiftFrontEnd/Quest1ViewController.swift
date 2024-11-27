import AVKit
import UIKit
import CoreVideo

class Quest1ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // Outlets for the first letter
    @IBOutlet weak var predictedCharacterLabel1: UILabel!
    @IBOutlet weak var resultImageView1: UIImageView!
    
    // Outlets for the second letter
    @IBOutlet weak var predictedCharacterLabel2: UILabel!
    @IBOutlet weak var resultImageView2: UIImageView!
    
    // Outlets for the third letter
    @IBOutlet weak var predictedCharacterLabel3: UILabel!
    @IBOutlet weak var resultImageView3: UIImageView!
    
    @IBOutlet weak var capturePhotoButton1: UIButton! // Sign B!
    @IBOutlet weak var capturePhotoButton2: UIButton! // Sign A!
    @IBOutlet weak var capturePhotoButton3: UIButton! // Sign L!

    override func viewDidLoad() {
        super.viewDidLoad()
        clearInitialUI()
        setupButtonAppearance(button: capturePhotoButton1, iconName: "camera")
            setupButtonAppearance(button: capturePhotoButton2, iconName: "camera")
            setupButtonAppearance(button: capturePhotoButton3, iconName: "camera")
        setupGradientBackground()
        setupLabelAppearance(label: predictedCharacterLabel1)
            setupLabelAppearance(label: predictedCharacterLabel2)
            setupLabelAppearance(label: predictedCharacterLabel3)
        setupImageViewAppearance(imageView: resultImageView1)
            setupImageViewAppearance(imageView: resultImageView2)
            setupImageViewAppearance(imageView: resultImageView3)
    }
    
    private func setupImageViewAppearance(imageView: UIImageView) {
        imageView.layer.cornerRadius = 10
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor.systemGray.cgColor
        imageView.clipsToBounds = true
    }
    
    private func setupLabelAppearance(label: UILabel) {
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .darkGray
    }
    
    private func setupGradientBackground() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.systemBlue.withAlphaComponent(0.3).cgColor,
            UIColor.systemTeal.withAlphaComponent(0.1).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.frame = view.bounds
        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    func clearInitialUI() {
        // Clear text and hide images initially
        predictedCharacterLabel1.text = ""
        resultImageView1.image = UIImage(named: "b1") // Set initial placeholder
        predictedCharacterLabel2.text = ""
        resultImageView2.image = UIImage(named: "a1")
        predictedCharacterLabel3.text = ""
        resultImageView3.image = UIImage(named: "l1")
    }

    // Button actions for each upload
    @IBAction func capturePhotoButtonTapped1(_ sender: UIButton) {
        presentImagePicker(tag: 1)
    }

    @IBAction func capturePhotoButtonTapped2(_ sender: UIButton) {
        presentImagePicker(tag: 2)
    }

    @IBAction func capturePhotoButtonTapped3(_ sender: UIButton) {
        presentImagePicker(tag: 3)
    }
    
    private func setupButtonAppearance(button: UIButton, iconName: String) {
        let icon = UIImage(systemName: iconName)
        button.setImage(icon, for: .normal)
        
        button.imageView?.contentMode = .scaleAspectFit
        button.tintColor = .systemBlue
        button.setTitleColor(.systemBlue, for: .normal)
        
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemBlue.cgColor
        button.clipsToBounds = true
    }

    // Present image picker and assign the tag to track which button called it
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

    // Handle the image selection
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let image = info[.originalImage] as? UIImage {
            picker.dismiss(animated: true) {
                let tag = picker.view.tag
                self.processSelectedImage(image, for: tag)
            }
        }
    }

    func processSelectedImage(_ image: UIImage, for tag: Int) {
        let imageView = getImageView(for: tag)
        let label = getLabel(for: tag)

        // Display a placeholder image and processing message
        imageView.image = UIImage(systemName: "hourglass")
        imageView.tintColor = .systemGray
        imageView.isHidden = false
        label.text = "Processing..."

        // Convert image to JPEG and upload it
        if let imageData = image.jpegData(compressionQuality: 1.0) {
            uploadImage(imageData, for: tag)
        }
    }

    func uploadImage(_ imageData: Data, for tag: Int) {
        guard let url = URL(string: "http://127.0.0.1:8000/predict-letter/") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let body = createMultipartBody(boundary: boundary, data: imageData, mimeType: "image/jpeg", filename: "image.jpg")
        request.httpBody = body

        let uploadTask = URLSession.shared.dataTask(with: request) { data, response, error in
            if error != nil {
                DispatchQueue.main.async {
                    self.showAlert("Error", message: "Failed to upload image")
                }
                return
            }

            if let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 {
                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String],
                       let predictedCharacter = jsonResponse["predicted_character"] {
                        DispatchQueue.main.async {
                            self.displayPrediction(predictedCharacter, for: tag)
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.showAlert("Error", message: "Failed to parse response")
                    }
                }
            }
        }

        uploadTask.resume()
    }

    // Show prediction result in the appropriate UI elements
    func displayPrediction(_ predictedCharacter: String, for tag: Int) {
        let imageView = getImageView(for: tag)
        let label = getLabel(for: tag)
        label.text = "Your sign is: \(predictedCharacter)"

        if (predictedCharacter == "B" && tag == 1) || (predictedCharacter == "A" && tag == 2) || (predictedCharacter == "L" && tag == 3){
            imageView.image = UIImage(systemName: "checkmark.circle.fill")
            imageView.tintColor = .systemGreen
            increaseUserPoints()
        } else {
            imageView.image = UIImage(systemName: "xmark.circle.fill")
            imageView.tintColor = .systemRed
        }
        imageView.isHidden = false
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



    // Helper functions to get the correct image view and label based on tag
    func getImageView(for tag: Int) -> UIImageView {
        return tag == 1 ? resultImageView1 : tag == 2 ? resultImageView2 : resultImageView3
    }

    func getLabel(for tag: Int) -> UILabel {
        return tag == 1 ? predictedCharacterLabel1 : tag == 2 ? predictedCharacterLabel2 : predictedCharacterLabel3
    }

    func showAlert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }
    
    func createMultipartBody(boundary: String, data: Data, mimeType: String, filename: String) -> Data {
        var body = Data()

        let formFieldName = "image" // Adjust form field name as per API requirements

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(formFieldName)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        return body
    }

}

