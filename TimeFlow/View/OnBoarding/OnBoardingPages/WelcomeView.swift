//
//  WelcomeView.swift
//  TimeFlow
//
//  Created by Adam Ress on 6/28/25.
//

import SwiftUI
import CoreMotion

struct WelcomeView: View {
    
    var onContinue: () -> Void = {}
    @State private var tapDown = false
    
    // Light parallax for the gradient
    @State private var motionX: CGFloat = 0
    @State private var motionY: CGFloat = 0
    private let motion = CMMotionManager()
    
    var body: some View {
        ZStack {
            animatedGradient
                .ignoresSafeArea()
                .overlay(bokehLayer.ignoresSafeArea())
            
            clockAnimation
            
            VStack(spacing: 32) {
                Spacer(minLength: 10)
                
                heroCard
                
                Spacer()
                
                getStartedButton
                    .scaleEffect(tapDown ? 0.97 : 1)
                    .animation(.spring(response: 0.25, dampingFraction: 0.6), value: tapDown)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in tapDown = true }
                            .onEnded { _ in
                                tapDown = false
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                onContinue()
                            }
                    )
                    .padding(.bottom, 35)

            }
            .padding(.horizontal, 28)
        }
        .onAppear { startMotionUpdates() }
        .onDisappear { motion.stopDeviceMotionUpdates() }
        .environment(\.colorScheme, .dark) // Ensures dark mode compatibility
    }
}

// MARK: – Layers
private extension WelcomeView {
    
    var animatedGradient: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                let t = timeline.date.timeIntervalSinceReferenceDate / 6
                let x = motionX * 40
                let y = motionY * 40
                let colors = [Color(red: 0.1, green: 0.1, blue: 0.1), Color.black]
                let g = Gradient(colors: colors)
                ctx.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .linearGradient(
                        g,
                        startPoint: CGPoint(x: 0.5 + 0.1 * sin(t) - x/size.width,
                                            y: 0.5 + 0.1 * cos(t) - y/size.height),
                        endPoint:   CGPoint(x: 0.5 - 0.1 * cos(t) - x/size.width,
                                            y: 0.5 + 0.1 * sin(t) - y/size.height))
                )
            }
        }
    }
    
    var bokehLayer: some View {
        TimelineView(.animation) { _ in
            Canvas { context, size in
                let t = Date().timeIntervalSinceReferenceDate
                for idx in 0..<12 {
                    let speed  = 20 + Double(idx) * 5
                    let phase  = (t + Double(idx) * 3)
                                    .truncatingRemainder(dividingBy: speed) / speed
                    let x      = size.width  * CGFloat(phase)
                    let y      = size.height * CGFloat((Double(idx % 4) + 1) / 5)
                    let radius = idx % 3 == 0 ? 90.0 : 50.0
                    let opacity = 0.05 - CGFloat(idx) * 0.005

                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y,
                                               width: radius, height: radius)),
                        with: .radialGradient(
                            Gradient(colors: [Color.white.opacity(opacity), .clear]),
                            center: .zero,
                            startRadius: 0,
                            endRadius: radius)
                    )
                }
            }
        }
        .blendMode(.plusLighter)
    }
    
    var clockAnimation: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                for i in 0..<20 {
                    let speed = 50.0
                    let phase = (t * speed + Double(i) * 100).truncatingRemainder(dividingBy: size.width)
                    let x = phase
                    let y = size.height * (0.2 + Double(i) / 20 * 0.6)
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: 3, height: 3)),
                        with: .color(Color.white.opacity(0.1))
                    )
                }
            }
        }
    }
    
    var heroCard: some View {
        VStack(spacing: 24) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 64, weight: .bold))
                .padding(26)
                .background(Circle().fill(Color.accentColor.opacity(0.15)))
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, .white.opacity(0.3))
            
            Text("TimeFlow")
                .font(.largeTitle.weight(.bold))
                .foregroundColor(.white)
            
            Text("Turn chaos into beautifully organised days.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.8))
            
            valueBullets
        }
        .padding(.vertical, 36)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
    
    var valueBullets: some View {
        VStack(spacing: 14) {
            pill(icon: "sparkles", text: "AI schedules in a tap")
            pill(icon: "hand.tap", text: "Drag-&-drop tweaks")
            pill(icon: "bell.badge.fill", text: "Mindful reminders")
        }
        .padding(.horizontal, 12)
    }
    func pill(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
            Text(text)
                .font(.subheadline.weight(.semibold))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 14)
        .foregroundColor(.white)
        .background(
            Capsule().fill(Color.white.opacity(0.1))
        )
    }
    
    var getStartedButton: some View {
        Text("Get Started")
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.25))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                    )
            )
            .foregroundColor(.white)
            .padding(.horizontal)
    }
}

// MARK: – Motion
private extension WelcomeView {
    func startMotionUpdates() {
        guard motion.isDeviceMotionAvailable else { return }
        motion.deviceMotionUpdateInterval = 1/40
        motion.startDeviceMotionUpdates(to: .main) { data, _ in
            guard let data = data else { return }
            motionX = CGFloat(data.attitude.roll)  / 6
            motionY = CGFloat(data.attitude.pitch) / 6
        }
    }
}

// MARK: – Preview
#Preview {
    WelcomeView()
        .environment(\.colorScheme, .dark)
}
