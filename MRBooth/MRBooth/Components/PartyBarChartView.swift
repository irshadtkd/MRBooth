//
//  PartyBarChartView.swift
//  MRBooth
//

import SwiftUI

struct PartyBarChartView: View {
    let items: [PartyReportItem]

    private var maxCount: Int {
        max(items.map(\.count).max() ?? 1, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(items) { item in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(item.party.displayName)
                            .font(AppFonts.caption(.semibold))
                            .foregroundStyle(item.party.color)
                        Spacer()
                        Text("\(item.count) (\(String(format: "%.0f", item.percentage))%)")
                            .font(AppFonts.caption())
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppTheme.elevatedBackground)
                                .frame(height: 10)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(item.party.color)
                                .frame(
                                    width: geo.size.width * CGFloat(item.count) / CGFloat(maxCount),
                                    height: 10
                                )
                        }
                    }
                    .frame(height: 10)
                }
            }
        }
    }
}

struct VotingProgressRingView: View {
    let stats: DashboardStats

    private var progress: Double {
        guard stats.total > 0 else { return 0 }
        return Double(stats.voted) / Double(stats.total)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.elevatedBackground, lineWidth: 12)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(AppTheme.success, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 4) {
                Text("\(Int(progress * 100))%")
                    .font(AppFonts.title2())
                    .foregroundStyle(AppTheme.textPrimary)
                Text(AppStrings.voted)
                    .font(AppFonts.caption())
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .frame(width: 140, height: 140)
    }
}
