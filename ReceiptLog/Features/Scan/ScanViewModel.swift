@preconcurrency import AVFoundation
import UIKit
import SwiftUI

enum ScanState: Equatable {
    case idle
    case scanning
    case processing
    case confirmed(OCRResult)
    case error(String)
}

@MainActor
@Observable
final class ScanViewModel: NSObject {
    var scanState: ScanState = .idle
    var capturedImage: UIImage?
    var ocrResult: OCRResult?
    var showOCRConfirm: Bool = false
    var isTorchOn: Bool = false

    private let ocrService = OCRService()
    let session = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "com.kbytsubasa.ReceiptLog.camera.session")

    func setupCamera() {
        guard session.inputs.isEmpty else { return }
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            scanState = .error("カメラが利用できません")
            return
        }
        session.beginConfiguration()
        session.addInput(input)
        session.addOutput(photoOutput)
        session.commitConfiguration()
        let capturedSession = session
        sessionQueue.async { capturedSession.startRunning() }
    }

    func stopCamera() {
        let capturedSession = session
        sessionQueue.async { capturedSession.stopRunning() }
    }

    func capturePhoto() {
        guard case .idle = scanState else { return }
        let capturedOutput = photoOutput
        sessionQueue.async { [weak self] in
            guard let self else { return }
            let settings = AVCapturePhotoSettings()
            capturedOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    func toggleTorch() {
        sessionQueue.async { [weak self] in
            guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
            do {
                try device.lockForConfiguration()
                device.torchMode = device.torchMode == .on ? .off : .on
                let isOn = device.torchMode == .on
                device.unlockForConfiguration()
                Task { @MainActor [weak self] in
                    self?.isTorchOn = isOn
                }
            } catch {
                print("Torch toggle failed: \(error)")
            }
        }
    }

    func processImage(_ image: UIImage) async {
        scanState = .processing
        do {
            let result = try await ocrService.recognizeText(from: image)
            capturedImage = image
            ocrResult = result
            scanState = .confirmed(result)
            showOCRConfirm = true
        } catch {
            scanState = .error("読み取れませんでした。手動入力してください。")
        }
    }

    func selectFromLibrary(_ image: UIImage) async {
        await processImage(image)
    }

    func startManualEntry() {
        ocrResult = OCRResult(storeName: "", totalAmount: nil, date: Date(), rawText: "")
        capturedImage = nil
        showOCRConfirm = true
    }
}

extension ScanViewModel: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }
        Task { @MainActor [self] in
            await self.processImage(image)
        }
    }
}
