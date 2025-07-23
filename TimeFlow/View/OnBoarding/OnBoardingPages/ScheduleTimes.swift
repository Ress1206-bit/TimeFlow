import SwiftUI

struct ScheduleTimes: View {
    
    @Binding var awakeHours: AwakeHours
    let themeColor: Color
    
    var onContinue: () -> Void = {}
    
    @State private var wakeMin: Double
    @State private var bedMin: Double
    
    private var sleepHours: Double {
        let span = (wakeMin - bedMin + 1440).truncatingRemainder(dividingBy: 1440)
        return (span / 60 * 10).rounded() / 10
    }
    
    private let card = Color(red: 0.13, green: 0.13, blue: 0.15)
    
    @State private var animateContent = false
    
    init(awakeHours: Binding<AwakeHours>, themeColor: Color, onContinue: @escaping () -> Void = {}) {
        self._awakeHours = awakeHours
        self.themeColor = themeColor
        self.onContinue = onContinue
        
        let initialWake = toMinutes(awakeHours.wrappedValue.wakeTime)
        let initialBed = toMinutes(awakeHours.wrappedValue.sleepTime)
        
        self._wakeMin = State(initialValue: initialWake)
        self._bedMin = State(initialValue: initialBed)
    }
    
    var body: some View {
        ZStack {
            //background
            LinearGradient(
                colors: [
                    AppTheme.Colors.background,
                    AppTheme.Colors.secondary.opacity(0.3),
                    AppTheme.Colors.background
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                
                Spacer()
                
                header
                
                BedtimeDial(wake: $wakeMin, bed: $bedMin, accent: themeColor, card: card)
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .scaleEffect(animateContent ? 1.0 : 0.8)
                    .opacity(animateContent ? 1.0 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateContent)
                
                sleepDurationDisplay
                    .scaleEffect(animateContent ? 1.0 : 0.8)
                    .opacity(animateContent ? 1.0 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateContent)
                
                Spacer()
                
                Button(action: onContinue) {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isValidSchedule ? themeColor : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .padding(.horizontal)
                        .padding(.bottom, 22)
                }
                .disabled(!isValidSchedule)
            }
        }
        .preferredColorScheme(.dark)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { progressToolbar(currentStep: 3) {
            onContinue()
        } }
        .onChange(of: wakeMin) { oldValue, newValue in
            enforceMinSeparation()
            awakeHours.wakeTime = toHHMM(from: newValue)
        }
        .onChange(of: bedMin) { oldValue, newValue in
            enforceMinSeparation()
            awakeHours.sleepTime = toHHMM(from: newValue)
        }
        .onAppear {
            withAnimation {
                animateContent = true
            }
        }
    }
    
    private var isValidSchedule: Bool {
        sleepHours >= 1 && sleepHours <= 23  // Prevent 0 or 24-hour sleep
    }
    
    private func enforceMinSeparation() {
        let minSeparation: Double = 60  // At least 1 hour apart
        let diff = (wakeMin - bedMin + 1440).truncatingRemainder(dividingBy: 1440)
        if diff < minSeparation {
            bedMin = (wakeMin - minSeparation + 1440).truncatingRemainder(dividingBy: 1440)
        } else if diff > 1440 - minSeparation {
            wakeMin = (bedMin + minSeparation).truncatingRemainder(dividingBy: 1440)
        }
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
        .opacity(animateContent ? 1.0 : 0)
        .offset(y: animateContent ? 0 : -20)
        .animation(.easeOut(duration: 0.8), value: animateContent)
    }
    
    private var sleepDurationDisplay: some View {
        Text("Sleep duration: \(sleepHours, specifier: "%.1f") hours")
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.white.opacity(0.9))
            .padding(.horizontal)
    }
}

struct BedtimeDial: View {
    @Binding var wake: Double
    @Binding var bed: Double
    
    let accent: Color
    let card: Color
    
