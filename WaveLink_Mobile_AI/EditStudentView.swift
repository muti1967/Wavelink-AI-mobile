import SwiftUI

struct EditStudentView: View {
    @Binding var student: Student
    @State private var name: String
    @State private var piUser: String
    @State private var piHost: String
    @State private var ip: String
    @State private var piNumber: String
    @Environment(\.presentationMode) var presentationMode

    init(student: Binding<Student>) {
        _student = student
        _name = State(initialValue: student.wrappedValue.name)
        _piUser = State(initialValue: student.wrappedValue.piUser)
        _piHost = State(initialValue: student.wrappedValue.piHost)
        _ip = State(initialValue: student.wrappedValue.ip)
        _piNumber = State(initialValue: student.wrappedValue.piNumber)
    }

    var body: some View {
        Form {
            Section(header: Text("Student Information")) {
                TextField("Name", text: $name)
                TextField("Pi User", text: $piUser)
                TextField("Pi Host", text: $piHost)
                TextField("IP", text: $ip)
                TextField("Pi Number", text: $piNumber)
            }

            Button("Save") {
                saveChanges()
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .navigationTitle("Edit Student")
    }

    func saveChanges() {
        student.name = name
        student.piUser = piUser
        student.piHost = piHost
        student.ip = ip
        student.piNumber = piNumber
    }
}
