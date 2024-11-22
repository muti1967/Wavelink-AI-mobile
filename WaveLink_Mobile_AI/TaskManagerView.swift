import SwiftUI
import AVFoundation
import UIKit

struct TaskManagerView: View {
    // LOTS and lots of state variables lol
    @State private var students: [Student] = [] // Start with an empty array
    @State private var taskName: String = ""
    @State private var taskDescription: String = ""
    @State private var selectedStudents: Set<UUID> = []
    @State private var taskTime: Date = Date()
    @State private var newStudentName: String = ""
    @State private var newPiUser: String = ""
    @State private var newPiHost: String = ""
    @State private var newIP: String = ""
    @State private var newPiNumber: String = ""
    @State private var newPiPassword: String = "" // New property for the password
    @State private var showAddStudentSheet: Bool = false // Changed from showAddStudentAlert
    @State private var showEditStudentSheet: Bool = false
    @State private var studentToEdit: Student?
    @State private var studentToDelete: Student?
    @State private var showDeleteConfirmation: Bool = false
    @State private var audioRecorder: AVAudioRecorder?
    @State private var isRecording: Bool = false
    @State private var audioFilePath: URL?
    @State private var isAudioRecorded: Bool = false
    @State private var showTextFileView: Bool = false
    @State private var textFileContent: String = ""
    @State private var isSending: Bool = false
    @State private var activeAlert: ActiveAlert?
    @State private var showAlert: Bool = false

    // Enum to manage multiple alerts
    enum ActiveAlert {
        case textFileAlert
        case sendingConfirmation
    }

    private let audioRecorderDelegate = AudioRecorderDelegate()

