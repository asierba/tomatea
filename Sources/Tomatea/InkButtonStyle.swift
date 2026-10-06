import AppKit
import SwiftUI

struct InkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .foregroundStyle(Color(nsColor: .textBackgroundColor))
            .padding(.horizontal, 12)
            .frame(height: 28)
            .background(Color.primary, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .opacity(configuration.isPressed ? 0.75 : 1)
            .contentShape(Rectangle())
    }
}