    private let stroke: CGFloat = 30
    private let knob: CGFloat = 34
    private let minTickHeight: CGFloat = 8
    private let hourTickHeight: CGFloat = 16
    private let labelOffset: CGFloat = 28  // Space for labels outside ticks
    
    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let radius = (side - knob - labelOffset) / 2  // Adjust for labels
            let centre = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            
            ZStack {
                dial(radius: radius)
                sleepArc(radius: radius, centre: centre)
                knob(minutes: $bed, symbol: "moon.fill", color: accent, radius: radius, centre: centre)
                knob(minutes: $wake, symbol: "sun.max.fill", color: accent, radius: radius, centre: centre)
                centreTimes
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Bedtime dial. Wake at \(timeString(from: wake)), Bed at \(timeString(from: bed))")
    }
    
    private func dial(radius: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(card)
                .shadow(color: .black.opacity(0.6), radius: 6)
            ForEach(0..<288) { i in  // 288 ticks for every 5 minutes (1440/5=288)
                if i % 12 == 0 {  // Every hour (288/24=12)
                    hourTickAndLabel(at: i, radius: radius)
                } else {
                    minorTick(at: i, radius: radius)
                }
            }
        }
    }
    
    private func minorTick(at index: Int, radius: CGFloat) -> some View {
        Rectangle()
            .fill(Color.white.opacity(0.4))
            .frame(width: 1, height: minTickHeight)
            .offset(y: -radius + minTickHeight / 2)
            .rotationEffect(.degrees(Double(index) * 1.25))  // 360/288=1.25
    }
    
    private func hourTickAndLabel(at index: Int, radius: CGFloat) -> some View {
        let hour = index / 12  // 0 to 23
        let rotation = Double(index) * 1.25
        
        return ZStack {
            Rectangle()
                .fill(Color.white.opacity(0.7))
                .frame(width: 2, height: hourTickHeight)
                .offset(y: -radius + hourTickHeight / 2)
            Text("\(hour)")
                .font(.caption2.weight(.semibold))
                .foregroundColor(.white.opacity(0.8))
                .offset(y: -radius - labelOffset / 2 + 4)  // Position outside
        }
        .rotationEffect(.degrees(rotation))
    }
    
    private func sleepArc(radius: CGFloat, centre: CGPoint) -> some View {
        let startAngle = Angle(degrees: angle(for: bed) - 90)
        let endAngle = Angle(degrees: angle(for: wake) - 90)
        let clockwise = (wake - bed + 1440).truncatingRemainder(dividingBy: 1440) > 720  // Determine direction
        
        return Path { p in
            p.addArc(center: centre,
                     radius: radius,
                     startAngle: startAngle,
                     endAngle: endAngle,
                     clockwise: clockwise)
        }
        .stroke(accent.opacity(0.5),  // Increased opacity for better visibility
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
                    
                    if mins != minutes.wrappedValue {
                        minutes.wrappedValue = mins
                        
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }
                }
        )
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Drag to adjust time")
    }
    
    private var centreTimes: some View {
        VStack(spacing: 6) {
            Text("Wake \(timeString(from: wake))")
            Text("Bed \(timeString(from: bed))")
        }
        .font(.callout.weight(.semibold))  // Larger font for better readability
        .foregroundColor(.white)
    }
    
    private func angle(for m: Double) -> Double { m / 1440 * 360 }
    
    private func timeString(from minutes: Double) -> String {
        let total = Int(minutes) % 1440
        let h = total / 60
        let m = total % 60
        let d = Calendar.current.date(bySettingHour: h, minute: m, second: 0, of: Date())!
        return DateFormatter.localizedString(from: d, dateStyle: .none, timeStyle: .short)
    }
}

private func toMinutes(_ hhmm: String) -> Double {
    let comps = hhmm.split(separator: ":").compactMap { Int($0) }
    guard comps.count == 2 else { return 0 }
    return Double((comps[0] * 60) + comps[1])
}

private func toHHMM(from minutes: Double) -> String {
    let h = Int(minutes) / 60 % 24
    let m = Int(minutes) % 60
    return String(format: "%02d:%02d", h, m)
}

#Preview {
    ScheduleTimes(awakeHours: .constant(AwakeHours(wakeTime: "07:00", sleepTime: "23:00")), themeColor: .blue)
}
