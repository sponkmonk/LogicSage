//
//  SageWebView.swift
//  SwiftSageiOS
//
//  Created by Chris Dillard on 4/26/23.
//
#if !os(macOS)

import Foundation
import SwiftUI
import UIKit
import WebKit
enum ViewMode {
    case webView
    case editor
}
struct SageMultiView: View {

    @ObservedObject var settingsViewModel: SettingsViewModel
    @State var viewMode: ViewMode
    @EnvironmentObject var windowManager: WindowManager
    var window: WindowInfo

    @EnvironmentObject var sageMultiViewModel: SageMultiViewModel
    @State var sourceEditorCode = """
    """
    @State var isEditing = false

    @Binding var frame: CGRect
    @Binding var position: CGSize
    @State private var isMoveGestureActivated = false
    @State var webViewURL: URL?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack {
                    TopBar(isEditing: $isEditing, onClose: {
                        windowManager.removeWindow(window: window)
                    }, windowInfo: window, webViewURL: getURL())
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if !isMoveGestureActivated {
                                    self.windowManager.bringWindowToFront(window: self.window)
                                    isMoveGestureActivated = true
                                }
                                let minY = geometry.safeAreaInsets.top - geometry.size.height / 12
                                // Keep windows from going to close top top
                                let newY = max(position.height + value.translation.height, minY)

                                position = CGSize(width: position.width + value.translation.width, height: newY)
                            }
                            .onEnded { value in
                                isMoveGestureActivated = false
                            }
                    )


                    if viewMode == .editor {
#if !os(macOS)
                        let viewModel = SourceCodeTextEditorViewModel()

                        SourceCodeTextEditor(text: $sageMultiViewModel.sourceCode, isEditing: $isEditing, customization:
                                                SourceCodeTextEditor.Customization(didChangeText:
                                                                                    { srcCodeTextEditor in
                            print("srcEditor didChangeText")

                        }, insertionPointColor: {
                            Colorv(cgColor: settingsViewModel.buttonColor.cgColor!)
                        }, lexerForSource: { lexer in
                            SwiftLexer()
                        }, textViewDidBeginEditing: { srcEditor in
                            print("srcEditor textViewDidBeginEditing")
                        }, theme: {
                            DefaultSourceCodeTheme(settingsViewModel: settingsViewModel)
                        }))
                        .environmentObject(viewModel)
#endif
                    }
                    else {
                        let viewModel = WebViewViewModel()
                        WebView(url:getURL())
                            .environmentObject(viewModel)
                    }

                }
                Spacer()
            }
        }

    }
    func getURL() -> URL {
        let webURL: URL
        if let webViewURL = webViewURL {
            webURL = webViewURL
        }
        else {
            webURL = URL(string: "http://www.google.com")!
        }
        
        return webURL
    }
}
class SourceCodeTextEditorViewModel: ObservableObject {
}
class WebViewViewModel: ObservableObject {
}
class PinchGestureHandler: ObservableObject {
    @Published var scale: CGFloat = 1.0
    var contentSize: CGSize = .zero
    var onContentSizeChange: ((CGSize) -> Void)?
    var isPinching: Bool = false
}
struct WebView: UIViewRepresentable {
    let url: URL
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    var webViewInstance: WKWebView {
        let webView = WKWebView()
        let request = URLRequest(url: self.url)
        webView.load(request)
        return webView
    }
    func makeUIView(context: Context) -> WKWebView {
        return webViewInstance
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {

    }
    class Coordinator: NSObject, WKNavigationDelegate, UIScrollViewDelegate {
        var parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return scrollView.subviews.first
        }
    }
}
struct HandleView: View {
    var body: some View {
        Circle()
            .frame(width: SettingsViewModel.shared.middleHandleSize, height: SettingsViewModel.shared.middleHandleSize)
            .foregroundColor(Color.white.opacity(0.666))
    }
}
#endif

#if !os(macOS)
struct ResizableViewModifier: ViewModifier {
    @Binding var frame: CGRect
    @Binding var zoomScale: CGFloat
    var window: WindowInfo

