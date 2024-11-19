import Foundation

struct Task: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var number: Int
    var time: String
    var description: String
    var audioFilePath: String? // New property to store the audio file path

    init(id: UUID = UUID(), name: String, number: Int, time: String, description: String, audioFilePath: String? = nil) {
        self.id = id
        self.name = name
        self.number = number
        self.time = time
        self.description = description
        self.audioFilePath = audioFilePath
    }

    static func == (lhs: Task, rhs: Task) -> Bool {
        return lhs.id == rhs.id
    }
}

struct Student: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var piUser: String
    var piHost: String
    var ip: String
    var piNumber: String
    var tasks: [Task]
    var taskCount: Int

    init(id: UUID = UUID(), name: String, piUser: String = "", piHost: String = "", ip: String = "", piNumber: String = "", tasks: [Task] = [], taskCount: Int = 1) {
        self.id = id
        self.name = name
        self.piUser = piUser
        self.piHost = piHost
        self.ip = ip
        self.piNumber = piNumber
        self.tasks = tasks
        self.taskCount = taskCount
    }

    static func == (lhs: Student, rhs: Student) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.piUser == rhs.piUser &&
               lhs.piHost == rhs.piHost &&
               lhs.ip == rhs.ip &&
               lhs.piNumber == rhs.piNumber &&
               lhs.tasks == rhs.tasks &&
               lhs.taskCount == rhs.taskCount
    }
}
