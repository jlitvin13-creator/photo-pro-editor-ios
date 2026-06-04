import Photos
import UIKit

final class PhotoLibraryService: NSObject {
    private var completion: ((Result<Void, Error>) -> Void)?

    func save(_ image: UIImage, completion: @escaping (Result<Void, Error>) -> Void) {
        self.completion = completion
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveFinished(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    @objc private func saveFinished(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error {
            completion?(.failure(error))
        } else {
            completion?(.success(()))
        }
        completion = nil
    }
}
