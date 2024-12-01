import UIKit
import AVKit
import AVFoundation



class GetFolders: UIViewController {
    
    private var folders: [String] = [] // Stores folder names
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        title = "Folders"
        
        setupScrollView()
        setupStackView()
        fetchFolders()
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupStackView() {
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
    }
    
    
    private func fetchFolders() {
        guard let url = URL(string: "http://localhost:8000/get-all-folders/") else {
            showError("Invalid URL")
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.showError(error.localizedDescription)
                    return
                }
                guard let data = data else {
                    self.showError("No data received")
                    return
                }

                do {
                    // Decode the JSON object with a "folders" key
                    let jsonResponse = try JSONDecoder().decode([String: [String]].self, from: data)
                    self.folders = jsonResponse["folders"] ?? []
                    self.createFolderButtons()
                } catch {
                    self.showError("Failed to decode response: \(error.localizedDescription)")
                }
            }
        }
        task.resume()
    }

    
    private func createFolderButtons() {
        for folder in folders {
            let button = UIButton(type: .system)
            button.setTitle(folder, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
            button.backgroundColor = .systemBlue
            button.setTitleColor(.white, for: .normal)
            button.layer.cornerRadius = 8
            button.heightAnchor.constraint(equalToConstant: 44).isActive = true
            button.addTarget(self, action: #selector(folderButtonTapped(_:)), for: .touchUpInside)
            button.tag = folders.firstIndex(of: folder) ?? 0
            stackView.addArrangedSubview(button)
        }
    }
    
    @objc private func folderButtonTapped(_ sender: UIButton) {
        let folderName = folders[sender.tag]
        let videoVC = GetVideos(folderName: folderName)
        navigationController?.pushViewController(videoVC, animated: true)
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true)
    }
}

class GetVideos: UIViewController {
    
    private let folderName: String
    private var videos: [String] = [] // Stores video names
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    
    init(folderName: String) {
        self.folderName = folderName
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        title = folderName
        
        setupScrollView()
        setupStackView()
        fetchVideos()
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupStackView() {
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
    }
    
    @objc private func videoButtonTapped(_ sender: UIButton) {
        guard let videoName = sender.titleLabel?.text else {
            showError("Video name is missing")
            return
        }

        let videoURLString = "http://127.0.0.1:8000/static/\(folderName)/\(videoName)"
        guard let videoURL = URL(string: videoURLString) else {
            showError("Invalid video URL")
            return
        }

        print("Video URL: \(videoURL)")

        let player = AVPlayer(url: videoURL)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePlaybackError(_:)),
            name: .AVPlayerItemFailedToPlayToEndTime,
            object: nil
        )

        let playerItem = player.currentItem
        playerItem?.addObserver(self, forKeyPath: "status", options: [.new, .initial], context: nil)

        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        present(playerViewController, animated: true) {
            player.play()
        }
    }

    @objc private func handlePlaybackError(_ notification: Notification) {
        if let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? NSError {
            print("Playback failed with error: \(error.localizedDescription)")
        } else {
            print("Playback failed with an unknown error.")
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            if let playerItem = change?[.newKey] as? AVPlayerItem {
                switch playerItem.status {
                case .readyToPlay:
                    print("AVPlayerItem is ready to play.")
                case .failed:
                    print("AVPlayerItem failed: \(String(describing: playerItem.error?.localizedDescription))")
                case .unknown:
                    print("AVPlayerItem status is unknown.")
                @unknown default:
                    break
                }
            }
        }
    }

    
    private func fetchVideos() {
        let urlString = "http://localhost:8000/get-videos-from-folder/\(folderName)/"
        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else {
            showError("Invalid URL")
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.showError(error.localizedDescription)
                    return
                }
                guard let data = data else {
                    self.showError("No data received")
                    return
                }

                do {
                    // Decode the JSON object with a "videos" key
                    let jsonResponse = try JSONDecoder().decode([String: [String]].self, from: data)
                    self.videos = jsonResponse["videos"] ?? []
                    self.createVideoButtons()
                } catch {
                    self.showError("Failed to decode response: \(error.localizedDescription)")
                }
            }
        }
        task.resume()
    }
    
    private func createVideoButtons() {
        for video in videos {
            let button = UIButton(type: .system)
            button.setTitle(video, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
            button.backgroundColor = .systemGreen
            button.setTitleColor(.white, for: .normal)
            button.layer.cornerRadius = 8
            button.heightAnchor.constraint(equalToConstant: 44).isActive = true
            button.addTarget(self, action: #selector(videoButtonTapped(_:)), for: .touchUpInside)
            stackView.addArrangedSubview(button)
        }
    }

    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true)
    }
}
