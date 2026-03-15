//
//  SlidingDrawerPosition.swift
//  MacRuler
//
//  Created by Eoin Kortext on 15/03/2026.
//


//
//  SlidingDrawerPosition.swift
//  TestUI
//
//  Created by Eoin Kortext on 11/03/2026.
//


import SwiftUI

// MARK: - Sliding Drawer View

/// A container view that slides in from the left or right edge of its parent,
/// anchored to one of the four corners. A chevron toggle sits in the padding
/// strip on the outer edge and drives the expand/collapse animation.
///
/// Usage:
/// ```
/// SlidingDrawerView(position: .bottomRight) {
///     VStack(alignment: .leading, spacing: 8) {
///         Text("Layer 1").font(.headline)
///         Toggle("Visible", isOn: $layerVisible)
///         Slider(value: $opacity)
///     }
///     .padding()
/// }
/// ```
struct SlidingDrawerView<Content: View>: View {

    let position: SlidingDrawerPosition
    let chevronWidth: CGFloat
    let animationDuration: Double
    @ViewBuilder let content: () -> Content

    @State private var isExpanded: Bool = true
    /// Measured width of the user-supplied content.
    @State private var contentWidth: CGFloat = 0

    // MARK: Init

    init(
        position: SlidingDrawerPosition,
        chevronWidth: CGFloat = 28,
        animationDuration: Double = 0.3,
        expanded: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.position = position
        self.chevronWidth = chevronWidth
        self.animationDuration = animationDuration
        self._isExpanded = State(initialValue: expanded)
        self.content = content
    }

    // MARK: Computed helpers

    /// How far to push the content off-screen when collapsed.
    /// Positive = shifted toward the near edge (off-screen).
    private var collapsedOffset: CGFloat {
        let travel = contentWidth
        return position.isLeft ? -travel : travel
    }

    private var currentOffset: CGFloat {
        isExpanded ? 0 : collapsedOffset
    }

    private var chevronImage: String {
        isExpanded ? position.expandedChevron : position.collapsedChevron
    }

    // MARK: Body

    var body: some View {
        // The whole assembly lives inside a frame aligned to the chosen corner.
        GeometryReader { _ in
            drawerBody
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: cornerAlignment
                )
        }
    }

    private var cornerAlignment: Alignment {
        switch position {
        case .topLeft:     return .topLeading
        case .topRight:    return .topTrailing
        case .bottomLeft:  return .bottomLeading
        case .bottomRight: return .bottomTrailing
        }
    }

    /// The actual sliding strip: [chevron | content] or [content | chevron]
    /// depending on side.
    private var drawerBody: some View {
        HStack(spacing: 0) {
            if position.isLeft {
                measuredContent
                chevronStrip
            } else {
                chevronStrip
                measuredContent
            }
        }
        .offset(x: currentOffset)
        .animation(.easeInOut(duration: animationDuration), value: isExpanded)
        // Clip so the content doesn't bleed outside while sliding.
        // We only clip the outer edge; the chevron remains visible.
        .clipped()
    }

    // MARK: Sub-views

    /// The user content, wrapped in a background GeometryReader to measure width.
    private var measuredContent: some View {
        content()
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear { contentWidth = geo.size.width }
                        .onChange(of: geo.size.width) { _, newWidth in
                            contentWidth = newWidth
                        }
                }
            )
    }

    /// The narrow strip with the chevron toggle.
    private var chevronStrip: some View {
        Button {
            withAnimation(.easeInOut(duration: animationDuration)) {
                isExpanded.toggle()
            }
        } label: {
            Image(systemName: chevronImage)
                .font(.title2)
                .frame(width: chevronWidth, height: chevronWidth + 5.0)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        #if os(macOS)
        .focusable(false)
        #endif
    }
}


// MARK: - Position Enum

enum SlidingDrawerPosition {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight

    var isLeft: Bool {
        switch self {
        case .topLeft, .bottomLeft: return true
        case .topRight, .bottomRight: return false
        }
    }

    var isTop: Bool {
        switch self {
        case .topLeft, .topRight: return true
        case .bottomLeft, .bottomRight: return false
        }
    }

    var verticalAlignment: Alignment {
        isTop ? .top : .bottom
    }

    var horizontalAlignment: HorizontalAlignment {
        isLeft ? .leading : .trailing
    }

    /// The chevron image when the drawer is expanded (visible).
    var expandedChevron: String {
        isLeft ? "chevron.compact.left" : "chevron.compact.right"
    }

    /// The chevron image when the drawer is collapsed (hidden).
    var collapsedChevron: String {
        isLeft ? "chevron.compact.right" : "chevron.compact.left"
    }
}
