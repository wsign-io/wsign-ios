#if os(iOS)
import SwiftUI
import UIKit

/// A SwiftUI view that hosts the signing experience. Use it inside your own `.sheet` or `.fullScreenCover`,
/// or use the `.wsignSigning(isPresented:url:configuration:onEvent:onResult:)` modifier, which also handles
/// presentation and dismissal.
public struct WsignSigningSheet: View {
    private let url: URL?
    private let configuration: WsignSigningConfiguration
    private let onEvent: ((SigningEvent) -> Void)?
    private let onDismissRequest: (() -> Void)?
    private let onResult: (SigningResult) -> Void

    @Environment(\.dismiss) private var dismiss

    /// - Parameters:
    ///   - url: The signing URL from your backend. `nil` shows the invalid-link screen.
    ///   - configuration: Session options.
    ///   - onEvent: Informational events.
    ///   - onDismissRequest: Called when the signer taps Close or the automatic dismissal delay elapses.
    ///     When `nil`, the sheet dismisses itself with the environment's `dismiss` action.
    ///   - onResult: Called once when the session ends.
    public init(
        url: URL?,
        configuration: WsignSigningConfiguration = WsignSigningConfiguration(),
        onEvent: ((SigningEvent) -> Void)? = nil,
        onDismissRequest: (() -> Void)? = nil,
        onResult: @escaping (SigningResult) -> Void
    ) {
        self.url = url
        self.configuration = configuration
        self.onEvent = onEvent
        self.onDismissRequest = onDismissRequest
        self.onResult = onResult
    }

    public var body: some View {
        let dismissAction = dismiss
        let requestDismissal = onDismissRequest
        SigningControllerRepresentable(
            url: url,
            configuration: configuration,
            onEvent: onEvent,
            onResult: onResult,
            onDismissRequest: {
                if let requestDismissal {
                    requestDismissal()
                } else {
                    dismissAction()
                }
            }
        )
        .ignoresSafeArea()
    }
}

public extension View {
    /// Presents the signing experience full screen while `isPresented` is `true`.
    ///
    /// `onResult` is called once, after the view has been dismissed. If the signer closes the view, or your
    /// code sets `isPresented` to `false` first, the result is `.canceled`.
    ///
    /// ```swift
    /// .wsignSigning(isPresented: $isSigning, url: signingURL) { result in
    ///     if result.isSigned { refreshOrder() }
    /// }
    /// ```
    func wsignSigning(
        isPresented: Binding<Bool>,
        url: URL?,
        configuration: WsignSigningConfiguration = WsignSigningConfiguration(),
        onEvent: ((SigningEvent) -> Void)? = nil,
        onResult: @escaping (SigningResult) -> Void
    ) -> some View {
        modifier(
            WsignSigningPresentationModifier(
                isPresented: isPresented,
                url: url,
                configuration: configuration,
                onEvent: onEvent,
                onResult: onResult
            )
        )
    }
}

struct WsignSigningPresentationModifier: ViewModifier {
    @Binding private var isPresented: Bool
    private let url: URL?
    private let configuration: WsignSigningConfiguration
    private let onEvent: ((SigningEvent) -> Void)?
    private let onResult: (SigningResult) -> Void
    @State private var pendingResult: SigningResult?

    init(
        isPresented: Binding<Bool>,
        url: URL?,
        configuration: WsignSigningConfiguration,
        onEvent: ((SigningEvent) -> Void)?,
        onResult: @escaping (SigningResult) -> Void
    ) {
        self._isPresented = isPresented
        self.url = url
        self.configuration = configuration
        self.onEvent = onEvent
        self.onResult = onResult
    }

    func body(content: Content) -> some View {
        content.fullScreenCover(isPresented: $isPresented, onDismiss: deliverResult) {
            WsignSigningSheet(
                url: url,
                configuration: configuration,
                onEvent: onEvent,
                onDismissRequest: { isPresented = false },
                onResult: { result in pendingResult = result }
            )
        }
    }

    private func deliverResult() {
        let result = pendingResult ?? .canceled
        pendingResult = nil
        onResult(result)
    }
}

/// Bridges `WsignSigningViewController` into SwiftUI.
struct SigningControllerRepresentable: UIViewControllerRepresentable {
    let url: URL?
    let configuration: WsignSigningConfiguration
    let onEvent: ((SigningEvent) -> Void)?
    let onResult: (SigningResult) -> Void
    let onDismissRequest: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> WsignSigningViewController {
        let controller = WsignSigningViewController(optionalURL: url, configuration: configuration)
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: WsignSigningViewController, context: Context) {
        context.coordinator.parent = self
    }

    static func dismantleUIViewController(_ controller: WsignSigningViewController, coordinator: Coordinator) {
        controller.cancel()
    }

    @MainActor
    final class Coordinator: NSObject, WsignSigningViewControllerDelegate {
        var parent: SigningControllerRepresentable

        init(parent: SigningControllerRepresentable) {
            self.parent = parent
        }

        func signingViewController(_ controller: WsignSigningViewController, didFinishWith result: SigningResult) {
            parent.onResult(result)
        }

        func signingViewController(_ controller: WsignSigningViewController, didReceive event: SigningEvent) {
            parent.onEvent?(event)
        }

        func signingViewControllerDidRequestDismissal(_ controller: WsignSigningViewController) {
            parent.onDismissRequest()
        }
    }
}
#endif
