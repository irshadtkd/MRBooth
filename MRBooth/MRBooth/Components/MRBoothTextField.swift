//
//  MRBoothTextField.swift
//  MRBooth
//

import SwiftUI

struct MRBoothTextField: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var isNumeric: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppFonts.caption(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
            TextField(placeholder.isEmpty ? title : placeholder, text: $text)
                .font(AppFonts.body())
                .foregroundStyle(AppTheme.textPrimary)
                #if os(iOS)
                .keyboardType(isNumeric ? .numberPad : .default)
                #endif
                .padding(12)
                .background(AppTheme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
        }
    }
}
