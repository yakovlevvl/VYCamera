//
//  VYCamera.swift
//  VYCamera
//
//  Created by Vladyslav Yakovlev on 11/8/18.
//  Copyright © 2018 Vladyslav Yakovlev. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices

extension VYCamera {
    
    private enum FlashMode {
        case on
        case off
        case auto
    }
    
    public enum ButtonAlignment {
        case left
        case right
        case center
    }
}

public protocol VYCameraDelegate: class {
    
    func camera(_ camera: VYCamera, didTake photo: UIImage, error: Error?)
    
    func camera(_ camera: VYCamera, didFinishVideoRecordingTo fileURL: URL, error: Error?)
    
    func camera(_ camera: VYCamera, didTakeWithImagePicker photo: UIImage, error: Error?)
    
    func camera(_ camera: VYCamera, didTakeWithImagePicker videoUrl: URL, error: Error?)
    
    func didCloseByUser()
}

public extension VYCameraDelegate {
    
    func camera(_ camera: VYCamera, didFinishVideoRecordingTo fileURL: URL, error: Error?) {}
    
    func camera(_ camera: VYCamera, didTakeWithImagePicker photo: UIImage, error: Error?) {}
    
    func camera(_ camera: VYCamera, didTakeWithImagePicker videoUrl: URL, error: Error?) {}
    
    func didCloseByUser() {}
}

public final class VYCamera: UIViewController {
    
    public weak var delegate: VYCameraDelegate?
    
    private let captureSession = AVCaptureSession()
    
    private let photoOutput = AVCapturePhotoOutput()
    
    private let videoOutput = AVCaptureMovieFileOutput()
    
    private var previewLayer: AVCaptureVideoPreviewLayer!
    
    private var captureDevice: AVCaptureDevice!
    
    private var prevZoomFactor: CGFloat = 1
    
    
    public var captureButtonColor = UIColor.white
    
    public var videoRecordingProgressColor = UIColor.red
    
    public var videoRecordingDuration: CFTimeInterval = 60
    
    public var closeButtonAlignment: ButtonAlignment = .left
    
    public var allowVideoRecording = true
    
    public var allowImagePicker = false
    
    
    public var closeButtonImage: UIImage? {
        didSet {
            closeButton.setImage(closeButtonImage ?? Images.closeIcon)
        }
    }
    
    public var switchButtonImage: UIImage? {
        didSet {
            switchButton.setImage(switchButtonImage ?? Images.switchCameraIcon)
        }
    }
    
    public var flashOnButtonImage: UIImage? {
        didSet {
            if flashMode == .on {
                flashButton.setImage(flashOnButtonImage ?? Images.flashOnIcon)
            }
        }
    }
    
    public var flashOffButtonImage: UIImage? {
        didSet {
            if flashMode == .off {
                flashButton.setImage(flashOffButtonImage ?? Images.flashOffIcon)
            }
        }
    }
    
    public var flashAutoButtonImage: UIImage? {
        didSet {
            if flashMode == .auto {
                flashButton.setImage(flashAutoButtonImage ?? Images.flashAutoIcon)
            }
        }
    }
    
    private var flashMode = FlashMode.off {
        didSet {
            switch flashMode {
            case .on : flashButton.setImage(flashOnButtonImage ?? Images.flashOnIcon)
            case .off : flashButton.setImage(flashOffButtonImage ?? Images.flashOffIcon)
            case .auto : flashButton.setImage(flashAutoButtonImage ?? Images.flashAutoIcon)
            }
        }
    }

