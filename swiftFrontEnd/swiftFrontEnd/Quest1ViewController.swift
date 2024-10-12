import AVKit
import UIKit
import CoreVideo

class Quest1ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var predictedCharacterLabel: UILabel!

    @IBOutlet weak var resultImageView: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        predictedCharacterLabel.text = "" // Initially clear
        resultImageView.isHidden = true // Hide the result image initially
    }

    @IBAction func capturePhotoButtonTapped(_ sender: UIButton) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = false

        let alert = UIAlertController(title: "Choose Image", message: "Select the source", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                imagePickerController.sourceType = .camera
                self.present(imagePickerController, animated: true, completion: nil)
            } else {
                self.showAlert("Error", message: "Camera is not available.")
            }
        }))
        alert.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
            imagePickerController.sourceType = .photoLibrary
            self.present(imagePickerController, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alert, animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            picker.dismiss(animated: true) {
                if let imageData = image.jpegData(compressionQuality: 1.0) {
                    self.uploadImage(imageData)
                }
            }
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    func uploadImage(_ imageData: Data) {
        guard let url = URL(string: "http://127.0.0.1:8000/predict-letter/") else {
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let body = createMultipartBody(boundary: boundary, data: imageData, mimeType: "image/jpeg", filename: "image.jpg")
        request.httpBody = body

        let uploadTask = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.showAlert("Error", message: "Failed to upload image")
                }
                return
            }

            if let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 {
                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String],
                       let predictedCharacter = jsonResponse["predicted_character"] {
                        
                        // Update UI on the main thread
                        DispatchQueue.main.async {
                            self.displayPrediction(predictedCharacter)
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

    func displayPrediction(_ predictedCharacter: String) {
        // Display the predicted character in the label
        self.predictedCharacterLabel.text = "Your sign is: \(predictedCharacter)"
        
        // Show check mark for "B", red X for anything else
        if predictedCharacter == "B" {
            self.resultImageView.image = UIImage(systemName: "checkmark.circle.fill") // Green checkmark icon
            self.resultImageView.tintColor = .systemGreen
        } else {
            self.resultImageView.image = UIImage(systemName: "xmark.circle.fill") // Red X icon
            self.resultImageView.tintColor = .systemRed
        }
        self.resultImageView.isHidden = false // Show the result image
    }

    func showAlert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true, completion: nil)
    }
}
