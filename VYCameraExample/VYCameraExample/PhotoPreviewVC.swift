//
//  PhotoPreviewVC.swift
//  VYCameraExample
//
//  Created by Vladyslav Yakovlev on 11/10/18.
//  Copyright © 2018 Vladyslav Yakovlev. All rights reserved.
//

import UIKit

final class PhotoPreviewVC: UIViewController {
    
    var photo: UIImage!
    
    private let photoView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
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
        view.addSubview(photoView)
        view.addSubview(closeButton)
        
        photoView.image = photo
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
    }
    
    private func layoutViews() {
        photoView.frame = view.bounds
        closeButton.frame.origin = CGPoint(x: 14, y: 14)
    }
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
}
