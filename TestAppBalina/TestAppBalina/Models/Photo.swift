//
//  Photo.swift
//  TestAppBalina
//
//  Created by Alexandr Filovets on 23.10.24.
//

import UIKit

// MARK: Response model

struct PhotoType: Identifiable, Codable {
    let id: Int
    let name: String
    let image: String?
}

struct PhotoTypeResponse: Codable {
    let page: Int
    let pageSize: Int
    let totalPages: Int
    let totalElements: Int
    let content: [PhotoType]
}

// MARK: - POST model

struct PhotoUploadData {
    let name: String
    let photo: UIImage
    let typeId: Int
}
