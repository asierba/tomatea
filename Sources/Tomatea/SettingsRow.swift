import SwiftUI

struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(4)
        .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct SettingsRow<Control: View>: View {
    let title: String
    let systemImage: String
    let tint: Color
    @ViewBuilder let control: Control

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(tint, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            Text(title)
            Spacer(minLength: 8)
            control
        }
        .padding(6)
    }
}
