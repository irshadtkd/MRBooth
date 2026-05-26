//
//  ErrorHandling.swift
//  MRBooth
//

import SwiftUI

@MainActor
protocol ErrorPresenting: AnyObject {
    var activeError: AppError? { get set }
}

extension ErrorPresenting {
    func handle(_ error: Error) {
        if let appError = error as? AppError {
            present(appError)
        } else {
            present(.unknown(error.localizedDescription))
        }
    }

    func present(_ error: AppError) {
        activeError = error
    }
}

struct ErrorAlertModifier: ViewModifier {
    @Binding var error: AppError?

    func body(content: Content) -> some View {
        content
            .alert(
                AppStrings.errorTitle,
                isPresented: Binding(
                    get: { error != nil },
                    set: { if !$0 { error = nil } }
                ),
                presenting: error
            ) { _ in
                Button(AppStrings.ok, role: .cancel) { error = nil }
            } message: { err in
                Text(err.localizedDescription)
            }
    }
}

extension View {
    func errorAlert(error: Binding<AppError?>) -> some View {
        modifier(ErrorAlertModifier(error: error))
    }
}
