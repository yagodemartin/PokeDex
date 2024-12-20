//
//  BaseViewModel.swift
//  PokeDex
//
//  Created by yamartin on 12/12/24.
//

import Foundation


enum ViewModelState: String {
    case okey

    case loading

    case error

    case unknownError

    case notReachable

    case empty
}

/// Clase base donde definimos los metodos comunes a todos los ViewModel

public class BaseViewModel {
    @Published var state: ViewModelState = .okey
    @Published var showWarningError = false
    @Published var alertButtonDisable = false
    
    @MainActor
    public func onAppear() {
        print(#function)
    }

}
