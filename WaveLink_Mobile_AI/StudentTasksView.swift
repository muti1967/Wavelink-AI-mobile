import SwiftUI

struct StudentTasksView: View {
    @Binding var students: [Student]
    @State private var showEditTaskAlert: Bool = false
    @State private var taskToEdit: Task? = nil
    @State private var editedTaskName: String = ""
    @State private var editedTaskDescription: String = ""
    @State private var editedTaskTime: Date = Date()

    var body: some View {
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
                                showEditTaskAlert = true
                            }
                            .tint(.blue)

                            // Delete action
                            Button("Delete", role: .destructive) {
                                if let studentIndex = students.firstIndex(where: { $0.id == student.id }) {
                                    students[studentIndex].tasks.remove(at: index)
                                    updateTaskNumbers(for: studentIndex)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Edit Tasks")
        .sheet(isPresented: $showEditTaskAlert) {
            // Use a sheet instead of an alert for a better editing experience
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

    // Function to update task numbers after deletion
    func updateTaskNumbers(for studentIndex: Int) {
        for index in students[studentIndex].tasks.indices {
            students[studentIndex].tasks[index].number = index + 1
        }
    }

    func saveTaskEdits() {
        guard let taskToEdit = taskToEdit else { return }

        for studentIndex in students.indices {
            if let taskIndex = students[studentIndex].tasks.firstIndex(where: { $0.id == taskToEdit.id }) {
                // Update the task details
                students[studentIndex].tasks[taskIndex].name = editedTaskName
                students[studentIndex].tasks[taskIndex].description = editedTaskDescription

                // Format the edited time and update it
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                students[studentIndex].tasks[taskIndex].time = formatter.string(from: editedTaskTime)

                break
            }
        }

        // Clear the task to edit
        self.taskToEdit = nil
    }

    // Helper function to parse time string into Date
    func parseTimeString(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.date(from: timeString)
    }
}
