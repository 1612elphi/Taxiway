import SwiftUI

// MARK: - FlipCardView

struct FlipCardView: View {
    let character: Character
    let fontSize: CGFloat
    let cardColor: Color
    let textColor: Color

    @State private var topFlapAngle: Double = 0
    @State private var bottomFlapAngle: Double = 0
    @State private var previousCharacter: Character?
    @State private var flipTask: Task<Void, Never>?

    private var charString: String { String(character) }
    private var prevString: String { String(previousCharacter ?? character) }

    private var charSize: CGSize {
        CGSize(width: fontSize * 0.7, height: fontSize * 1.2)
    }

    var body: some View {
        ZStack {
            halfCard(text: charString, isTop: false)

            halfCard(text: charString, isTop: false)
                .rotation3DEffect(
                    .degrees(bottomFlapAngle),
                    axis: (x: 1, y: 0, z: 0),
                    anchor: .top,
                    perspective: 0.3
                )

            halfCard(text: charString, isTop: true)

            halfCard(text: prevString, isTop: true)
                .rotation3DEffect(
                    .degrees(-topFlapAngle),
                    axis: (x: 1, y: 0, z: 0),
                    anchor: .bottom,
                    perspective: 0.3
                )

            Rectangle()
                .fill(Color.black.opacity(0.6))
                .frame(height: 1)
        }
        .frame(width: charSize.width, height: charSize.height)
        .clipped()
        .onChange(of: character) { oldValue, _ in
            previousCharacter = oldValue
            triggerFlip()
        }
    }

    private func halfCard(text: String, isTop: Bool) -> some View {
        Text(text)
            .font(.system(size: fontSize, weight: .bold, design: .monospaced))
            .foregroundStyle(textColor)
            .frame(width: charSize.width, height: charSize.height)
            .background(cardColor)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .modifier(HalfClip(isTop: isTop, height: charSize.height))
    }

    private func triggerFlip() {
        flipTask?.cancel()

        topFlapAngle = 0
        bottomFlapAngle = 90

        withAnimation(.easeIn(duration: 0.12)) {
            topFlapAngle = 90
        }

        withAnimation(.easeOut(duration: 0.12).delay(0.12)) {
            bottomFlapAngle = 0
        }

        let currentChar = character
        flipTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(280))
            guard !Task.isCancelled else { return }
            topFlapAngle = 0
            bottomFlapAngle = 0
            previousCharacter = currentChar
        }
    }
}

private struct HalfClip: ViewModifier {
    let isTop: Bool
    let height: CGFloat

    func body(content: Content) -> some View {
        content
            .offset(y: isTop ? height / 4 : -height / 4)
            .frame(height: height / 2)
            .clipped()
            .offset(y: isTop ? -height / 4 : height / 4)
    }
}

// MARK: - SolariWordView

struct SolariWordView: View {
    let word: String
    let fontSize: CGFloat
    let cardColor: Color
    let textColor: Color

    var body: some View {
        HStack(spacing: 3) {
            ForEach(Array(word.enumerated()), id: \.offset) { _, char in
                FlipCardView(
                    character: char,
                    fontSize: fontSize,
                    cardColor: cardColor,
                    textColor: textColor
                )
            }
        }
    }
}

// MARK: - SolariCascadeView

struct SolariCascadeView: View {
    let word: String
    let fontSize: CGFloat
    let cardColor: Color
    let textColor: Color

    @State private var displayed: [Character]
    @State private var hasAppeared = false

    private static let rollAlphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")

    init(word: String, fontSize: CGFloat, cardColor: Color, textColor: Color) {
        self.word = word
        self.fontSize = fontSize
        self.cardColor = cardColor
        self.textColor = textColor
        _displayed = State(initialValue: Array(repeating: Character(" "), count: word.count))
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(displayed.enumerated()), id: \.offset) { _, char in
                FlipCardView(
                    character: char,
                    fontSize: fontSize,
                    cardColor: cardColor,
                    textColor: textColor
                )
            }
        }
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            startCascade()
        }
    }

    private func startCascade() {
        let targets = Array(word)
        for (i, target) in targets.enumerated() {
            Task { @MainActor in
                let startDelay = 0.3 + 0.12 * Double(i)
                try? await Task.sleep(for: .seconds(startDelay))

                let rollCount = Int.random(in: 4...7)
                for r in 0..<rollCount {
                    displayed[i] = Self.rollAlphabet.randomElement()!
                    let speed = 60 + r * 12
                    try? await Task.sleep(for: .milliseconds(speed))
                }

                displayed[i] = target
            }
        }
    }
}

// MARK: - SolariTaglineView

struct SolariTaglineView: View {
    let text: String
    let maxLength: Int
    let fontSize: CGFloat
    let cardColor: Color
    let textColor: Color

    @State private var displayed: [Character]
    @State private var cascadeTask: Task<Void, Never>?

    init(text: String, maxLength: Int, fontSize: CGFloat, cardColor: Color, textColor: Color) {
        self.text = text
        self.maxLength = maxLength
        self.fontSize = fontSize
        self.cardColor = cardColor
        self.textColor = textColor
        _displayed = State(initialValue: Array(repeating: Character(" "), count: maxLength))
    }

    private var targetChars: [Character] {
        Array(text.padding(toLength: maxLength, withPad: " ", startingAt: 0))
    }

    var body: some View {
        HStack(spacing: 1.5) {
            ForEach(0..<maxLength, id: \.self) { index in
                FlipCardView(
                    character: displayed[index],
                    fontSize: fontSize,
                    cardColor: cardColor,
                    textColor: textColor
                )
            }
        }
        .onChange(of: text) { _, _ in
            startCascade()
        }
    }

    private func startCascade() {
        cascadeTask?.cancel()
        let targets = targetChars
        cascadeTask = Task { @MainActor in
            for (i, target) in targets.enumerated() {
                guard !Task.isCancelled else { return }
                if displayed[i] != target {
                    displayed[i] = target
                }
                try? await Task.sleep(for: .milliseconds(20))
            }
        }
    }
}

// MARK: - SolariStatusView

struct SolariStatusView: View {
    let outcome: DisplayOutcome

    private var word: String {
        switch outcome {
        case .pass: "PASS"
        case .warn: "WARN"
        case .fail: "FAIL"
        }
    }

    private var textColor: Color {
        switch outcome {
        case .pass: TaxiwayTheme.statusPass
        case .warn: TaxiwayTheme.statusWarning
        case .fail: TaxiwayTheme.statusError
        }
    }

    var body: some View {
        SolariWordView(
            word: word,
            fontSize: 36,
            cardColor: Color(white: 0.15),
            textColor: textColor
        )
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .background(Color(white: 0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
