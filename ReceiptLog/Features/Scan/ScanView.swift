import SwiftUI
import SwiftData
import StoreKit
import AVFoundation
import PhotosUI

struct ScanView: View {
    @State private var viewModel = ScanViewModel()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var cameraPermissionDenied = false
    @Environment(\.modelContext) private var modelContext
    @AppStorage("scanSaveCount") private var scanSaveCount = 0

    private var isProcessing: Bool {
        if case .processing = viewModel.scanState { return true }
        return false
    }

    var body: some View {
        ZStack {
            CameraPreviewView(session: viewModel.session)
                .ignoresSafeArea()

            VStack {
                Spacer()

                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.receiptAccent, lineWidth: 3)
                    .frame(width: 300, height: 400)
                    .overlay {
                        if isProcessing {
                            ProgressView()
                                .tint(.white)
                        }
                    }

                Spacer()

                HStack(spacing: 40) {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title)
                            .foregroundStyle(.white)
                    }
                    .accessibilityLabel("フォトライブラリから選択")

                    Button(action: { viewModel.capturePhoto() }) {
                        Circle()
                            .fill(isProcessing ? Color.white.opacity(0.5) : .white)
                            .frame(width: 70, height: 70)
                            .overlay(Circle().stroke(Color.receiptAccent, lineWidth: 3).padding(4))
                    }
                    .disabled(isProcessing)
                    .accessibilityLabel("撮影")

                    Button(action: { viewModel.toggleTorch() }) {
                        Image(systemName: viewModel.isTorchOn ? "bolt.fill" : "bolt.slash.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                    }
                    .accessibilityLabel(viewModel.isTorchOn ? "フラッシュをオフ" : "フラッシュをオン")
                }
                .padding(.bottom, 20)

                Button("✏️ 手動で入力する") {
                    viewModel.startManualEntry()
                }
                .foregroundStyle(.white)
                .padding(.bottom, 30)
                .accessibilityIdentifier("manual-entry-button")
            }
        }
        .onAppear {
            checkCameraPermission()
            viewModel.setupCamera()
        }
        .onDisappear {
            viewModel.stopCamera()
            viewModel.showOCRConfirm = false
        }
        .onChange(of: viewModel.scanState) { _, state in
            if case .error(let msg) = state {
                toastMessage = msg
                showToast = true
            }
        }
        .onChange(of: selectedPhoto) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await viewModel.selectFromLibrary(image)
                }
            }
        }
        .sheet(isPresented: $viewModel.showOCRConfirm) {
            if let result = viewModel.ocrResult {
                OCRConfirmView(
                    ocrResult: result,
                    capturedImage: viewModel.capturedImage,
                    onSave: { receipt in
                        modelContext.insert(receipt)
                        scanSaveCount += 1
                        requestReviewIfNeeded()
                        toastMessage = "✓ 保存しました"
                        showToast = true
                        viewModel.showOCRConfirm = false
                        selectedPhoto = nil
                    }
                )
            }
        }
        .alert("カメラのアクセスが必要です", isPresented: $cameraPermissionDenied) {
            Button("設定を開く") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("レシートを撮影するにはカメラへのアクセスを許可してください。設定アプリから変更できます。")
        }
        .toast(isPresented: $showToast, message: toastMessage)
    }

    private func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if !granted {
                    DispatchQueue.main.async { cameraPermissionDenied = true }
                }
            }
        case .denied, .restricted:
            cameraPermissionDenied = true
        default:
            break
        }
    }

    private func requestReviewIfNeeded() {
        guard scanSaveCount == 3 else { return }
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else { return }
        AppStore.requestReview(in: scene)
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            layer.frame = uiView.bounds
        }
    }
}
