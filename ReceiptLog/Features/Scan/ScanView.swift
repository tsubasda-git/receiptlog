import SwiftUI
import AVFoundation
import PhotosUI

struct ScanView: View {
    @State private var viewModel = ScanViewModel()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showToast = false
    @State private var toastMessage = ""
    @Environment(\.modelContext) private var modelContext

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
                        if case .processing = viewModel.scanState {
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

                    Button(action: { viewModel.capturePhoto() }) {
                        Circle()
                            .fill(.white)
                            .frame(width: 70, height: 70)
                            .overlay(Circle().stroke(Color.receiptAccent, lineWidth: 3).padding(4))
                    }

                    Button(action: {}) {
                        Image(systemName: "bolt.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                    }
                }
                .padding(.bottom, 20)

                Button("✏️ 手動で入力する") {
                    viewModel.startManualEntry()
                }
                .foregroundStyle(.white)
                .padding(.bottom, 30)
            }
        }
        .onAppear { viewModel.setupCamera() }
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
                        toastMessage = "✓ 保存しました"
                        showToast = true
                        viewModel.showOCRConfirm = false
                    }
                )
            }
        }
        .toast(isPresented: $showToast, message: toastMessage)
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
