//
//  HomeViewController.swift
//  swiftFrontEnd
//
//  Created by Mohammed Ali on 9/24/24.
//

import UIKit

class HomeViewController: UIViewController {

    @IBOutlet weak var usernameTextLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        if let username = UserSession.shared.username {
            usernameTextLabel.text = username
              }
        setupGradientBackground()
        addRandomCircles()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func logOutButtonPressed(_ sender: Any) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
           
        if let loginVC = storyboard.instantiateViewController(withIdentifier: "loginViewController") as? ViewController {
               loginVC.modalPresentationStyle = .fullScreen
               self.present(loginVC, animated: true, completion: nil)
           }
    }
    
    private func addRandomCircles() {
        let numberOfCircles = 8  // Number of random circles to generate
        let circleColor = UIColor.systemBlue.withAlphaComponent(0.5).cgColor
        
        for _ in 0..<numberOfCircles {
            let circleSize = CGFloat.random(in: 30...100)  // Random size for each circle
            let circleLayer = CAShapeLayer()
            let circlePath = UIBezierPath(
                ovalIn: CGRect(
                    x: CGFloat.random(in: 0...view.bounds.width - circleSize),
                    y: CGFloat.random(in: 0...view.bounds.height - circleSize),
                    width: circleSize,
                    height: circleSize
                )
            )
            
            circleLayer.path = circlePath.cgPath
            circleLayer.fillColor = circleColor
            view.layer.insertSublayer(circleLayer, at: 1) // Insert above the gradient layer
        }
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