    init() {
        loadStudents() // Load students when the view is initialized
    }

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    Form {
                        Section(header: Text("Task Details")) {
                            TextField("Task Name", text: $taskName)
                            TextField("Task Description", text: $taskDescription)
                            HStack {
                                Text("Task Time:")
                                Spacer()
                                DatePicker("", selection: $taskTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .frame(maxWidth: 150)
                            }
                            HStack {
                                Button(action: {
                                    if isRecording {
                                        stopRecording()
                                    } else if isAudioRecorded {
                                        // Prompt the user to confirm re-recording
                                        confirmReRecording()
                                    } else {
                                        startRecording()
                                    }
                                }) {
                                    if isRecording {
                                        Text("Stop Recording")
                                            .padding()
                                            .background(Color.red)
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                    } else if isAudioRecorded {
                                        Image(systemName: "checkmark.circle.fill")
                                            .resizable()
                                            .frame(width: 30, height: 30)
                                            .foregroundColor(.green)
                                    } else {
                                        Text("Record Audio")
                                            .padding()
                                            .background(Color.blue)
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                    }
                                }
                            }
                        }
                    }

                    List {
                        ForEach(students) { student in
                            HStack {
                                Text(student.name)
                                Spacer()
                                if selectedStudents.contains(student.id) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                toggleStudentSelection(student)
                            }
                            .swipeActions {
                                // Delete action (appears to the right)
                                Button("Delete", role: .destructive) {
                                    studentToDelete = student
                                    showDeleteConfirmation = true
                                }
                                .tint(.red)

                                // Edit action (appears to the left)
                                Button("Edit") {
                                    studentToEdit = student
                                    newStudentName = student.name
                                    newPiUser = student.piUser
                                    newPiHost = student.piHost
                                    newIP = student.ip
                                    newPiNumber = student.piNumber
                                    newPiPassword = student.piPassword
                                    showEditStudentSheet = true
                                }
                                .tint(.blue)
                            }
                        }
                    }

                    // HStack to align all four buttons side-by-side
                    HStack {
                        Button(action: assignTask) {
                            Text("Assign Task")
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }

                        Spacer() // Add space between the buttons

                        Button(action: {
                            sendTasksToDevices()
                        }) {
                            Text("Send To Device(s)")
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }

                        Spacer() // Add space between the buttons

                        Button(action: {
                            newStudentName = ""
                            newPiUser = ""
                            newPiHost = ""
                            newIP = ""
                            newPiNumber = ""
                            newPiPassword = ""
                            showAddStudentSheet = true // Changed to showAddStudentSheet
                        }) {
                            Text("Add Student")
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }

                        Spacer() // Add space between the buttons

                        NavigationLink(destination: StudentTasksView(students: $students)) {
                            Text("View and Edit Tasks")
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal) // Add horizontal padding to the HStack

                    // Confirmation Dialog for deleting student
                    .confirmationDialog("Are you sure you want to delete this student?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                        Button("Delete", role: .destructive) {
                            if let student = studentToDelete {
                                deleteStudent(student)
                            }
                        }
                        Button("Cancel", role: .cancel, action: {})
                    }
                }
                // Loading indicator
                if isSending {
                    VStack {
                        Text("Sending...")
                            .font(.headline)
                            .padding()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.5)
                            .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.4))
                    .edgesIgnoringSafeArea(.all)
                }
            }
            .navigationTitle("Task Manager")
            .onAppear {
                loadStudents() // Load students when the view appears
            }
            .onChange(of: students) { _ in
                saveStudents() // Save students whenever the array changes
            }
            // Single alert to handle multiple cases
            .alert(isPresented: $showAlert) {
                switch activeAlert {
                case .textFileAlert:
                    return Alert(
                        title: Text("File Created"),
                        message: Text("Do you want to view the text file?"),
                        primaryButton: .default(Text("View")) {
                            showTextFileView = true // Show the sheet with the text file content
                        },
                        secondaryButton: .cancel(Text("Send")) {
                            startSendingProcess()
                        }
                    )
                case .sendingConfirmation:
                    return Alert(
                        title: Text("Success"),
                        message: Text("The file has been sent successfully."),
                        dismissButton: .default(Text("OK"))
                    )
                case .none:
                    return Alert(title: Text("Error"), message: Text("An unexpected error occurred."), dismissButton: .default(Text("OK")))
                }
            }
            // Sheets
            .sheet(isPresented: $showAddStudentSheet) {
                VStack {
                    Text("Add New Student")
                        .font(.headline)
                        .padding()

                    TextField("Student Name", text: $newStudentName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    TextField("Pi User", text: $newPiUser)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    TextField("Pi Host", text: $newPiHost)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    TextField("IP", text: $newIP)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    TextField("Pi Number", text: $newPiNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    SecureField("Pi Password", text: $newPiPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    HStack {
                        Button("Add") {
                            addStudent()
                            showAddStudentSheet = false
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)

                        Button("Cancel") {
                            showAddStudentSheet = false
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
            .sheet(isPresented: $showEditStudentSheet) {
                VStack {
                    Text("Edit Student")
                        .font(.headline)
                        .padding()

                    TextField("Student Name", text: $newStudentName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    TextField("Pi User", text: $newPiUser)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    TextField("Pi Host", text: $newPiHost)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    TextField("IP", text: $newIP)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    TextField("Pi Number", text: $newPiNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    SecureField("Pi Password", text: $newPiPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    HStack {
                        Button("Save") {
                            editStudent()
                            showEditStudentSheet = false
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)

                        Button("Cancel") {
                            showEditStudentSheet = false
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
            .sheet(isPresented: $showTextFileView) {
                VStack {
                    Text("Text File Content")
                        .font(.headline)
                        .padding()

                    ScrollView {
                        Text(textFileContent)
                            .padding()
                    }

                    Button(action: {
                        showTextFileView = false
                        startSendingProcess()
                    }) {
                        Text("Send")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                }
            }
        }
    }

    func toggleStudentSelection(_ student: Student) {
        if selectedStudents.contains(student.id) {
            selectedStudents.remove(student.id)
        } else {
            selectedStudents.insert(student.id)
        }
    }

    func assignTask() {
        guard !taskName.isEmpty, !taskDescription.isEmpty else { return }

        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let timeString = formatter.string(from: taskTime)

        for studentID in selectedStudents {
            if let index = students.firstIndex(where: { $0.id == studentID }) {
                let newTask = Task(
                    name: taskName,
                    number: students[index].taskCount,
                    time: timeString,
                    description: taskDescription,
                    audioFilePath: audioFilePath?.path // Save the audio file path
                )

                // Verify the audio file exists
                if let path = audioFilePath?.path, FileManager.default.fileExists(atPath: path) {
                    print("Audio file saved at: \(path)")
                } else {
                    print("Audio file was not saved or does not exist.")
                }

                students[index].tasks.append(newTask)
                students[index].taskCount += 1
            }
        }

        // Reset task fields
        taskName = ""
        taskDescription = ""
        selectedStudents.removeAll()
        audioFilePath = nil
        isAudioRecorded = false // Reset the audio recorded state
    }

    func addStudent() {
        guard !newStudentName.isEmpty else { return }
        let newStudent = Student(
            name: newStudentName,
            piUser: newPiUser,
            piHost: newPiHost,
            ip: newIP,
            piNumber: newPiNumber,
            piPassword: newPiPassword // Save the password
        )
        students.append(newStudent)
        newStudentName = ""
        newPiUser = ""
        newPiHost = ""
        newIP = ""
        newPiNumber = ""
        newPiPassword = "" // Reset the password field
    }

    func editStudent() {
        guard let student = studentToEdit, !newStudentName.isEmpty else { return }
        if let index = students.firstIndex(where: { $0.id == student.id }) {
            students[index].name = newStudentName
            students[index].piUser = newPiUser
            students[index].piHost = newPiHost
            students[index].ip = newIP
            students[index].piNumber = newPiNumber
            students[index].piPassword = newPiPassword // Update the password field
        }
        studentToEdit = nil
        newStudentName = ""
        newPiUser = ""
        newPiHost = ""
        newIP = ""
        newPiNumber = ""
        newPiPassword = "" // Reset the password field
    }

    func deleteStudent(_ student: Student) {
        students.removeAll { $0.id == student.id }
    }

    // MARK: - Audio Recording Methods
    func startRecording() {
        // Remove existing audio file if re-recording
        if isAudioRecorded, let existingAudioPath = audioFilePath {
            do {
                try FileManager.default.removeItem(at: existingAudioPath)
                print("Old audio file deleted.")
            } catch {
                print("Failed to delete old audio file: \(error.localizedDescription)")
            }
            audioFilePath = nil
        }

        let fileName = UUID().uuidString + ".m4a"
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let audioURL = documentPath.appendingPathComponent(fileName)
        audioFilePath = audioURL

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            // Configure the audio session
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            // Initialize and start the recorder
            audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            audioRecorder?.delegate = audioRecorderDelegate // Assign the delegate

            // Set up the closure to handle recording completion
            audioRecorderDelegate.onFinishRecording = { success in
                DispatchQueue.main.async {
                    if success {
                        print("Recording finished successfully.")
                        self.isAudioRecorded = true
                    } else {
                        print("Recording failed.")
                        self.isAudioRecorded = false
                        // Handle failure (e.g., show an alert)
                    }
                }
            }

            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
            isRecording = true
        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false

        // Deactivate the audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error.localizedDescription)")
        }

        // Set audio recorded state
        isAudioRecorded = true
    }

    func confirmReRecording() {
        let alert = UIAlertController(title: "Re-record Audio", message: "Do you want to replace the existing audio recording?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Re-record", style: .destructive, handler: { _ in
            self.startRecording()
        }))

        // Present the alert
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true, completion: nil)
        }
    }

    // MARK: - Data Persistence Methods
    func saveStudents() {
        if let encodedData = try? JSONEncoder().encode(students) {
            UserDefaults.standard.set(encodedData, forKey: "students")
        }
    }

    func loadStudents() {
        if let savedData = UserDefaults.standard.data(forKey: "students"),
           let decodedStudents = try? JSONDecoder().decode([Student].self, from: savedData) {
            students = decodedStudents
        }
    }

    // This is gonna be the long one, it will save the txt file then send it to the devices.
    func sendTasksToDevices() {
        print("Preparing to send tasks to devices...")

        // Prepare the content of the text file
        var fileContent = ""

        for student in students {
            // Student info
            let studentInfo = [
                student.name,
                student.piUser,
                student.piHost,
                student.ip,
                student.piPassword,
                student.piNumber
            ]
            // Join student info with commas
            let studentInfoLine = studentInfo.joined(separator: ",")

            // Prepare tasks info
            var tasksInfo = ""
            for task in student.tasks {
                let taskInfo = [
                    "\(task.number)",
                    task.name,
                    task.audioFilePath ?? "",
                    task.time
                ]
                // Join task info with commas
                let taskInfoLine = taskInfo.joined(separator: ",")
                // Append task info to tasksInfo string
                tasksInfo += "," + taskInfoLine
            }

            // Combine student info and tasks info
            let studentLine = studentInfoLine + tasksInfo + "\n"
            // Append to fileContent
            fileContent += studentLine
        }

        // Save the fileContent to a text file
        let fileName = "students_tasks.txt"
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentsDirectory.appendingPathComponent(fileName)

            do {
                // Write the content to the file
                try fileContent.write(to: fileURL, atomically: true, encoding: .utf8)
                print("File saved successfully at \(fileURL.path)")
                // Update the state variables
                textFileContent = fileContent
                activeAlert = .textFileAlert
                showAlert = true
            } catch {
                print("Error writing file: \(error.localizedDescription)")
            }
        } else {
            print("Unable to access documents directory")
        }
    }

    func startSendingProcess() {
        isSending = true
        // Simulate a delay to represent the sending process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isSending = false
            activeAlert = .sendingConfirmation
            showAlert = true
        }
    }

    // Will incorporate this later
    func sendFileToDevices(fileURL: URL) {
        // For example, use URLSession for HTTP requests
        // Or use external libraries for SSH/SFTP transfers
        // i dont know if i should use http , ssh, sftp, or bluetooth..
    }
}
