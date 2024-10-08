//
//  CameraView.swift
//  ReactNativeCameraKit
//

import AVFoundation
import UIKit

/*
 * View abtracting the logic unrelated to the actual camera
 * Like permission, ratio overlay, focus, zoom gesture, write image, etc
 */
@objc(CKCameraView)
class CameraView: UIView {
    private let camera: CameraProtocol

    // Focus
    private let focusInterfaceView: FocusInterfaceView

    // scanner
    private var lastBarcodeDetectedTime: TimeInterval = 0
    private var scannerInterfaceView: ScannerInterfaceView
    private var supportedBarcodeType: [AVMetadataObject.ObjectType] = [.upce, .code39, .code39Mod43, .ean13, .ean8, .code93, .code128, .pdf417, .qr, .aztec, .dataMatrix, .interleaved2of5]
//    private var supportedBarcodeType: [AVMetadataObject.ObjectType] = [.upce, .ean13, .ean8]
    
    // camera
    private var ratioOverlayView: RatioOverlayView?

    // gestures
    private var zoomGestureRecognizer: UIPinchGestureRecognizer?

    // props
    // camera settings
    @objc var cameraType: CameraType = .back
    @objc var flashMode: FlashMode = .auto
    @objc var torchMode: TorchMode = .off
    // ratio overlay
    @objc var ratioOverlay: String?
    @objc var ratioOverlayColor: UIColor?
    // scanner
    @objc var scannerPosition: String?
    @objc var scanBarcode = false
    @objc var showFrame = false
    @objc var initBarCodeTypes: NSArray?
    @objc var onReadCode: RCTDirectEventBlock?
    @objc var onCameraShow: RCTDirectEventBlock?
    @objc var scanThrottleDelay = 2000
    @objc var frameColor: UIColor?
    @objc var laserColor: UIColor?
    // other
    @objc var onOrientationChange: RCTDirectEventBlock?
    @objc var onZoom: RCTDirectEventBlock?
    @objc var resetFocusTimeout = 0
    @objc var resetFocusWhenMotionDetected = false
    @objc var focusMode: FocusMode = .on
    @objc var zoomMode: ZoomMode = .on
    @objc var zoom: NSNumber?
    @objc var maxZoom: NSNumber?

    // MARK: - Setup

    // This is used to delay camera setup until we have both granted permission & received default props
    var hasCameraBeenSetup = false
    var hasPropBeenSetup = false {
        didSet {
            setupCamera()
        }
    }
    var hasPermissionBeenGranted = false {
        didSet {
            setupCamera()
        }
    }

    private func setupCamera() {
        if (hasPropBeenSetup && hasPermissionBeenGranted && !hasCameraBeenSetup) {
            hasCameraBeenSetup = true
            
            // let isValid = initBarCodeTypes!.contains(convertBarCodeEnumToString(barcodeType: .ean8));
            
            let filteredQRTypes = initBarCodeTypes != nil ? supportedBarcodeType.filter { type in initBarCodeTypes!.contains(convertBarCodeEnumToString(barcodeType: type)) }: supportedBarcodeType
//            let filteredTypes = supportedBarcodeType.filter { type in availableTypes.contains(type) }
            camera.setup(cameraType: cameraType, supportedBarcodeType: scanBarcode || onReadCode != nil ? filteredQRTypes : [])

        }
    }

    // MARK: Lifecycle

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
#if targetEnvironment(simulator)
        camera = SimulatorCamera()
#else
        camera = RealCamera()
#endif

        scannerInterfaceView = ScannerInterfaceView(frameColor: .white, laserColor: .red)
        focusInterfaceView = FocusInterfaceView()

        super.init(frame: frame)

        // Transfer the default values, otherwise the default wont take effect since it's a separate class
        focusInterfaceView.update(focusMode: focusMode)
        focusInterfaceView.update(resetFocusTimeout: resetFocusTimeout)
        focusInterfaceView.update(resetFocusWhenMotionDetected: resetFocusWhenMotionDetected)
        update(zoomMode: zoomMode)

        addSubview(camera.previewView)

        addSubview(scannerInterfaceView)
        scannerInterfaceView.isHidden = true

        addSubview(focusInterfaceView)
        focusInterfaceView.delegate = camera

