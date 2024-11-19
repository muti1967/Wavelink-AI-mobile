import SwiftUI
import AVFoundation

struct TaskManagerView: View {
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
    @State private var showAddStudentAlert: Bool = false
    @State private var showEditStudentSheet: Bool = false
    @State private var studentToEdit: Student?
    @State private var studentToDelete: Student?
    @State private var showDeleteConfirmation: Bool = false
    @State private var audioRecorder: AVAudioRecorder?
    @State private var isRecording: Bool = false
    @State private var audioFilePath: URL?

    init() {
        loadStudents() // Load students when the view is initialized
    }

    var body: some View {
        NavigationView {
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
                                } else {
                                    startRecording()
                                }
                            }) {
                                Text(isRecording ? "Stop Recording" : "Record Audio")
                                    .padding()
                                    .background(isRecording ? Color.red : Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
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
                                showEditStudentSheet = true
                            }
                            .tint(.blue)
                        }
                    }
                }

                Button(action: assignTask) {
                    Text("Assign Task")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()

                Button(action: {
                    newStudentName = ""
                    newPiUser = ""
                    newPiHost = ""
                    newIP = ""
                    newPiNumber = ""
                    showAddStudentAlert = true
                }) {
                    Text("Add Student")
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
                .alert("Add New Student", isPresented: $showAddStudentAlert) {
                    VStack {
                        TextField("Student Name", text: $newStudentName)
                        TextField("Pi User", text: $newPiUser)
                        TextField("Pi Host", text: $newPiHost)
                        TextField("IP", text: $newIP)
                        TextField("Pi Number", text: $newPiNumber)
                        Button("Add", action: addStudent)
                        Button("Cancel", role: .cancel, action: {})
                    }
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
                .confirmationDialog("Are you sure you want to delete this student?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                    Button("Delete", role: .destructive) {
                        if let student = studentToDelete {
                            deleteStudent(student)
                        }
                    }
                    Button("Cancel", role: .cancel, action: {})
                }

                NavigationLink(destination: StudentTasksView(students: $students)) {
                    Text("View and Edit Tasks")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .navigationTitle("Task Manager")
            .onAppear {
                loadStudents() // Load students when the view appears
            }
            .onChange(of: students) {
                saveStudents() // Save students whenever the array changes
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
                students[index].tasks.append(newTask)
                students[index].taskCount += 1
            }
        }

        taskName = ""
        taskDescription = ""
        selectedStudents.removeAll()
        audioFilePath = nil // Reset the audio file path

    }

    func addStudent() {
        guard !newStudentName.isEmpty else { return }
        let newStudent = Student(name: newStudentName, piUser: newPiUser, piHost: newPiHost, ip: newIP, piNumber: newPiNumber)
        students.append(newStudent)
        newStudentName = ""
        newPiUser = ""
        newPiHost = ""
        newIP = ""
        newPiNumber = ""
    }

    func editStudent() {
        guard let student = studentToEdit, !newStudentName.isEmpty else { return }
        if let index = students.firstIndex(where: { $0.id == student.id }) {
            students[index].name = newStudentName
            students[index].piUser = newPiUser
            students[index].piHost = newPiHost
            students[index].ip = newIP
            students[index].piNumber = newPiNumber
        }
        studentToEdit = nil
        newStudentName = ""
        newPiUser = ""
        newPiHost = ""
        newIP = ""
        newPiNumber = ""
    }

    func deleteStudent(_ student: Student) {
        students.removeAll { $0.id == student.id }
    }

    // MARK: - Audio Recording Methods
    func startRecording() {
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
            audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
            isRecording = true
        } catch {
            print("Failed to start recording: \(error)")
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
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
}
