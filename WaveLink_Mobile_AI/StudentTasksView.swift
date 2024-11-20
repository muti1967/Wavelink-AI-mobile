import SwiftUI
import AVFoundation

struct StudentTasksView: View {
    @Binding var students: [Student]
    @State private var showEditTaskAlert: Bool = false
    @State private var taskToEdit: Task? = nil
    @State private var editedTaskName: String = ""
    @State private var editedTaskDescription: String = ""
    @State private var editedTaskTime: Date = Date()
    @State private var currentlyPlayingTaskID: UUID? = nil
    @State private var audioRecorder: AVAudioRecorder? = nil
    @State private var isRecording: Bool = false
    @State private var updatedAudioFilePath: URL? = nil
    @State private var showDeleteConfirmation: Bool = false
    @State private var audioPlayer: AVAudioPlayer? = nil

    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(students) { student in
                        Section(header: Text(student.name)) {
                            ForEach(student.tasks.indices, id: \.self) { index in
                                let task = students[students.firstIndex(where: { $0.id == student.id })!].tasks[index]
                                VStack(alignment: .leading) {
                                    Text(task.name).font(.headline)
                                    Text("Task Number: \(task.number)")
                                    Text("Time: \(task.time)")
                                    Text("Description: \(task.description)")

                                    // Play/Pause Button
                                    if let audioFilePath = task.audioFilePath {
                                        Button(action: {
                                            handleAudioPlayback(for: task, with: audioFilePath)
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
                                        taskToEdit = task
                                        editedTaskName = task.name
                                        editedTaskDescription = task.description
                                        if let date = parseTimeString(task.time) {
                                            editedTaskTime = date
                                        }
                                        updatedAudioFilePath = nil
                                        showEditTaskAlert = true
                                    }
                                    .tint(.blue)

                                    // Delete action
                                    Button("Delete", role: .destructive) {
                                        if let studentIndex = students.firstIndex(where: { $0.id == student.id }) {
                                            deleteTask(at: index, for: studentIndex)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Edit Tasks")
                .navigationBarItems(trailing: Button(action: {
                    showDeleteConfirmation = true
                }) {
                    Image(systemName: "trash")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.red)
                })
                .alert(isPresented: $showDeleteConfirmation) {
                    Alert(
                        title: Text("Delete All Data"),
                        message: Text("Are you sure you want to delete all data associated with this app? This action cannot be undone."),
                        primaryButton: .destructive(Text("Delete")) {
                            deleteAllData()
                        },
                        secondaryButton: .cancel()
                    )
                }
                .sheet(isPresented: $showEditTaskAlert) {
                    VStack {
                        Text("Edit Task")
                            .font(.headline)
                            .padding()

                        TextField("Task Name", text: $editedTaskName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()

                        TextField("Task Description", text: $editedTaskDescription)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()

                        DatePicker("Edit Time", selection: $editedTaskTime, displayedComponents: .hourAndMinute)
                            .padding()

                        // Audio Recording Button
                        Button(action: {
                            if isRecording {
                                stopRecording()
                            } else {
                                startRecording()
                            }
                        }) {
                            Text(isRecording ? "Stop Recording" : "Re-record Audio")
                                .padding()
                                .background(isRecording ? Color.red : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding()

                        HStack {
                            Button("Save") {
                                saveTaskEdits()
                                showEditTaskAlert = false
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)

                            Button("Cancel") {
                                showEditTaskAlert = false
                            }
                            .padding()
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding()
                    }
                    .padding()
                }
            }
        }
    }

    // Function to delete a task
    func deleteTask(at index: Int, for studentIndex: Int) {
        students[studentIndex].tasks.remove(at: index)
        updateTaskNumbers(for: studentIndex)
    }

    // Function to handle audio playback
    func handleAudioPlayback(for task: Task, with audioFilePath: String) {
        let audioURL = URL(fileURLWithPath: audioFilePath)

        // Check if the file exists
        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            print("Audio file does not exist at path: \(audioURL.path)")
            return
        }

        if currentlyPlayingTaskID == task.id {
            // If the audio is already playing, pause it
            audioPlayer?.pause()
            currentlyPlayingTaskID = nil
        } else {
            // Stop any currently playing audio
            audioPlayer?.stop()

            do {
                // Set up the audio session for playback
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)

                // Initialize and play the audio
                audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
                audioPlayer?.play()
                currentlyPlayingTaskID = task.id

                // Debugging output
                print("Playing audio from: \(audioURL.path)")
            } catch {
                print("Failed to play audio: \(error)")
            }
        }
    }

    // Function to delete all data
    func deleteAllData() {
        students.removeAll()
        UserDefaults.standard.removeObject(forKey: "students")

        let fileManager = FileManager.default
        if let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            do {
                let fileURLs = try fileManager.contentsOfDirectory(at: documentDirectory, includingPropertiesForKeys: nil)
                for fileURL in fileURLs {
                    try fileManager.removeItem(at: fileURL)
                }
            } catch {
                print("Failed to delete audio files: \(error)")
            }
        }
    }

    // Function to start recording audio
    func startRecording() {
        let fileName = UUID().uuidString + ".m4a"
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let audioURL = documentPath.appendingPathComponent(fileName)
        updatedAudioFilePath = audioURL

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
            isRecording = true
        } catch {
            print("Failed to start recording: \(error)")
        }
    }

    // Function to stop recording audio
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
    }

    // Function to update task numbers after deletion
    func updateTaskNumbers(for studentIndex: Int) {
        for index in students[studentIndex].tasks.indices {
            students[studentIndex].tasks[index].number = index + 1
        }
    }

    // Function to save task edits
    func saveTaskEdits() {
        guard let taskToEdit = taskToEdit else { return }

        for studentIndex in students.indices {
            if let taskIndex = students[studentIndex].tasks.firstIndex(where: { $0.id == taskToEdit.id }) {
                students[studentIndex].tasks[taskIndex].name = editedTaskName
                students[studentIndex].tasks[taskIndex].description = editedTaskDescription

                let formatter = DateFormatter()
                formatter.timeStyle = .short
                students[studentIndex].tasks[taskIndex].time = formatter.string(from: editedTaskTime)

                if let newAudioPath = updatedAudioFilePath?.path {
                    students[studentIndex].tasks[taskIndex].audioFilePath = newAudioPath
                }
                break
            }
        }
        self.taskToEdit = nil
    }

    // Helper function to parse time string into Date
    func parseTimeString(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.date(from: timeString)
    }
}