        handleCameraPermission()
    }

    override func removeFromSuperview() {
        camera.cameraRemovedFromSuperview()

        super.removeFromSuperview()
    }

    // MARK: React lifecycle

    override func reactSetFrame(_ frame: CGRect) {
        super.reactSetFrame(frame)

        camera.previewView.frame = bounds

        scannerInterfaceView.frame = bounds
        // If frame size changes, we have to update the scanner
        if(showFrame) {
            updateFrameOffset()
        } else {
            camera.update(scannerFrameSize: nil)
        }

        focusInterfaceView.frame = bounds

        ratioOverlayView?.frame = bounds

        camera.update(onShowCallback: self.onInitCamera)

    }

    override func removeReactSubview(_ subview: UIView) {
        subview.removeFromSuperview()
        super.removeReactSubview(subview)
    }

    // Called once when all props have been set, then every time one is updated
    override func didSetProps(_ changedProps: [String]) {
        hasPropBeenSetup = true
        
        // Camera settings
        if changedProps.contains("cameraType") {
            camera.update(cameraType: cameraType)
        }
        
        if(changedProps.contains("scannerPosition")) {
            if(showFrame) {
                updateFrameOffset()
            } else {
                self.camera.update(scannerFrameSize: nil)
            }
        }
        
        if changedProps.contains("flashMode") {
            camera.update(flashMode: flashMode)
        }
        if changedProps.contains("cameraType") || changedProps.contains("torchMode") {
            camera.update(torchMode: torchMode)
        }
        
        if changedProps.contains("onOrientationChange") {
            camera.update(onOrientationChange: onOrientationChange)
        }
        
        if changedProps.contains("onZoom") {
            camera.update(onZoom: onZoom)
        }

        // Ratio overlay
        if changedProps.contains("ratioOverlay") {
            if let ratioOverlay {
                if let ratioOverlayView {
                    ratioOverlayView.setRatio(ratioOverlay)
                } else {
                    ratioOverlayView = RatioOverlayView(frame: bounds, ratioString: ratioOverlay, overlayColor: ratioOverlayColor)
                    addSubview(ratioOverlayView!)
                }
            } else {
                ratioOverlayView?.removeFromSuperview()
                ratioOverlayView = nil
            }
        }

        if changedProps.contains("ratioOverlayColor"), let ratioOverlayColor {
            ratioOverlayView?.setColor(ratioOverlayColor)
        }

        // Scanner
        if changedProps.contains("scanBarcode") || changedProps.contains("onReadCode") {
            let filteredQRTypes = initBarCodeTypes != nil ? supportedBarcodeType.filter { type in initBarCodeTypes!.contains(convertBarCodeEnumToString(barcodeType: type)) }: supportedBarcodeType
            
            camera.isBarcodeScannerEnabled(scanBarcode,
                                           supportedBarcodeType: filteredQRTypes,
                                           onBarcodeRead: { [weak self] barcode in self?.onBarcodeRead(barcode: barcode) })
        }

        if changedProps.contains("showFrame") || changedProps.contains("scanBarcode") {
            DispatchQueue.main.async {
                self.scannerInterfaceView.isHidden = !self.showFrame
                if(self.showFrame) {
                    self.updateFrameOffset();
                } else {
                    self.camera.update(scannerFrameSize: nil)
                }
            }
        }

        if changedProps.contains("laserColor"), let laserColor {
            scannerInterfaceView.update(laserColor: laserColor)
        }

        if changedProps.contains("frameColor"), let frameColor {
            scannerInterfaceView.update(frameColor: frameColor)
        }

        // Others
        if changedProps.contains("focusMode") {
            focusInterfaceView.update(focusMode: focusMode)
        }
        if changedProps.contains("resetFocusTimeout") {
            focusInterfaceView.update(resetFocusTimeout: resetFocusTimeout)
        }
        if changedProps.contains("resetFocusWhenMotionDetected") {
            focusInterfaceView.update(resetFocusWhenMotionDetected: resetFocusWhenMotionDetected)
        }

        if changedProps.contains("zoomMode") {
            self.update(zoomMode: zoomMode)
        }
        
        if changedProps.contains("zoom") {
            camera.update(zoom: zoom?.doubleValue)
        }
        
        if changedProps.contains("maxZoom") {
            camera.update(maxZoom: maxZoom?.doubleValue)
        }
    }

    // MARK: Public

    func capture(_ options: [String: Any],
                 onSuccess: @escaping (_ imageObject: [String: Any]) -> (),
                 onError: @escaping (_ error: String) -> ()) {
        camera.capturePicture(onWillCapture: { [weak self] in
            // Flash/dim preview to indicate shutter action
            DispatchQueue.main.async {
                self?.camera.previewView.alpha = 0
                UIView.animate(withDuration: 0.35, animations: {
                    self?.camera.previewView.alpha = 1
                })
            }
        }, onSuccess: { [weak self] imageData, thumbnailData in
            DispatchQueue.global(qos: .default).async {
                self?.writeCaptured(imageData: imageData, thumbnailData: thumbnailData, onSuccess: onSuccess, onError: onError)

                self?.focusInterfaceView.resetFocus()
            }
        }, onError: onError)
    }
    
    // MARK: - Private Helper

    private func update(zoomMode: ZoomMode) {
        if zoomMode == .on {
            if (zoomGestureRecognizer == nil) {
                let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchToZoomRecognizer(_:)))
                addGestureRecognizer(pinchGesture)
                zoomGestureRecognizer = pinchGesture
            }
        } else {
            if let zoomGestureRecognizer {
                removeGestureRecognizer(zoomGestureRecognizer)
                self.zoomGestureRecognizer = nil
            }
        }
    }
    
    private func handleCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // The user has previously granted access to the camera.
            hasPermissionBeenGranted = true
            break
        case .notDetermined:
            // The user has not yet been presented with the option to grant video access.
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.hasPermissionBeenGranted = true
                }
            }
        default:
            // The user has previously denied access.
            break
        }
    }
    
    private func convertBarCodeEnumToString(barcodeType: AVMetadataObject.ObjectType) -> String {
        var stringValue: String = "";

        switch(barcodeType) {
            case .upce:
                stringValue = "upce"
            case .code39:
                stringValue = "code39"
            case .code39Mod43:
                stringValue = "code39Mod43"
            case .ean13:
                stringValue = "ean13"
            case .ean8:
                stringValue = "ean8"
            case .ean8:
                stringValue = "ean8"
            case .code93:
                stringValue = "code93"
            case .code128:
                stringValue = "code128"
            case .pdf417:
                stringValue = "pdf417"
            case .qr:
                stringValue = "qr"
            case .aztec:
                stringValue = "aztec"
            case .dataMatrix:
                stringValue = "dataMatrix"
            case .interleaved2of5:
                stringValue = "interleaved2of5"
        default:
            stringValue = ""
        }
        
        return stringValue
        
    }
    private func writeCaptured(imageData: Data,
                               thumbnailData: Data?,
                               onSuccess: @escaping (_ imageObject: [String: Any]) -> (),
                               onError: @escaping (_ error: String) -> ()) {
        do {
            let temporaryImageFileURL = try saveToTmpFolder(imageData)
            
            onSuccess([
                "size": imageData.count,
                "uri": temporaryImageFileURL.description,
                "name": temporaryImageFileURL.lastPathComponent,
                "thumb": ""
            ])
        } catch {
            let errorMessage = "Error occurred while writing image data to a temporary file: \(error)"
            print(errorMessage)
            onError(errorMessage)
        }
    }

    private func saveToTmpFolder(_ data: Data) throws -> URL {
        let temporaryFileName = ProcessInfo.processInfo.globallyUniqueString
        // Store temporary photos in the 'caches' directory to support expo-file-system
        let cachesUrl = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        var temporaryFolderURL = cachesUrl
        if let bundleId = Bundle.main.bundleIdentifier {
            temporaryFolderURL = temporaryFolderURL.appendingPathComponent(bundleId, isDirectory: true)
        }
        temporaryFolderURL = temporaryFolderURL.appendingPathComponent("com.tesla.react-native-camera-kit", isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryFolderURL, withIntermediateDirectories: true)
        let temporaryFileURL = temporaryFolderURL.appendingPathComponent("\(temporaryFileName).jpg")

        try data.write(to: temporaryFileURL, options: .atomic)

        return temporaryFileURL
    }

    private func onBarcodeRead(barcode: String) {
        // Throttle barcode detection
        let now = Date.timeIntervalSinceReferenceDate
        guard lastBarcodeDetectedTime + Double(scanThrottleDelay) / 1000 < now else {
            return
        }

        lastBarcodeDetectedTime = now

        onReadCode?(["codeStringValue": barcode])
    }
    
    private func updateFrameOffset() {
        if self.scannerPosition == "center" && self.showFrame {
            let centerFrame = self.scannerInterfaceView.frameSize
            print("center")
            camera.update(scannerFrameSize: centerFrame);
        } else if self.scannerPosition == "top" && self.showFrame {
            let centerFrame = self.scannerInterfaceView.frameSize
            print("top", centerFrame)
            let topFrame = CGRect(x: centerFrame.origin.x, y: centerFrame.origin.y / 2, width: centerFrame.size.width, height: centerFrame.size.height)
            print("after top: ", topFrame)
            camera.update(scannerFrameSize: topFrame);
        }
    }
        
    private func onInitCamera() {
        onCameraShow?(["isInit": true])
    }

    // MARK: - Gesture selectors

    @objc func handlePinchToZoomRecognizer(_ pinchRecognizer: UIPinchGestureRecognizer) {
        if pinchRecognizer.state == .began {
            camera.zoomPinchStart()
        }
        if pinchRecognizer.state == .changed {
            camera.zoomPinchChange(pinchScale: pinchRecognizer.scale)
        }
    }
}
