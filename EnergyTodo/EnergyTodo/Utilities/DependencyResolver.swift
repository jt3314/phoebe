import Foundation

/// Topological sort using Kahn's algorithm for task dependency resolution.
/// Ported from src/lib/scheduling/dependency-resolver.ts
enum DependencyResolver {

    /// Perform topological sort on tasks based on dependencies.
    /// Returns nil if a circular dependency is detected.
    static func topologicalSort(
        tasks: [Task_],
        dependencies: [TaskDependency]
    ) -> [Task_]? {
        // Build adjacency list and in-degree map
        var adjList: [UUID: [UUID]] = [:]
        var inDegree: [UUID: Int] = [:]

        // Initialize
        for task in tasks {
            adjList[task.id] = []
            inDegree[task.id] = 0
        }

        // Build graph: edge from dependsOnTaskId -> taskId
        for dep in dependencies {
            let from = dep.dependsOnTaskId
            let to = dep.taskId

            guard adjList[from] != nil, adjList[to] != nil else { continue }

            adjList[from, default: []].append(to)
            inDegree[to, default: 0] += 1
        }

        // Find all nodes with no incoming edges
        var queue: [UUID] = tasks
            .filter { inDegree[$0.id] == 0 }
            .map(\.id)

        let taskMap = Dictionary(uniqueKeysWithValues: tasks.map { ($0.id, $0) })
        var sorted: [Task_] = []

        while !queue.isEmpty {
            let taskId = queue.removeFirst()
            if let task = taskMap[taskId] {
                sorted.append(task)
            }

            for neighborId in adjList[taskId] ?? [] {
                inDegree[neighborId, default: 0] -= 1
                if inDegree[neighborId] == 0 {
                    queue.append(neighborId)
                }
            }
        }

        // If sorted doesn't contain all tasks, there's a cycle
        if sorted.count != tasks.count {
            return nil
        }

        return sorted
    }

    /// Group tasks by milestone, maintaining dependency order within each group.
    static func sortTasksByMilestone(
        tasks: [Task_],
        dependencies: [TaskDependency]
    ) -> [UUID?: [Task_]] {
        let sorted = topologicalSort(tasks: tasks, dependencies: dependencies) ?? tasks

        var result: [UUID?: [Task_]] = [:]
        for task in sorted {
            result[task.milestoneId, default: []].append(task)
        }
        return result
    }
}
