import SwiftUI
import UIKit
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject private var supabaseService: SupabaseService
    @Environment(\.presentationMode) var presentationMode
    
    @State private var username: String = ""
    @State private var avatarUrl: String = ""
    @State private var isUpdating: Bool = false
    @State private var errorMessage: String = ""
    @State private var showSuccess: Bool = false
    @State private var isImagePickerPresented = false
    @State private var selectedImage: UIImage? = nil
    @State private var isUploadingImage = false
    
    // Animation properties
    @State private var pulsate: Bool = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("PROFILE INFORMATION")) {
                    HStack {
                        Spacer()
                        
                        // Avatar/profile image with upload button
                        VStack {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 120, height: 120)
                                    .scaleEffect(pulsate ? 1.05 : 1.0)
                                    .animation(
                                        Animation.easeInOut(duration: 1.5)
                                            .repeatForever(autoreverses: true),
                                        value: pulsate
                                    )
                                
                                if let image = selectedImage {
                                    // Display the selected image from photo picker
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                } else if let user = supabaseService.authService.currentUser {
                                    // Use our custom ProfileImageView
                                    ProfileImageView(
                                        user: user,
                                        size: 100,
                                        supabaseService: supabaseService
                                    )
                                } else {
                                    // Default icon if no user
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 100, height: 100)
                                        .foregroundColor(.blue)
                                }
                                
                                // Show spinner when uploading
                                if isUploadingImage {
                                    ZStack {
                                        Circle()
                                            .fill(Color.black.opacity(0.5))
                                            .frame(width: 100, height: 100)
                                        
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(1.5)
                                    }
                                }
                            }
                            .padding(.vertical, 10)
                            
                            // Button to change profile picture
                            Button(action: { isImagePickerPresented = true }) {
                                Label("Change Picture", systemImage: "photo")
                                    .font(.footnote)
                                    .foregroundColor(.blue)
                            }
                            .disabled(isUploadingImage || isUpdating)
                            .sheet(isPresented: $isImagePickerPresented) {
                                PhotoPicker(selectedImage: $selectedImage)
                            }
                            .onChange(of: selectedImage) { newImage in
                                if newImage != nil {
                                    uploadProfileImage()
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    
                    TextField("Username", text: $username)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding(.vertical, 5)
                    }
                    
                    if showSuccess {
                        Text("Profile updated successfully!")
                            .foregroundColor(.green)
                            .padding(.vertical, 5)
                    }
                }
                
                Section {
                    Button(action: updateProfile) {
                        if isUpdating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            Text("Update Profile")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .foregroundColor(.blue)
                        }
                    }
                    .disabled(isUpdating || username.isEmpty)
                    
                    Button(action: signOut) {
                        Text("Sign Out")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundColor(.red)
                    }
                    .disabled(isUpdating)
                }
            }
            .navigationTitle("Your Profile")
            .onAppear {
                if let user = supabaseService.authService.currentUser {
                    username = user.username
                    avatarUrl = user.avatarUrl ?? ""
                    pulsate = true
                }
            }
        }
    }
    
    private func updateProfile() {
        guard !username.isEmpty else { return }
        
        isUpdating = true
        errorMessage = ""
        showSuccess = false
        
        Task {
            do {
                try await supabaseService.authService.updateUserProfile(
                    username: username,
                    avatarUrl: avatarUrl.isEmpty ? nil : avatarUrl
                )
                
                await MainActor.run {
                    showSuccess = true
                    
                    // Hide success message after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showSuccess = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to update profile: \(error.localizedDescription)"
                }
            }
            
            await MainActor.run {
                isUpdating = false
            }
        }
    }
    
    private func signOut() {
        Task {
            do {
                try await supabaseService.authService.signOut()
                await MainActor.run {
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to sign out: \(error.localizedDescription)"
                }
            }
        }
    }
    
    /// Upload the selected profile image to Supabase Storage
    private func uploadProfileImage() {
        guard let image = selectedImage else { return }
        
        isUploadingImage = true
        errorMessage = ""
        
        // Resize image if needed and convert to JPEG data
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            errorMessage = "Failed to process image data"
            isUploadingImage = false
            return
        }
        
        // Upload to Supabase Storage
        Task {
            do {
                // This will upload to storage and update the user profile in one go
                let updatedUser = try await supabaseService.updateUserWithNewAvatar(
                    imageData: imageData,
                    fileExtension: "jpg"
                )
                
                await MainActor.run {
                    // Update the avatar URL in the form
                    avatarUrl = updatedUser.avatarUrl ?? ""
                    
                    // Clear the selected image as it's now uploaded
                    selectedImage = nil
                    
                    // Show success message
                    showSuccess = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showSuccess = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to upload image: \(error.localizedDescription)"
                }
            }
            
            await MainActor.run {
                isUploadingImage = false
            }
        }
    }
}

/// SwiftUI wrapper for PHPickerViewController to select images
struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            guard let result = results.first else { return }
            
            result.itemProvider.loadObject(ofClass: UIImage.self) { (object, error) in
                if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image
                    }
                }
                
                if let error = error {
                    print("PhotoPicker error: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}