//
//  TabBarView.swift
//  TimeFlow
//
//  Created by Adam Ress on 5/29/25.
//

import SwiftUI

struct TabBarView: View {
    
    @Binding var selectedTab: Int
    
    private let tabItems = [
        TabItem(icon: "house.fill", title: "Home", tag: 0),
        TabItem(icon: "target", title: "Goals", tag: 1),
        TabItem(icon: "person.circle", title: "Commitments", tag: 2),
        TabItem(icon: "person.circle", title: "Commitments", tag: 3),
        TabItem(icon: "chart.bar.fill", title: "Analytics", tag: 4),
    ]
    
    var body: some View {
        // Single container that extends to bottom
        VStack(spacing: 0) {
            // Top border
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(AppTheme.Colors.overlay.opacity(0.3))
            
            // Tab bar content
            HStack(spacing: 0) {
                ForEach(tabItems, id: \.tag) { item in
                    TabButton(
                        item: item,
                        selectedTab: $selectedTab
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)
        }
        .background(
            .ultraThinMaterial
        )
        .ignoresSafeArea(.all, edges: .bottom)
        .shadow(
            color: .black.opacity(0.1),
            radius: 10,
            x: 0,
            y: -2
        )
    }
}

struct TabButton: View {
    let item: TabItem
    @Binding var selectedTab: Int
    
    private var isSelected: Bool {
        selectedTab == item.tag
    }
    
    var body: some View {
        Button {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                selectedTab = item.tag
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    // Background indicator for selected state
                    if isSelected {
                        Circle()
                            .fill(AppTheme.Colors.primary.opacity(0.15))
                            .frame(width: 32, height: 32)
                            .scaleEffect(isSelected ? 1.0 : 0.8)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                    }
                    
                    // Icon
                    Image(systemName: item.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.textTertiary)
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                }
                
                // Title
                Text(item.title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.textQuaternary)
                    .opacity(isSelected ? 1.0 : 0.8)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Tab Item Model
struct TabItem {
    let icon: String
    let title: String
    let tag: Int
}

#Preview {
    ZStack {
        AppTheme.Colors.background
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            TabBarView(selectedTab: .constant(0))
        }
    }
}
