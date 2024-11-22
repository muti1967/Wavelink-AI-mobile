import SwiftUI
import Foundation

struct TaskRow: View {
    @ObservedObject var task: Task
    @Binding var currentlyPlayingTaskID: UUID?
    var handleAudioPlayback: (Task, String) -> Void
    var editTaskAction: (Task) -> Void
    var deleteTaskAction: (Task) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text(task.name).font(.headline)
            Text("Task Number: \(task.number)")
            Text("Time: \(task.time)")
            Text("Description: \(task.description)")

            // Play/Pause Button
            if let audioFilePath = task.audioFilePath {
                Button(action: {
                    handleAudioPlayback(task, audioFilePath)
                }) {
                    Image(systemName: currentlyPlayingTaskID == task.id ? "pause.circle" : "play.circle")
                        .resizable()
                        .frame(width: 30, height: 30)
                }
                .padding(.top, 5)
            }
        }
        .contentShape(Rectangle())
        .swipeActions {
            // Edit action
            Button("Edit") {
                editTaskAction(task)
            }
            .tint(.blue)

            // Delete action
            Button("Delete", role: .destructive) {
                deleteTaskAction(task)
            }
            .tint(.red)
        }
    }
}
