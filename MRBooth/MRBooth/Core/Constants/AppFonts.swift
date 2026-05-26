//
//  AppFonts.swift
//  MRBooth
//

import SwiftUI

enum AppFonts {
    static func largeTitle(_ weight: Font.Weight = .bold) -> Font {
        .system(size: 34, weight: weight, design: .rounded)
    }

    static func title(_ weight: Font.Weight = .bold) -> Font {
        .system(size: 28, weight: weight, design: .rounded)
    }

    static func title2(_ weight: Font.Weight = .semibold) -> Font {
        .system(size: 22, weight: weight, design: .rounded)
    }

    static func title3(_ weight: Font.Weight = .semibold) -> Font {
        .system(size: 20, weight: weight, design: .default)
    }

    static func headline(_ weight: Font.Weight = .semibold) -> Font {
        .system(size: 17, weight: weight, design: .default)
    }

    static func body(_ weight: Font.Weight = .regular) -> Font {
        .system(size: 16, weight: weight, design: .default)
    }

    static func callout(_ weight: Font.Weight = .regular) -> Font {
        .system(size: 15, weight: weight, design: .default)
    }

    static func subheadline(_ weight: Font.Weight = .regular) -> Font {
        .system(size: 14, weight: weight, design: .default)
    }

    static func footnote(_ weight: Font.Weight = .regular) -> Font {
        .system(size: 13, weight: weight, design: .default)
    }

    static func caption(_ weight: Font.Weight = .medium) -> Font {
        .system(size: 12, weight: weight, design: .default)
    }

    static func caption2(_ weight: Font.Weight = .regular) -> Font {
        .system(size: 11, weight: weight, design: .default)
    }

    static func statNumber() -> Font {
        .system(size: 32, weight: .bold, design: .rounded)
    }

    static func button() -> Font {
        .system(size: 17, weight: .semibold, design: .rounded)
    }
}
