//
//  BaseViewModel.swift
//  PokeDex
//
//  Created by yamartin on 12/12/24.
//

import Foundation
import OSLog

/// The possible states of a view during its lifecycle.
///
/// This enum represents the various states a UI can be in while loading,
/// processing, or displaying data.
///
/// ## Cases
/// - `okey`: Data loaded successfully and ready to display
/// - `loading`: Data is being fetched from the network
/// - `error`: An error occurred during data fetching
/// - `unknownError`: An unexpected error occurred
/// - `notReachable`: Network connection is not available
/// - `empty`: No data is available to display
enum ViewModelState: String {
    /// Data loaded successfully and ready to display.
    case okey

    /// Data is being fetched from the network.
    case loading

    /// An error occurred during data fetching.
    case error

    /// An unexpected error occurred without specific information.
    case unknownError

    /// Network connection is not available.
    case notReachable

    /// No data is available to display.
    case empty
}

/// A base class that provides common functionality for all ViewModels.
///
/// `BaseViewModel` is the parent class for all view models in the application.
/// It provides shared properties and methods for managing view state, error handling,
/// and lifecycle events.
///
/// ## Shared Properties
/// - `state`: The current state of the view (loading, success, error, etc.)
/// - `showWarningError`: Controls visibility of error dialogs
/// - `alertButtonDisable`: Enables/disables action buttons during operations
///
/// ## Lifecycle
/// Subclasses can override `onAppear()` to perform initialization when the view appears.
///
/// ## Usage
/// ```swift
/// class MyFeatureViewModel: BaseViewModel, ObservableObject {
///     @Published var data: [Item] = []
///
///     override func onAppear() {
///         loadData()
///     }
///
///     @MainActor
///     private func loadData() {
///         state = .loading
///         // Fetch and update data
///     }
/// }
/// ```
public class BaseViewModel {
    /// The current state of the view (loading, success, error, etc.).
    /// Published property that triggers UI updates when changed.
    @Published var state: ViewModelState = .okey

    /// Controls whether an error warning dialog should be displayed.
    /// Set to `true` to show the error dialog, `false` to hide it.
    @Published var showWarningError = false

    /// Controls whether action buttons should be disabled.
    /// Typically set to `true` during network operations to prevent duplicate requests.
    @Published var alertButtonDisable = false

    /// Logs an error message using the centralized API logger.
    /// All ViewModels should use this method for consistent error logging.
    /// - Parameter message: The error message to log
    func logError(_ message: String) {
        Logger.api.error("\(message)")
    }

    /// Called when the view appears on screen.
    /// Override this method in subclasses to perform initialization,
    /// such as loading data from the network.
    ///
    /// This method runs on the main thread due to the `@MainActor` annotation.
    @MainActor
    public func onAppear() {
        print(#function)
    }
}
