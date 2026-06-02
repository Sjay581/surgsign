import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Accessibility View Extensions

extension View {
    /// Groups a decorative badge view into a single accessibility element
    /// with a combined label/value pair. Useful for compact patient-card
    /// badges (POD, code status, etc.) where the individual glyphs would
    /// otherwise be read out separately by VoiceOver.
    ///
    /// - Parameters:
    ///   - label: The descriptive label (e.g. "Code status").
    ///   - value: The current value (e.g. "DNR"). `nil` collapses the
    ///     accessibility element to label-only.
    func surgAccessibilityBadge(_ label: String, value: String?) -> some View {
        let combined: String
        if let value, !value.isEmpty {
            combined = "\(label), \(value)"
        } else {
            combined = label
        }
        return self
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(combined))
    }
}

// MARK: - Haptic Feedback

#if canImport(UIKit)
/// Fires a single impact-style haptic. No-op on platforms without UIKit so
/// the package continues to build headlessly (e.g. Linux SwiftPM CI).
func surgHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
    let generator = UIImpactFeedbackGenerator(style: style)
    generator.prepare()
    generator.impactOccurred()
}
#endif