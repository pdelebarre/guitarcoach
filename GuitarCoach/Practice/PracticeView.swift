import SwiftUI

struct PracticeView: View {
    @State private var model = PracticeViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if model.canUseCamera {
                CameraPreview(session: model.camera.session)
                    .ignoresSafeArea()
                    .overlay(alignment: .bottom) { controlsOverlay }
                    .overlay(alignment: .top) { guidanceOverlay }
            } else {
                permissionDeniedView
            }
        }
        .onAppear { model.start() }
        .onDisappear { model.stop() }
        .accessibilityElement(children: .contain)
    }

    private var guidanceOverlay: some View {
        VStack(spacing: 8) {
            Text(model.currentChord.name)
                .font(.system(.largeTitle, design: .rounded).bold())
                .foregroundStyle(.white)
                .shadow(radius: 4)

            Text(model.primaryMessage)
                .font(.system(.title3, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .shadow(radius: 4)
                .accessibilityLabel("Coaching guidance")

            if model.allMessages.count > 1 {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(model.allMessages.dropFirst(), id: \.self) { message in
                        Text("• \(message)")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                .accessibilityHidden(true)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.black.opacity(0.35))
    }

    private var controlsOverlay: some View {
        Button(action: model.cycleChord) {
            Label("Next chord", systemImage: "arrow.triangle.2.circlepath")
                .font(.headline)
                .padding()
                .background(.ultraThinMaterial, in: Capsule())
        }
        .padding(.bottom, 32)
        .accessibilityHint("Moves to the next chord in the starter path.")
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Camera access is needed to show finger placement.")
                .font(.headline)
                .multilineTextAlignment(.center)
            Text("Enable camera access in Settings. Frames are processed on-device and never stored.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
    }
}
