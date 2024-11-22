import SwiftUI
import AVFoundation
import Foundation

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
                    // **First ForEach loop over students**
                    ForEach(students) { student in
                        Section(header: Text(student.name)) {
                            // **Second ForEach loop over tasks**
                            ForEach(student.tasks) { task in
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
                                        if let studentIndex = students.firstIndex(where: { $0.id == student.id }),
                                           let taskIndex = students[studentIndex].tasks.firstIndex(where: { $0.id == task.id }) {
                                            deleteTask(at: taskIndex, for: studentIndex)
                                        }
                                    }
                                    .tint(.red)
                                }
                            }
                            .onDelete { indices in
                                if let studentIndex = students.firstIndex(where: { $0.id == student.id }) {
                                    deleteTask(atOffsets: indices, for: studentIndex)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Edit Tasks")
                .navigationBarItems(
                    leading: Button(action: createDebugData) {
                        Image(systemName: "ladybug")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.blue)
                    },
                    trailing: Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.red)
                    }
                )
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

    // Debug button function
    func createDebugData() {
        // Clear existing students
        students.removeAll()

        // Create default students
        let student1 = Student(
            name: "Student 1",
            tasks: [
                Task(name: "Task 1", number: 1, time: "9:00 AM", description: "First task for Student 1"),
                Task(name: "Task 2", number: 2, time: "10:00 AM", description: "Second task for Student 1"),
                Task(name: "Task 3", number: 3, time: "11:00 AM", description: "Third task for Student 1")
            ],
            taskCount: 3 // Number of tasks
        )

        let student2 = Student(
            name: "Student 2",
            tasks: [
                Task(name: "Task 1", number: 1, time: "12:00 PM", description: "First task for Student 2"),
                Task(name: "Task 2", number: 2, time: "1:00 PM", description: "Second task for Student 2"),
                Task(name: "Task 3", number: 3, time: "2:00 PM", description: "Third task for Student 2")
            ],
            taskCount: 3 // Number of tasks
        )

        // Add students to the list
        students.append(student1)
        students.append(student2)
    }

    // Function to delete a task
    func deleteTask(at index: Int, for studentIndex: Int) {
        // Remove the task at the given index
        students[studentIndex].tasks.remove(at: index)
        students[studentIndex].taskCount -= 1 // Decrement the task count

        // Adjust task numbers for tasks beyond the deleted index
        for i in index..<students[studentIndex].tasks.count {
            students[studentIndex].tasks[i].number -= 1
        }
    }

    func deleteTask(atOffsets offsets: IndexSet, for studentIndex: Int) {
        // Sort offsets in descending order to prevent index shifting issues
        let sortedOffsets = offsets.sorted(by: >)

        // Remove tasks at the specified offsets
        for offset in sortedOffsets {
            students[studentIndex].tasks.remove(at: offset)
        }
        students[studentIndex].taskCount = students[studentIndex].tasks.count // Update task count

        // Renumber all tasks to ensure proper ordering
        for i in 0..<students[studentIndex].tasks.count {
            students[studentIndex].tasks[i].number = i + 1
        }
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
            audioPlayer?.pause()
            currentlyPlayingTaskID = nil
        } else {
            audioPlayer?.stop()
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
                audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
                audioPlayer?.play()
                currentlyPlayingTaskID = task.id
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
        for (index, _) in students[studentIndex].tasks.enumerated() {
            students[studentIndex].tasks[index].number = index + 1 // Assign 1-based task numbers
        }
        print("Updated Task Numbers:", students[studentIndex].tasks.map { $0.number })
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

    func addNewTask(to studentIndex: Int, task: Task) {
        students[studentIndex].tasks.append(task)
        students[studentIndex].taskCount += 1 // Increment task count
    }

    // Helper function to parse time string into Date
    func parseTimeString(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.date(from: timeString)
    }
}
