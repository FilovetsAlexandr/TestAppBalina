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
}
