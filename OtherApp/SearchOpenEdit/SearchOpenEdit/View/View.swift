//
//  View.swift
//  ProjectConfusion
//
//  Created by zhouziyuan on 2022/7/13.
//

import SwiftUI

struct NiceButtonStyle: ButtonStyle {
    var foregroundColor: Color
    var backgroundColor: Color
    var pressedColor: Color

    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(10)
            .foregroundColor(foregroundColor)
            .background(configuration.isPressed ? pressedColor : backgroundColor)
            .cornerRadius(5)
    }
}

extension View {
    func niceButton(
        foregroundColor: Color = .white,
        backgroundColor: Color = .gray,
        pressedColor: Color = .accentColor
    ) -> some View {
        buttonStyle(
            NiceButtonStyle(
                foregroundColor: foregroundColor,
                backgroundColor: backgroundColor,
                pressedColor: pressedColor
            )
        )
    }

    /// Adds a double click handler this view (macOS only)
    ///
    /// Example
    /// ```
    /// Text("Hello")
    ///     .onDoubleClick { print("Double click detected") }
    /// ```
    /// - Parameters:
    ///   - handler: Block invoked when a double click is detected
    func onDoubleClick(handler: @escaping () -> Void) -> some View {
        modifier(DoubleClickHandler(handler: handler))
    }

    /// Adds a right click handler this view (macOS only)
    ///
    /// Example
    /// ```
    /// Text("Hello")
    ///     .onRightClick { print("right click detected") }
    /// ```
    /// - Parameters:
    ///   - handler: Block invoked when a double click is detected
    func onRightClick(handler: @escaping () -> Void) -> some View {
        modifier(RightClickHandler(handler: handler))
    }
}

struct DoubleClickHandler: ViewModifier {
    let handler: () -> Void
    func body(content: Content) -> some View {
        content.overlay {
            ClickListeningViewRepresentable(clickType: .Double, handler: handler)
        }
    }
}

struct RightClickHandler: ViewModifier {
    let handler: () -> Void
    func body(content: Content) -> some View {
        content.overlay {
            ClickListeningViewRepresentable(clickType: .Right, handler: handler)
        }
    }
}

struct ClickListeningViewRepresentable: NSViewRepresentable {
    let clickType: ClickListeningView.ClickType
    let handler: () -> Void
    func makeNSView(context: Context) -> ClickListeningView {
        ClickListeningView(clickType: clickType, handler: handler)
    }

    func updateNSView(_ nsView: ClickListeningView, context: Context) {}
}

class ClickListeningView: NSView {
    enum ClickType {
        case Double
        case Right
    }

    let clickType: ClickType
    let handler: () -> Void

    init(clickType: ClickType, handler: @escaping () -> Void) {
        self.clickType = clickType
        self.handler = handler
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        if clickType == .Double, event.clickCount == 2 {
            handler()
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        super.rightMouseDown(with: event)
        guard clickType == .Right else { return }
        handler()
    }
}
