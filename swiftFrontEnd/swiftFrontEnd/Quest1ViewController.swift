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

    override func viewDidLoad() {
        super.viewDidLoad()
        clearInitialUI()
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
        } else {
            imageView.image = UIImage(systemName: "xmark.circle.fill")
            imageView.tintColor = .systemRed
        }
        imageView.isHidden = false
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

