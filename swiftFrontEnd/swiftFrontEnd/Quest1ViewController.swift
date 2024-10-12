//
//  Quest1ViewController.swift
//  swiftFrontEnd
//
//  Created by Mohammed Ali on 9/24/24.
//

import AVKit
import UIKit
import CoreVideo

class Quest1ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func capturePhotoButtonTapped(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.sourceType = .camera
            imagePickerController.cameraCaptureMode = .photo
            imagePickerController.allowsEditing = false
            
            self.present(imagePickerController, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Error", message: "Camera is not available.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true, completion: nil)
        }
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            picker.dismiss(animated: true) {
                // Convert UIImage to a format that can be processed by OpenCV
                if let imageData = image.jpegData(compressionQuality: 1.0) {
                    // Pass the image data to the model inference function
                    self.runInferenceOnImageData(imageData)
                }
            }
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func runInferenceOnImageData(_ imageData: Data) {
        // Convert imageData to a format that can be processed by OpenCV
        let image = UIImage(data: imageData)
        guard let cvImage = image?.toCVPixelBuffer() else { return }
        
        // Use your existing Python code logic here to process `cvImage` with OpenCV and MediaPipe.
        // Perform the hand detection and extract features using MediaPipe.
        // Predict the character using your pre-trained model.
        
        let predictedCharacter = "A" // Replace with actual model output
        
        // Display the result to the user
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Prediction", message: "The model predicts: \(predictedCharacter)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true, completion: nil)
        }
    }
}

// Extension to convert UIImage to CVPixelBuffer
extension UIImage {
    func toCVPixelBuffer() -> CVPixelBuffer? {
        let width = Int(self.size.width)
        let height = Int(self.size.height)
        
        var pixelBuffer: CVPixelBuffer?
        let attributes: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
        
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         width,
                                         height,
                                         kCVPixelFormatType_32ARGB,
                                         attributes as CFDictionary,
                                         &pixelBuffer)
        
        guard status == kCVReturnSuccess, let unwrappedPixelBuffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(unwrappedPixelBuffer, .readOnly)
        let pixelData = CVPixelBufferGetBaseAddress(unwrappedPixelBuffer)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: pixelData,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(unwrappedPixelBuffer),
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
            CVPixelBufferUnlockBaseAddress(unwrappedPixelBuffer, .readOnly)
            return nil
        }
        
        guard let cgImage = self.cgImage else {
            CVPixelBufferUnlockBaseAddress(unwrappedPixelBuffer, .readOnly)
            return nil
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        CVPixelBufferUnlockBaseAddress(unwrappedPixelBuffer, .readOnly)
        
        return unwrappedPixelBuffer
    }
}