    var handleSize: CGFloat = SettingsViewModel.shared.cornerHandleSize
    @EnvironmentObject var windowManager: WindowManager

    func body(content: Content) -> some View {
        content
            .frame(width: frame.width, height: frame.height)
            .overlay(
                ResizingHandle(position: .topLeading, frame: $frame, handleSize: handleSize, zoomScale: $zoomScale, window: window)
                    .environmentObject(windowManager)
            )
        //            .overlay(ResizingHandle(position: .topTrailing, frame: $frame, handleSize: handleSize, zoomScale: $zoomScale))
        //            .overlay(ResizingHandle(position: .bottomLeading, frame: $frame, handleSize: handleSize, zoomScale: $zoomScale))
        //            .overlay(ResizingHandle(position: .bottomTrailing, frame: $frame, handleSize: handleSize, zoomScale: $zoomScale))
    }
}

struct ResizingHandle: View {
    enum Position {
        case topLeading, topTrailing, bottomLeading, bottomTrailing
    }

    var position: Position
    @Binding var frame: CGRect
    var handleSize: CGFloat
    @State private var translation: CGSize = .zero
    @Binding var zoomScale: CGFloat


    @GestureState private var dragOffset: CGSize = .zero
    @State private var activeDragOffset: CGSize = .zero
    @State private var isResizeGestureActive = false

    @EnvironmentObject var windowManager: WindowManager
    var window: WindowInfo

    var body: some View {

        Circle()
            .fill(SettingsViewModel.shared.buttonColor)
            .frame(width: handleSize, height: handleSize)
            .position(positionPoint(for: position, dragOffset: activeDragOffset))
            .opacity(0.666)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation
                    }
                    .onChanged { value in

                        activeDragOffset = value.translation

                        if !isResizeGestureActive {
                            isResizeGestureActive = true
                            self.windowManager.bringWindowToFront(window: self.window)

                        }
                    }
                    .onEnded { value in
                        updateFrame(with: value.translation)
                        activeDragOffset = .zero
                        isResizeGestureActive = false

                    }
            )
            .onChange(of: activeDragOffset) { newValue in
                withAnimation(.interactiveSpring()) {
                    updateFrame(with: newValue)
                }
            }
            .animation(.interactiveSpring(), value: activeDragOffset)
            .offset(CGSize(width: handleSize / 2, height: handleSize / 2))
    }

    private func positionPoint(for position: Position, dragOffset: CGSize) -> CGPoint {
        let translation = dragOffset
        switch position {
        case .topLeading:
            return CGPoint(x: frame.minX + translation.width / 2, y: frame.minY + translation.height / 2)
        case .topTrailing:
            return CGPoint(x: frame.maxX + translation.width / 2, y: frame.minY + translation.height / 2)
        case .bottomLeading:
            return CGPoint(x: frame.minX + translation.width / 2, y: frame.maxY + translation.height / 2)
        case .bottomTrailing:
            return CGPoint(x: frame.maxX + translation.width / 2, y: frame.maxY + translation.height / 2)
        }
    }

    private func updateFrame(with translation: CGSize) {
        let newWidth: CGFloat
        let newHeight: CGFloat

        switch position {
        case .topLeading:
            newWidth = frame.width - translation.width
            newHeight = frame.height - translation.height
        case .topTrailing:
            newWidth = frame.width + translation.width
            newHeight = frame.height - translation.height
        case .bottomLeading:
            newWidth = frame.width - translation.width
            newHeight = frame.height + translation.height
        case .bottomTrailing:
            newWidth = frame.width + translation.width
            newHeight = frame.height + translation.height
        }
        frame.size.width = newWidth
        frame.size.height = newHeight
    }
}


class SageMultiViewModel: ObservableObject {
    @Published var windowInfo: WindowInfo
    @Published var sourceCode: String

    init(windowInfo: WindowInfo) {
        self.windowInfo = windowInfo
        self.sourceCode = windowInfo.fileContents
    }
}

#endif
