//
//  MainViewModel.swift
//  TestAppBalina
//
//  Created by Alexandr Filovets on 23.10.24.
//

import Combine
import SwiftUI
import AVFoundation

class MainViewModel: ObservableObject {
    @Published var photoTypes: [PhotoType] = []
    @Published var currentPage = 1
    @Published var isLoading = false
    @Published var isLastPage = false
    @Published var showCamera = false
    @Published var cameraAccessDenied = false
    @Published var capturedImage: UIImage? = nil
    @Published var uploadProgress: Double = 0.0 // Прогресс загрузки
    @Published var isUploading = false // Флаг для отслеживания загрузки
    @Published var uploadResultMessage: String? = nil // Сообщение об успехе или ошибке

    private var cancellables = Set<AnyCancellable>()
    private let service = PhotoTypeService()
    
    // Загружаем данные
    func loadData() {
        guard !isLoading && !isLastPage else { return }
        isLoading = true
        
        service.fetchPhotoTypes(page: currentPage)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .failure(let error):
                    print("Error fetching data: \(error)") // Логируем ошибку загрузки данных
                case .finished:
                    break
                }
            }, receiveValue: { [weak self] response in
                self?.photoTypes.append(contentsOf: response.content)
                self?.currentPage += 1
                self?.isLastPage = response.page >= response.totalPages
            })
            .store(in: &cancellables)
    }

    // Отправляем фото и данные на сервер
    func uploadPhoto(typeId: Int, name: String) {
        guard let image = capturedImage else { return }
        
        let uploadData = PhotoUploadData(name: name, photo: image, typeId: typeId)
        isUploading = true
        uploadProgress = 0.0
        
        print("Начинается загрузка фотографии с typeId: \(typeId) и именем: \(name)")
        
        service.uploadPhoto(with: uploadData)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isUploading = false
                switch completion {
                case .failure(let error):
                    self?.uploadResultMessage = "Error uploading photo: \(error.localizedDescription)"
                    print("Ошибка при отправке фотографии: \(error)")
                case .finished:
                    self?.uploadResultMessage = "Photo uploaded successfully"
                    print("Фото успешно загружено!")
                    
                    // После успешной загрузки повторно загружаем данные с сервера, чтобы обновить список
                    self?.loadData()
                }
            }, receiveValue: { [weak self] progress in
                let normalizedProgress = min(max(progress, 0.0), 1.0)
                self?.uploadProgress = normalizedProgress
                print("Текущий прогресс загрузки: \(normalizedProgress)")
            })
            .store(in: &cancellables)
    }
    // Проверка разрешения на использование камеры
    func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async {
                self.showCamera = true
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.showCamera = granted
                    self?.cameraAccessDenied = !granted
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.cameraAccessDenied = true
            }
        @unknown default:
            break
        }
    }
    // Симуляция секундной загрузки данных для Pull-to-Refresh
    func simulateDataLoad() async {
        print("Симуляция Pull-to-Refresh начата")
        await Task.sleep(1 * 1_000_000_000) // 1 секунда задержки
        DispatchQueue.main.async {
            self.loadData() // Загружаем данные после симуляции задержки
        }
    }
    
}
