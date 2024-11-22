import Foundation
import Combine

class Task: Identifiable, ObservableObject, Codable, Equatable {
    let id: UUID
    @Published var name: String
    @Published var number: Int
    @Published var time: String
    @Published var description: String
    @Published var audioFilePath: String?

    init(id: UUID = UUID(), name: String, number: Int, time: String, description: String, audioFilePath: String? = nil) {
        self.id = id
        self.name = name
        self.number = number
        self.time = time
        self.description = description
        self.audioFilePath = audioFilePath
    }

    // MARK: - Codable Conformance

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case number
        case time
        case description
        case audioFilePath
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        // Decode the wrapped values
        name = try container.decode(String.self, forKey: .name)
        number = try container.decode(Int.self, forKey: .number)
        time = try container.decode(String.self, forKey: .time)
        description = try container.decode(String.self, forKey: .description)
        audioFilePath = try container.decodeIfPresent(String.self, forKey: .audioFilePath)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        // Encode the wrapped values
        try container.encode(name, forKey: .name)
        try container.encode(number, forKey: .number)
        try container.encode(time, forKey: .time)
        try container.encode(description, forKey: .description)
        try container.encodeIfPresent(audioFilePath, forKey: .audioFilePath)
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
