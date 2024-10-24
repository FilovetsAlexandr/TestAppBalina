//
//  MainView.swift
//  TestAppBalina
//
//  Created by Alexandr Filovets on 23.10.24.
//

import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = MainViewModel()
    @State private var selectedPhotoTypeId: Int? = nil // Для хранения выбранного typeId
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isUploading {
                    VStack {
                        Text("Uploading photo...")
                        if let resultMessage = viewModel.uploadResultMessage {
                            Text(resultMessage)
                                .foregroundColor(resultMessage.contains("Error") ? .red : .green)
                                .padding()
                                .onAppear {
                                    // Скрываем сообщение через 2 секунды
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        viewModel.uploadResultMessage = nil
                                    }
                                }
                        }
                    }
                    .padding()
                } else if let resultMessage = viewModel.uploadResultMessage {
                    Text(resultMessage)
                        .foregroundColor(resultMessage.contains("Error") ? .red : .green)
                        .padding()
                        .hidden()
                }
                
                List {
                    // Отображаем все элементы, которые были загружены
                    ForEach(viewModel.photoTypes) { photoType in
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
                                    selectedPhotoTypeId = photoType.id // Сохраняем ID выбранного элемента
                                    viewModel.checkCameraPermission() // Проверяем разрешение на использование камеры
                                }
                        }
                    }
                    
                    if viewModel.isLoading {
                        ProgressView()
                    } else if !viewModel.isLastPage {
                        Text("Load more...")
                            .onAppear {
                                viewModel.loadData() // Подгружаем данные
                            }
                    }
                }
            }
            .navigationTitle("Photo Types Balinasoft")
            .onAppear {
                viewModel.loadData() // Загружаем данные при первом появлении
            }
            .sheet(isPresented: $viewModel.showCamera) {
                CameraView(image: $viewModel.capturedImage) // Передаем capturedImage через Binding
                    .onDisappear {
                        if let image = viewModel.capturedImage {
                            print("Изображение захвачено: \(image)") // Если изображение захвачено
                        } else {
                            print("Изображение не захвачено") // Если изображение не захвачено
                        }

                        if let selectedId = selectedPhotoTypeId {
                            print("Идентификатор выбранного элемента: \(selectedId)") // Принт для отладки ID
                            viewModel.uploadPhoto(typeId: selectedId, name: "Filovets Alexandr Vladimirovich")
                        } else {
                            print("Не выбран элемент для загрузки") // Принт для отладки ID
                        }
                    }
            }
            .alert(isPresented: $viewModel.cameraAccessDenied) {
                Alert(title: Text("Camera Access Denied"), message: Text("Please enable camera access in Settings."), dismissButton: .default(Text("OK")))
            }
            // Добавляем pull-to-refresh
            .refreshable {
                await viewModel.simulateDataLoad() // Используем метод для обновления данных
            }
        }
    }
}
