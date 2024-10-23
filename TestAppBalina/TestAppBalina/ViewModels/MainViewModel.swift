//
//  MainViewModel.swift
//  TestAppBalina
//
//  Created by Alexandr Filovets on 23.10.24.
//

import Combine
import SwiftUI

class MainViewModel: ObservableObject {
    @Published var photoTypes: [PhotoType] = []
    @Published var currentPage = 1
    @Published var isLoading = false
    @Published var isLastPage = false
    private var cancellables = Set<AnyCancellable>()
    
    private let service = PhotoTypeService()
    
    func loadData() {
        guard !isLoading && !isLastPage else { return }
        isLoading = true
        
        service.fetchPhotoTypes(page: currentPage)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .failure(let error):
                    print("Error fetching data: \(error)")
                case .finished:
                    break
                }
            }, receiveValue: { [weak self] response in
                self?.photoTypes.append(contentsOf: response.content)
                self?.currentPage += 1
                self?.isLastPage = self!.currentPage > response.totalPages
            })
            .store(in: &cancellables)
    }
    
    func photoTypesForPage(page: Int) -> [PhotoType] {
        let pageSize = 20
        let startIndex = (page - 1) * pageSize
        let endIndex = min(photoTypes.count, startIndex + pageSize)
        
        guard startIndex < endIndex else { return [] }
        
        return Array(photoTypes[startIndex..<endIndex])
    }
}
