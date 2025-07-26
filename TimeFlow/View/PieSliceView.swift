//
//  PieSliceView.swift
//  TimeFlow
//
//  Created by Adam Ress on 7/21/25.
//

import SwiftUI

struct PieSliceView: View {
    let startAngle: Angle
    let endAngle: Angle
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2
            
            Path { path in
                path.move(to: center)
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: startAngle - Angle(degrees: 90), // Adjust to start from top
                    endAngle: endAngle - Angle(degrees: 90),
                    clockwise: false
                )
                path.closeSubpath()
            }
            .fill(color)
            .overlay(
                Path { path in
                    path.move(to: center)
                    path.addArc(
                        center: center,
                        radius: radius,
                        startAngle: startAngle - Angle(degrees: 90),
                        endAngle: endAngle - Angle(degrees: 90),
                        clockwise: false
                    )
                    path.closeSubpath()
                }
                .stroke(Color.white, lineWidth: 1)
            )
        }
    }
}
