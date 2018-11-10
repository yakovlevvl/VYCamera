//
//  CaptureButton.swift
//  VYCamera
//
//  Created by Vladyslav Yakovlev on 11/8/18.
//  Copyright © 2018 Vladyslav Yakovlev. All rights reserved.
//

import UIKit

protocol CaptureButtonDelegate: class {
    
    func captureButtonTapped()
    
    func captureButtonPressed()
    
    func captureButtonUnpressed()
}

final class CaptureButton: UIView {
    
    var borderColor = UIColor.white {
        didSet {
            layer.borderColor = borderColor.cgColor
        }
    }
    
    var borderWidth: CGFloat = 5.0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    
    var progressLineColor = UIColor.red
    
    var progressLineWidth: CGFloat = 5.0
    
    var videoCaptureDuration: CFTimeInterval = 60
    
    weak var delegate: CaptureButtonDelegate?
    
    override var frame: CGRect {
        didSet {
            layoutViews()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    private func setupViews() {
        backgroundColor = .clear
        
        layer.borderColor = borderColor.cgColor
        layer.borderWidth = borderWidth
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapRecognized(_:))))
        addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(longPressRecognized(_:))))
    }
    
    private func layoutViews() {
        layer.cornerRadius = frame.height/2
    }
    
    @objc private func tapRecognized(_ gesture: UITapGestureRecognizer) {
        delegate?.captureButtonTapped()
    }
    
    @objc private func longPressRecognized(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began :

            let circleLayer = CAShapeLayer()
            let value = frame.width/2
            circleLayer.path = UIBezierPath(arcCenter: CGPoint(x: value, y: value), radius: value + 2, startAngle: CGFloat(-Double.pi/2.0), endAngle: CGFloat(3*Double.pi/2.0), clockwise: true).cgPath
            circleLayer.fillColor = UIColor.clear.cgColor
            circleLayer.strokeColor = progressLineColor.cgColor
            circleLayer.lineWidth = progressLineWidth
            circleLayer.strokeEnd = 0
            layer.addSublayer(circleLayer)
            
            UIView.animate(0.3, animation: {
                self.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            }, completion: { _ in
                let animation = CABasicAnimation(keyPath: "strokeEnd")
                animation.duration = self.videoCaptureDuration
                animation.fromValue = 0
                animation.toValue = 1
                circleLayer.strokeEnd = 1
                animation.delegate = self
                circleLayer.add(animation, forKey: "")
            })
            
            delegate?.captureButtonPressed()
            
        case .ended :
            
            if let layer = layer.sublayers?.last {
                layer.removeFromSuperlayer()
            }
            
        default : break
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CaptureButton: CAAnimationDelegate {
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        delegate?.captureButtonUnpressed()
        if let layer = layer.sublayers?.last {
            layer.removeFromSuperlayer()
        }
        UIView.animate(0.3) {
            self.transform = .identity
        }
    }
}
