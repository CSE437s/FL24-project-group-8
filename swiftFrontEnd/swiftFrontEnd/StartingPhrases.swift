import AVKit
import UIKit
import CoreVideo

class StartingPhrases: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

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

    func clearInitialUI() {
        predictedCharacterLabel1.text = ""
        resultImageView1.image = UIImage(named: "hello")
        predictedCharacterLabel2.text = ""
        resultImageView2.image = UIImage(named: "thank")
        predictedCharacterLabel3.text = ""
        resultImageView3.image = UIImage(named: "nice")
    }

    @IBAction func captureVideoButtonTapped(_ sender: UIButton) {
        print(sender.tag)
        presentImagePicker(tag: sender.tag)
    }

    func presentImagePicker(tag: Int) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = false
        imagePickerController.mediaTypes = ["public.movie"] // Allow video selection
        imagePickerController.view.tag = tag

        let alert = UIAlertController(title: "Choose Video", message: "Select the source", preferredStyle: .actionSheet)
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

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let videoURL = info[.mediaURL] as? URL {
            picker.dismiss(animated: true) {
                let tag = picker.view.tag
                self.processSelectedVideo(url: videoURL, for: tag)
            }
        }
    }

    func processSelectedVideo(url: URL, for tag: Int) {
        let imageView = getImageView(for: tag)
        let label = getLabel(for: tag)

        imageView.image = UIImage(systemName: "hourglass")
        imageView.tintColor = .systemGray
        imageView.isHidden = false
        label.text = "Processing..."

        if let videoData = try? Data(contentsOf: url) {
            uploadMedia(videoData, for: tag)
            // Set a timeout to reset UI if no response is received within 10 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                if label.text == "Processing..." {  // Only reset if still processing
                    label.text = "Failed to get a response"
                    imageView.image = UIImage(systemName: "exclamationmark.circle.fill")
                    imageView.tintColor = .systemRed
                }
            }
        } else {
            showAlert("Error", message: "Failed to process video.")
        }
    }

    func uploadMedia(_ mediaData: Data, for tag: Int) {
        guard let url = URL(string: "http://127.0.0.1:8000/predict-phrase/") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let body = createMultipartBody(boundary: boundary, data: mediaData, mimeType: "video/mp4", filename: "video.mp4")
        request.httpBody = body

        let uploadTask = URLSession.shared.dataTask(with: request) { data, response, error in
            if error != nil {
                DispatchQueue.main.async {
                    self.showAlert("Error", message: "Failed to upload video")
                }
                return
            }

            if let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 {
                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String],
                       let predictedPhrase = jsonResponse["predicted_phrase"] {
                        DispatchQueue.main.async {
                            self.displayPrediction(predictedPhrase, for: tag)
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

    func displayPrediction(_ predictedPhrase: String, for tag: Int) {
//        let imageView = getImageView(for: tag)
//        let label = getLabel(for: tag)
//        label.text = "Predicted Phrase: \(predictedPhrase)"
//
//        imageView.image = UIImage(systemName: "checkmark.circle.fill")
//        imageView.tintColor = .systemGreen
//        imageView.isHidden = false
        let imageView = getImageView(for: tag)
        let label = getLabel(for: tag)
        label.text = "Your sign is: \(predictedPhrase)"

        if (predictedPhrase == "Hello" && tag == 1) || (predictedPhrase == "Thank You" && tag == 2) || (predictedPhrase == "Nice To Meet You" && tag == 3){
            imageView.image = UIImage(systemName: "checkmark.circle.fill")
            imageView.tintColor = .systemGreen
        } else {
            imageView.image = UIImage(systemName: "xmark.circle.fill")
            imageView.tintColor = .systemRed
        }
        imageView.isHidden = false
    }

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
        let formFieldName = "video"

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(formFieldName)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        return body
    }
}
