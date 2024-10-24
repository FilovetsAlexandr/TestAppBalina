//
//  PhotoTypeService.swift
//  TestAppBalina
//
//  Created by Alexandr Filovets on 23.10.24.
//

import Foundation
import Combine

class PhotoTypeService {
    private let baseURL: String = "https://junior.balinasoft.com/"
    private var cache: [Int: PhotoTypeResponse] = [:] // Кеш
    private var cancellables = Set<AnyCancellable>()
    // Функция для получения данных (GET) (с поддержкой кеширования)
    func fetchPhotoTypes(page: Int) -> AnyPublisher<PhotoTypeResponse, Error> {
        // Проверяем кэш, если данные уже загружены для этой страницы
        if let cachedResponse = cache[page] {
            return Just(cachedResponse)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        // Собираем URL
        guard let url = URL(string: "\(baseURL)api/v2/photo/type?page=\(page)") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        // Выполняем сетевой запрос
        return URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { output in
                guard let response = output.response as? HTTPURLResponse, response.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return output.data
            }
            .decode(type: PhotoTypeResponse.self, decoder: JSONDecoder())
            .handleEvents(receiveOutput: { [weak self] response in
                self?.cache[page] = response // Кэшируем ответ
            })
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // Функция для очистки кэша
    func clearCache() {
        cache.removeAll()
    }
    
    // Пример POST-запроса
    func sendPhotoTypeData(photoType: PhotoType) -> AnyPublisher<Void, Error> {
        guard let url = URL(string: "\(baseURL)api/v2/photo/type") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let bodyData = try? JSONEncoder().encode(photoType)
        request.httpBody = bodyData
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { output in
                guard let response = output.response as? HTTPURLResponse, response.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return ()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // Функция для отправки фото и данных с помощью POST
       func uploadPhoto(with data: PhotoUploadData) -> AnyPublisher<Double, Error> {
           guard let url = URL(string: "\(baseURL)api/v2/photo") else {
               return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
           }
           
           var request = URLRequest(url: url)
           request.httpMethod = "POST"
           
           let boundary = UUID().uuidString
           request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
           
           // Формируем тело запроса
           var body = Data()
           
           // Добавляем имя
           body.append("--\(boundary)\r\n".data(using: .utf8)!)
           body.append("Content-Disposition: form-data; name=\"name\"\r\n\r\n".data(using: .utf8)!)
           body.append("\(data.name)\r\n".data(using: .utf8)!)
           
           // Добавляем typeId
           body.append("--\(boundary)\r\n".data(using: .utf8)!)
           body.append("Content-Disposition: form-data; name=\"typeId\"\r\n\r\n".data(using: .utf8)!)
           body.append("\(data.typeId)\r\n".data(using: .utf8)!)
           
           // Добавляем фото
           let imageData = data.photo.jpegData(compressionQuality: 0.8)!
           body.append("--\(boundary)\r\n".data(using: .utf8)!)
           body.append("Content-Disposition: form-data; name=\"photo\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
           body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
           body.append(imageData)
           body.append("\r\n".data(using: .utf8)!)
           
           body.append("--\(boundary)--\r\n".data(using: .utf8)!)
           request.httpBody = body
           
           return URLSession.shared.dataTaskPublisher(for: request)
               .tryMap { output in
                   guard let response = output.response as? HTTPURLResponse, response.statusCode == 200 else {
                       throw URLError(.badServerResponse)
                   }
                   return Double(imageData.count) / Double(output.response.expectedContentLength)
               }
               .receive(on: DispatchQueue.main)
               .eraseToAnyPublisher()
       }
}
