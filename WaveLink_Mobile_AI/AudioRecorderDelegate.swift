import Foundation
import AVFoundation

class AudioRecorderDelegate: NSObject, AVAudioRecorderDelegate {
    // Implement delegate methods if needed
    var onFinishRecording: ((Bool) -> Void)?

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            print("Recording finished successfully.")
        } else {
            print("Recording failed.")
        }
        // You can post notifications or update shared state if needed
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            print("Encoding error occurred: \(error.localizedDescription)")
        }
    }
}
