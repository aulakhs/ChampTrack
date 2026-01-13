import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var style: ButtonStyle = .primary

    enum ButtonStyle {
        case primary
        case secondary
        case destructive

        var backgroundColor: Color {
            switch self {
            case .primary: return .championBlue
            case .secondary: return .clear
            case .destructive: return .accentRed
            }
        }

        var foregroundColor: Color {
            switch self {
            case .primary: return .white
            case .secondary: return .championBlue
            case .destructive: return .white
            }
        }

        var borderColor: Color {
            switch self {
            case .primary: return .clear
            case .secondary: return .championBlue
            case .destructive: return .clear
            }
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                        .scaleEffect(0.8)
                }
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(style.backgroundColor)
            .foregroundColor(style.foregroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(style.borderColor, lineWidth: style == .secondary ? 2 : 0)
            )
        }
        .disabled(isLoading || isDisabled)
        .opacity(isDisabled ? 0.6 : 1)
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    var icon: String? = nil

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.medium)
            }
            .foregroundColor(.championBlue)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Color.championBlue.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

struct IconButton: View {
    let icon: String
    let action: () -> Void
    var color: Color = .championBlue
    var size: CGFloat = 44

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(color)
                .frame(width: size, height: size)
                .background(color.opacity(0.1))
                .clipShape(Circle())
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        PrimaryButton(title: "Sign In", action: {})
        PrimaryButton(title: "Loading...", action: {}, isLoading: true)
        PrimaryButton(title: "Sign Up", action: {}, style: .secondary)
        PrimaryButton(title: "Delete", action: {}, style: .destructive)
        SecondaryButton(title: "Add Child", action: {}, icon: "plus")
        HStack {
            IconButton(icon: "pencil", action: {})
            IconButton(icon: "trash", action: {}, color: .accentRed)
        }
    }
    .padding()
}
