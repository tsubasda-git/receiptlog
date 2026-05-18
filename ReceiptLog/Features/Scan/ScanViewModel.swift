import AVFoundation
import UIKit
import SwiftUI

enum ScanState {
    case idle
    case scanning
    case processing
    case confirmed(OCRResult)
    case error(String)
}

@Observable
final class ScanViewModel: NSObject {
    var scanState: ScanState = .idle
    var capturedImage: UIImage?
    var ocrResult: OCRResult?
    var showOCRConfirm: Bool = false

    private let ocrService = OCRService()
    let session = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()

    func setupCamera() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        session.beginConfiguration()
        session.addInput(input)
        session.addOutput(photoOutput)
        session.commitConfiguration()
        Task.detached { await self.session.startRunning() }
    }

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
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
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }
        Task { await processImage(image) }
    }
}
