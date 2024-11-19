import SwiftUI

struct TaskManagerView: View {
    @State private var tasks: [String] = ["Task 1", "Task 2", "Task 3"]
    @State private var newTask: String = ""

    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(tasks, id: \.self) { task in
                        Text(task)
                    }
                    .onDelete(perform: deleteTask)
                }
                
                HStack {
                    TextField("New Task", text: $newTask)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button(action: addTask) {
                        Text("Add")
                    }
                }
                .padding()
            }
            .navigationTitle("Task Manager")
        }
    }

    func addTask() {
        if !newTask.isEmpty {
            tasks.append(newTask)
            newTask = ""
        }
    }

    func deleteTask(at offsets: IndexSet) {
        tasks.remove(atOffsets: offsets)
    }
}
