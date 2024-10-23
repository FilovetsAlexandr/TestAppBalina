//
//  MainView.swift
//  TestAppBalina
//
//  Created by Alexandr Filovets on 23.10.24.
//

import SwiftUI
import AVFoundation

struct MainView: View {
    @StateObject private var viewModel = MainViewModel()
    @State private var showCamera = false // Для отображения камеры
    @State private var cameraAccessDenied = false // Флаг для проверки доступа к камере

    var body: some View {
        NavigationView {
            List {
                // Разбиваем элементы по страницам и убираем пустые секции
                ForEach(1...viewModel.currentPage, id: \.self) { page in
                    let pageData = viewModel.photoTypesForPage(page: page)
                    if !pageData.isEmpty {
                        Section(header: Text("Page \(page)")) {
                            ForEach(pageData) { photoType in
                                HStack {
                                    if let imageUrlString = photoType.image, let imageUrl = URL(string: imageUrlString) {
                                        AsyncImage(url: imageUrl) { image in
                                            image.resizable().aspectRatio(contentMode: .fit)
                                        } placeholder: {
                                            ProgressView()
                                        }
                                        .frame(width: 50, height: 50)
                                    } else {
                                        // Показываем placeholder, если image = null или некорректный URL
                                        Image(systemName: "photo")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 50, height: 50)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Text(photoType.name)
                                        .onTapGesture {
                                            checkCameraPermission() // При нажатии на элемент проверяем разрешение и открываем камеру
                                        }
                                }
                            }
                        }
                    }
                }
                
                // Прогресс-индикатор для подгрузки данных внизу
                if viewModel.isLoading {
                    ProgressView()
                } else if !viewModel.isLastPage {
                    Text("Load more...")
                        .onAppear {
                            viewModel.loadData()
                        }
                }
            }
            .navigationTitle("Photo Types Balinasoft")
            .onAppear {
                viewModel.loadData()
            }
            .sheet(isPresented: $showCamera) {
                CameraView() // Показываем камеру
            }
            .alert(isPresented: $cameraAccessDenied) {
                Alert(
                    title: Text("Camera Access Denied"),
                    message: Text("Please enable camera access in Settings."),
                    dismissButton: .default(Text("OK"))
                )
            }
            // Добавляем pull-to-refresh
            .refreshable {
                await simulateDataLoad()
            }
        }
    }

    // Проверка разрешения на использование камеры
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // Камера разрешена
            showCamera = true
        case .notDetermined:
            // Запрос на разрешение
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        showCamera = true
                    }
                } else {
                    DispatchQueue.main.async {
                        cameraAccessDenied = true
                    }
                }
            }
        case .denied, .restricted:
            // Камера запрещена
            cameraAccessDenied = true
        @unknown default:
            break
        }
    }

    // Симуляция секундной загрузки данных для pull-to-refresh
    private func simulateDataLoad() async {
        await Task.sleep(1 * 1_000_000_000) // 1 секунда задержки
        viewModel.loadData()
    }
}
