//
//  ContentView.swift
//  CustomDragDropImagePicker
//
//  Created by Amish Tufail on 02/02/2024.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    
    var body: some View {
        NavigationStack {
            VStack {
                ImagePicker(title: "Drag & Drop Image", subTitle: "Tap to add an Image", systemImage: "square.and.arrow.up", tint: .blue) { image in
                }
                .frame(maxWidth: 300, maxHeight: 250)
                .padding(.top, 30.0)
                Spacer()
            }
            .padding()
            .navigationTitle("Image Picker 🏞️")
        }
    }
}

#Preview {
    ContentView()
}

struct ImagePicker: View {
    var title: String
    var subTitle: String
    var systemImage: String
    var tint: Color
    var onImageChange: (UIImage) -> () // This is only to return back the image, just like we do in escaping closures
    
    @State private var showImagePicker: Bool = false
    @State private var photoItem: PhotosPickerItem?
    @State private var previewImage: UIImage?
    @State private var isLoading: Bool = false
    
    var body: some View {
        GeometryReader {
            let size = $0.size
            
            VStack(spacing: 4.0) {
                Image(systemName: systemImage)
                    .font(.largeTitle)
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text(title)
                    .font(.callout)
                    .padding(.top, 15.0)
                Text(subTitle)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            .opacity(previewImage == nil ? 1.0 : 0.0)
            .frame(width: size.width, height: size.height)
            // Displaying Preview
            .overlay {
                if let previewImage {
                    Image(uiImage: previewImage)
                        .resizable()
                        .scaledToFit()
                        .clipShape(.rect)
                        .padding(15.0)
                }
            }
            // Displaying Loader
            .overlay {
                if isLoading {
                    ProgressView()
                        .padding(10.0)
                        .background(.ultraThinMaterial, in: .rect(cornerRadius: 5.0))
                }
            }
            .animation(.snappy, value: isLoading)
            .animation(.snappy, value: previewImage)
            .dropDestination(for: Data.self, action: { items, location in
                if let firstItem = items.first, let droppedImage = UIImage(data: firstItem) {
                    previewImage = droppedImage // Using this, it causes immense memory usage, to avoid this we create thumbnail of image and will use that
                    generateImageThumbnail(droppedImage, size) // We use this now
                    // Sending back the image
                    onImageChange(droppedImage)
                    return true
                }
                return false
            }, isTargeted: { _ in
                
            })
            .contentShape(.rect)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 15.0)
                        .fill(tint.opacity(0.08).gradient)
                    RoundedRectangle(cornerRadius: 15.0)
                        .stroke(tint, style: .init(lineWidth: 1, dash: [12]))
                        .padding(1)
                }
            }
        }
    }
    
    func generateImageThumbnail(_ image: UIImage, _ size: CGSize) {
        isLoading = true
        Task.detached {
            let thumbnailImage = await image.byPreparingThumbnail(ofSize: size)
            await MainActor.run {
                previewImage = thumbnailImage
                isLoading = false
            }
        }
    }
}