    private let closeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.frame.size = CGSize(width: 50, height: 50)
        button.setImage(Images.closeIcon)
        button.contentMode = .center
        return button
    }()
    
    private let flashButton: UIButton = {
        let button = UIButton(type: .custom)
        button.frame.size = CGSize(width: 60, height: 60)
        button.setImage(Images.flashOffIcon)
        button.contentMode = .center
        return button
    }()
    
    private let switchButton: UIButton = {
        let button = UIButton(type: .custom)
        button.frame.size = CGSize(width: 60, height: 60)
        button.setImage(Images.switchCameraIcon)
        button.contentMode = .center
        return button
    }()
    
    private let captureButton: CaptureButton = {
        let button = CaptureButton()
        button.frame.size = CGSize(width: 76, height: 76)
        return button
    }()
    
    private lazy var pickerButton: UIButton = {
        let button = UIButton(type: .custom)
        button.frame.size = CGSize(width: 50, height: 50)
        button.setImage(Images.pickerIcon)
        button.contentMode = .center
        button.tintColor = .white
        return button
    }()
    
    public init() {
        super.init(nibName: nil, bundle: nil)
        setupCamera()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        layoutViews()
    }
    
    private func setupCamera() {
        guard let videoInput = try? AVCaptureDeviceInput(device: AVCaptureDevice.default(for: AVMediaType.video)!), let audioInput = try? AVCaptureDeviceInput(device: AVCaptureDevice.default(for: AVMediaType.audio)!) else { return }
        
        captureSession.addInput(videoInput)
        captureSession.addInput(audioInput)
        captureSession.addOutput(photoOutput)
        captureSession.addOutput(videoOutput)
        captureDevice = videoInput.device
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        captureSession.startRunning()
        flashMode = .off
    }
    
    private func setupViews() {
        view.addSubview(closeButton)
        view.addSubview(flashButton)
        view.addSubview(switchButton)
        view.addSubview(captureButton)
        
        if allowImagePicker {
            view.addSubview(pickerButton)
        }

        view.layer.insertSublayer(previewLayer, at: 0)
        
        captureButton.delegate = self
        captureButton.allowVideoRecording = allowVideoRecording
        captureButton.borderColor = captureButtonColor
        captureButton.progressLineColor = videoRecordingProgressColor
        captureButton.videoCaptureDuration = videoRecordingDuration
        
        closeButton.addTarget(self, action: #selector(closeCamera), for: .touchUpInside)
        flashButton.addTarget(self, action: #selector(toggleFlash), for: .touchUpInside)
        switchButton.addTarget(self, action: #selector(switchCamera), for: .touchUpInside)
        
        if allowImagePicker {
            pickerButton.addTarget(self, action: #selector(pickerButtonTapped), for: .touchUpInside)
        }
        
        let focusGesture = UITapGestureRecognizer(target: self, action: #selector(focus(tap:)))
        focusGesture.delegate = self
        view.addGestureRecognizer(focusGesture)
        let zoomGesture = UIPinchGestureRecognizer(target: self, action: #selector(zoom(pinch:)))
        zoomGesture.delegate = self
        view.addGestureRecognizer(zoomGesture)
    }
    
    private func layoutViews() {
        switch closeButtonAlignment {
        case .left :
            closeButton.frame.origin.x = currentDevice == .iPhoneX ? 16 : 14
            if allowImagePicker {
                pickerButton.frame.origin.x = view.frame.width - pickerButton.frame.width - (currentDevice == .iPhoneX ? 16 : 14)
            }
        case .right :
            closeButton.frame.origin.x = view.frame.width - closeButton.frame.width - (currentDevice == .iPhoneX ? 16 : 14)
            if allowImagePicker {
                pickerButton.frame.origin.x = currentDevice == .iPhoneX ? 16 : 14
            }
        case .center :
            closeButton.center.x = view.center.x
            if allowImagePicker {
                pickerButton.frame.origin.x = currentDevice == .iPhoneX ? 16 : 14
            }
        }
        closeButton.frame.origin.y = currentDevice == .iPhoneX ? 40 : 14
        pickerButton.frame.origin.y = currentDevice == .iPhoneX ? 40 : 14
        
        captureButton.center.x = view.center.x
        let captureButtonInset: CGFloat = currentDevice == .iPhoneX ? 36 : 24
        captureButton.frame.origin.y = view.frame.height - captureButton.frame.height - captureButtonInset
        
        flashButton.center.x = (view.center.x - captureButton.frame.width/2)/2
        flashButton.center.y = captureButton.center.y
        
        switchButton.center.x = view.frame.width - flashButton.center.x
        switchButton.center.y = captureButton.center.y
        
        previewLayer.frame = view.bounds
    }
    
    @objc private func pickerButtonTapped() {
        let pickerVC = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            pickerVC.sourceType = .photoLibrary
            if allowVideoRecording {
                pickerVC.mediaTypes.append(kUTTypeMovie as String)
                pickerVC.videoMaximumDuration = videoRecordingDuration
            }
            pickerVC.delegate = self
            present(pickerVC, animated: true)
        }
    }
    
    @objc private func closeCamera() {
        dismiss(animated: true)
        delegate?.didCloseByUser()
    }
}

extension VYCamera {
    
    private func takePhoto() {
        let settings = AVCapturePhotoSettings()
        if !flashButton.isHidden {
            switch flashMode {
            case .off : settings.flashMode = .off
            case .on : settings.flashMode = .on
            case .auto : settings.flashMode = .auto
            }
        }
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    private func startVideoRecording() {
        let url = URL(fileURLWithPath: NSTemporaryDirectory() + "recordedVideo.mov")
        videoOutput.startRecording(to: url, recordingDelegate: self)
    }
    
    private func stopVideoRecording() {
        videoOutput.stopRecording()
    }
}

extension VYCamera {
    
    @objc private func switchCamera() {
        UIView.animate(0.24) {
            self.switchButton.transform = self.switchButton.transform.rotated(by: -(CGFloat.pi * 0.999))
        }
        
        captureDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: captureDevice.position == .back ? .front : .back).devices.first!
        
        captureSession.beginConfiguration()
        captureSession.removeInput((captureSession.inputs as! [AVCaptureDeviceInput]).filter{$0.device.hasMediaType(AVMediaType.video)}.first!)
        try! captureSession.addInput(AVCaptureDeviceInput(device: captureDevice))
        captureSession.commitConfiguration()
        
        flashButton.isHidden = !(photoOutput.supportedFlashModes.count > 1)
    }
    
    @objc private func toggleFlash() {
        if photoOutput.supportedFlashModes.count > 1 {
            switch flashMode {
            case .off : flashMode = .on
            case .on : flashMode = .auto
            case .auto : flashMode = .off
            }
        }
    }
}

extension VYCamera {
    
    @objc private func zoom(pinch: UIPinchGestureRecognizer) {
        try! captureDevice.lockForConfiguration()
        switch pinch.state {
        case .began : prevZoomFactor = captureDevice.videoZoomFactor
        case .changed : captureDevice.videoZoomFactor = max(1, min(prevZoomFactor * pinch.scale, captureDevice.activeFormat.videoMaxZoomFactor))
        default : break
        }
        captureDevice.unlockForConfiguration()
    }
    
    @objc private func focus(tap: UIGestureRecognizer) {
        guard captureDevice.isExposurePointOfInterestSupported else { return }
        
        let tapPoint = tap.location(in: view)
        let interestPoint = previewLayer.captureDevicePointConverted(fromLayerPoint: tapPoint)
        
        showFocus(at: tapPoint)
        
        try! captureDevice.lockForConfiguration()
        
        if captureDevice.isFocusPointOfInterestSupported {
            captureDevice.focusPointOfInterest = interestPoint
            captureDevice.focusMode = .continuousAutoFocus
        }
        
        captureDevice.exposurePointOfInterest = interestPoint
        captureDevice.exposureMode = .continuousAutoExposure
        captureDevice.unlockForConfiguration()
    }
    
    private func showFocus(at point: CGPoint) {
        let focus = UIView()
        focus.frame.size = CGSize(width: 78, height: 78)
        focus.layer.cornerRadius = focus.frame.height/2
        focus.backgroundColor = .clear
        focus.layer.borderColor = UIColor.white.cgColor
        focus.layer.borderWidth = 2
        focus.center = point
        focus.tag = 1
        if view.subviews.last!.tag == 1 {
            view.subviews.last!.removeFromSuperview()
        }
        view.addSubview(focus)
        
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(0.3)
        focus.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        UIView.setAnimationDelay(1)
        focus.layer.opacity = 0
        UIView.commitAnimations()
    }
}

extension VYCamera: AVCapturePhotoCaptureDelegate {
    
    public func photoOutput(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        if let buffer = photoSampleBuffer {
            let photo = UIImage(data: AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: buffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer)!)!
            delegate?.camera(self, didTake: photo, error: error)
        }
    }
}

extension VYCamera: AVCaptureFileOutputRecordingDelegate {
    
    public func fileOutput(_ captureOutput: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        delegate?.camera(self, didFinishVideoRecordingTo: outputFileURL, error: error)
    }
}

extension VYCamera: CaptureButtonDelegate {
    
    func captureButtonTapped() {
        takePhoto()
    }
    
    func captureButtonPressed() {
        startVideoRecording()
        UIView.animate(0.3) {
            self.flashButton.alpha = 0
            self.switchButton.alpha = 0
            self.closeButton.alpha = 0
            self.pickerButton.alpha = 0
        }
    }
    
    func captureButtonUnpressed() {
        stopVideoRecording()
        UIView.animate(0.3) {
            self.flashButton.alpha = 1
            self.switchButton.alpha = 1
            self.closeButton.alpha = 1
            self.pickerButton.alpha = 1
        }
    }
}

extension VYCamera: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            delegate?.camera(self, didTakeWithImagePicker: image, error: nil)
        } else if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            delegate?.camera(self, didTakeWithImagePicker: image, error: nil)
        } else if let videoUrl = info[UIImagePickerController.InfoKey.mediaURL] as? URL {
            delegate?.camera(self, didTakeWithImagePicker: videoUrl, error: nil)
        }
    }
}

extension VYCamera: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == gestureRecognizer.view
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
