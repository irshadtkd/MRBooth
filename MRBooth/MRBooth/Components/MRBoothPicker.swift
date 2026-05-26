//
//  MRBoothPicker.swift
//  MRBooth
//

import SwiftUI

struct MRBoothPicker: View {
    let title: String
    @Binding var selection: String
    let options: [String]
    var placeholder: String = "Select"
    var isEnabled: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppFonts.caption(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
            Picker(title, selection: $selection) {
                Text(placeholder).tag("")
                    .foregroundStyle(AppTheme.textSecondary)
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(.menu)
            .foregroundStyle(AppTheme.textPrimary)
            .tint(AppTheme.textPrimary)
            .disabled(!isEnabled || options.isEmpty)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
            .opacity(isEnabled && !options.isEmpty ? 1 : 0.55)
        }
    }
}
