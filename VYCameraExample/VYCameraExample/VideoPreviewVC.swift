//
//  VideoPreviewVC.swift
//  VYCameraExample
//
//  Created by Vladyslav Yakovlev on 11/10/18.
//  Copyright © 2018 Vladyslav Yakovlev. All rights reserved.
//

import UIKit
import AVFoundation

final class VideoPreviewVC: UIViewController {
    
    var videoUrl: URL!
    
    private var playerLayer: AVPlayerLayer!
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.frame.size = CGSize(width: 50, height: 50)
        button.setImage(UIImage(named: "CloseIcon"), for: .normal)
        button.contentMode = .center
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        layoutViews()
    }
    
    private func setupViews() {
        let videoPlayer = AVPlayer(url: videoUrl)
        playerLayer = AVPlayerLayer(player: videoPlayer)
        view.layer.addSublayer(playerLayer)
        videoPlayer.play()
        
        view.addSubview(closeButton)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
    }
    
    private func layoutViews() {
        playerLayer.frame = view.bounds
        closeButton.frame.origin = CGPoint(x: 14, y: 14)
    }
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
}
