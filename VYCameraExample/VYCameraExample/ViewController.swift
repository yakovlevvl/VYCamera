//
//  ViewController.swift
//  VYCameraExample
//
//  Created by Vladyslav Yakovlev on 11/8/18.
//  Copyright © 2018 Vladyslav Yakovlev. All rights reserved.
//

import VYCamera

final class ViewController: UIViewController {
    
    private let camera = VYCamera()
    
    private let openButton: UIButton = {
        let button = UIButton(type: .custom)
        button.frame.size = CGSize(width: 216, height: 80)
        button.setTitle("Open Camera", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel!.font = UIFont(name: "AvenirNext-Bold", size: 21)
        button.layer.cornerRadius = button.frame.height/2
        button.layer.shadowPath = UIBezierPath(roundedRect: button.bounds, cornerRadius: button.layer.cornerRadius).cgPath
        button.layer.shadowColor = UIColor.gray.cgColor
        button.layer.shadowOpacity = 0.14
        button.layer.shadowRadius = 12
        button.layer.shadowOffset = .zero
        button.backgroundColor = .white
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        view.addSubview(openButton)
        
        camera.delegate = self
        
        openButton.center = view.center
        openButton.addTarget(self, action: #selector(openCamera), for: .touchUpInside)
    }
    
    @objc private func openCamera() {
        present(camera, animated: true)
    }
    
    private func showPhotoPreview(_ photo: UIImage) {
        let previewVC = PhotoPreviewVC()
        previewVC.photo = photo
        camera.present(previewVC, animated: true)
    }
    
    private func showVideoPreview(_ videoUrl: URL) {
        let previewVC = VideoPreviewVC()
        previewVC.videoUrl = videoUrl
        camera.present(previewVC, animated: true)
    }
}

extension ViewController: VYCameraDelegate {
    
    func didTake(photo: UIImage, error: Error?) {
        if error == nil {
            showPhotoPreview(photo)
        }
    }
    
    func didFinishVideoRecordingTo(fileURL: URL, error: Error?) {
        if error == nil {
            showVideoPreview(fileURL)
        }
    }
    
    func didCloseByUser() {
        print("didCloseByUser")
    }
}

