//
//  ScheduleTimes.swift
//  TimeFlow
//
//  Created by Adam Ress on 6/28/25.
//

import SwiftUI

struct ScheduleTimes: View {
    @State private var wake: Double = 7 * 60
    @State private var bed:  Double = 23 * 60
    
    var onContinue: () -> Void = {}
    
    private var sleepHours: Double {
        let span = (wake - bed + 1440).truncatingRemainder(dividingBy: 1440)
        return (span / 60 * 10).rounded() / 10
    }
    
    private let accent = Color(red: 0.30, green: 0.64, blue: 0.97)
    private let card   = Color(red: 0.13, green: 0.13, blue: 0.15)
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
                .overlay(
                    Image("Noise")
                        .resizable()
                        .scaledToFill()
                        .opacity(0.05)
                        .ignoresSafeArea()
                )
            
            VStack(spacing: 40) {
                
                Spacer()
                
                header
                
                BedtimeDial(wake: $wake, bed: $bed, accent: accent, card: card)
                    .frame(width: 340, height: 340)
                
                Text("\(sleepHours, specifier: "%.1f") h in bed")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Button(action: onContinue) {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(accent)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .padding(.horizontal)
                        .padding(.bottom, 22)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var header: some View {
        VStack(spacing: 8) {
            Text("When do you usually sleep?")
                .font(.title2.weight(.bold))
                .foregroundColor(.white)
            Text("Drag the handles to set wake-up and bedtime.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
    }
    
    @ToolbarContentBuilder
    var progressToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Text("Step 3 of 6")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white.opacity(0.7))
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Skip") { onContinue() }
                .foregroundColor(.white.opacity(0.9))
        }
    }
}

struct BedtimeDial: View {
    @Binding var wake: Double
    @Binding var bed:  Double
    
    let accent: Color
    let card: Color
    
    private let stroke: CGFloat = 30
    private let knob:  CGFloat = 34
    
    var body: some View {
        GeometryReader { geo in
            let side   = min(geo.size.width, geo.size.height)
            let radius = (side - knob) / 2
            let centre = CGPoint(x: geo.size.width/2, y: geo.size.height/2)
            
            ZStack {
                dial(radius: radius)
                sleepArc(radius: radius, centre: centre)
                knob(minutes: $bed,  symbol: "moon.fill",
                     color: accent.opacity(0.85), radius: radius, centre: centre)
                knob(minutes: $wake, symbol: "sun.max.fill",
                     color: .yellow.opacity(0.95), radius: radius, centre: centre)
                centreTimes
            }
        }
    }
    
    private func dial(radius: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(card)
                .shadow(color: .black.opacity(0.6), radius: 6)
            ForEach(0..<24) { h in
                Rectangle()
                    .fill(Color.white.opacity(0.7))
                    .frame(width: 2, height: h % 6 == 0 ? 16 : 8)
                    .offset(y: -radius + 8)
                    .rotationEffect(.degrees(Double(h) / 24 * 360))
            }
        }
    }
    
    private func sleepArc(radius: CGFloat, centre: CGPoint) -> some View {
        let start = Angle(degrees: angle(for: bed))
        let end   = Angle(degrees: angle(for: wake))
        return Path { p in
            p.addArc(center: centre,
                     radius: radius,
                     startAngle: start - .degrees(90),
                     endAngle:   end   - .degrees(90),
                     clockwise: false)
        }
        .stroke(accent.opacity(0.3),
                style: StrokeStyle(lineWidth: stroke, lineCap: .round))
    }
    
    private func knob(minutes: Binding<Double>,
                      symbol: String,
                      color: Color,
                      radius: CGFloat,
                      centre: CGPoint) -> some View {
        let ang = angle(for: minutes.wrappedValue)
        let rad = CGFloat(ang - 90) * .pi / 180
        let x = centre.x + cos(rad) * radius
        let y = centre.y + sin(rad) * radius
        
        return ZStack {
            Circle()
                .fill(color)
                .frame(width: knob, height: knob)
                .shadow(radius: 3)
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
        }
        .position(x: x, y: y)
        .gesture(
            DragGesture()
                .onChanged { g in
                    
                    let v = CGVector(dx: g.location.x - centre.x,
                                     dy: g.location.y - centre.y)
                    
                    var deg = atan2(v.dy, v.dx) * 180 / .pi + 90
                    
                    if deg < 0 {
                        deg += 360
                    }
                    
                    var mins = deg / 360 * 1440
                    mins = (mins / 5).rounded() * 5

                    minutes.wrappedValue = mins
                }
        )
    }
    
    private var centreTimes: some View {
        VStack(spacing: 4) {
            Text("Wake \(timeString(from: wake))")
            Text("Bed  \(timeString(from: bed))")
        }
        .font(.footnote.weight(.semibold))
        .foregroundColor(.white)
    }
    
    private func angle(for m: Double) -> Double { m / 1440 * 360 }
    
    private func timeString(from minutes: Double) -> String {
        let h = Int(minutes) / 60
        let m = Int(minutes) % 60
        let d = Calendar.current.date(bySettingHour: h, minute: m, second: 0, of: Date())!
        return DateFormatter.localizedString(from: d, dateStyle: .none, timeStyle: .short)
    }
}

#Preview {
    NavigationStack { ScheduleTimes() }
}
