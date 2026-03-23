import XCTest
@testable import EnergyTodo

final class DependencyResolverTests: XCTestCase {

    private func makeTask(id: UUID = UUID(), name: String = "Task", projectId: UUID = UUID()) -> Task_ {
        Task_(
            id: id,
            projectId: projectId,
            milestoneId: nil,
            name: name,
            description: nil,
            effortPoints: 3,
            timeEstimate: nil,
            scheduledDate: nil,
            completedDate: nil,
            status: .pending,
            sortOrder: 0,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    // MARK: - Topological Sort

    func testNoDependencies() {
        let t1 = makeTask(name: "A")
        let t2 = makeTask(name: "B")
        let t3 = makeTask(name: "C")

        let result = DependencyResolver.topologicalSort(tasks: [t1, t2, t3], dependencies: [])
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.count, 3)
    }

    func testLinearChain() {
        let projectId = UUID()
        let t1 = makeTask(id: UUID(), name: "First", projectId: projectId)
        let t2 = makeTask(id: UUID(), name: "Second", projectId: projectId)
        let t3 = makeTask(id: UUID(), name: "Third", projectId: projectId)

        let deps = [
            TaskDependency(id: UUID(), taskId: t2.id, dependsOnTaskId: t1.id, projectId: projectId),
            TaskDependency(id: UUID(), taskId: t3.id, dependsOnTaskId: t2.id, projectId: projectId),
        ]

        let result = DependencyResolver.topologicalSort(tasks: [t1, t2, t3], dependencies: deps)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?[0].id, t1.id)
        XCTAssertEqual(result?[1].id, t2.id)
        XCTAssertEqual(result?[2].id, t3.id)
    }

    func testDiamondDependency() {
        let projectId = UUID()
        let t1 = makeTask(id: UUID(), name: "Root", projectId: projectId)
        let t2 = makeTask(id: UUID(), name: "Left", projectId: projectId)
        let t3 = makeTask(id: UUID(), name: "Right", projectId: projectId)
        let t4 = makeTask(id: UUID(), name: "Join", projectId: projectId)

        let deps = [
            TaskDependency(id: UUID(), taskId: t2.id, dependsOnTaskId: t1.id, projectId: projectId),
            TaskDependency(id: UUID(), taskId: t3.id, dependsOnTaskId: t1.id, projectId: projectId),
            TaskDependency(id: UUID(), taskId: t4.id, dependsOnTaskId: t2.id, projectId: projectId),
            TaskDependency(id: UUID(), taskId: t4.id, dependsOnTaskId: t3.id, projectId: projectId),
        ]

        let result = DependencyResolver.topologicalSort(tasks: [t1, t2, t3, t4], dependencies: deps)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.count, 4)

        // t1 must come first, t4 must come last
        XCTAssertEqual(result?.first?.id, t1.id)
        XCTAssertEqual(result?.last?.id, t4.id)
    }

    func testCircularDependencyReturnsNil() {
        let projectId = UUID()
        let t1 = makeTask(id: UUID(), name: "A", projectId: projectId)
        let t2 = makeTask(id: UUID(), name: "B", projectId: projectId)

        let deps = [
            TaskDependency(id: UUID(), taskId: t2.id, dependsOnTaskId: t1.id, projectId: projectId),
            TaskDependency(id: UUID(), taskId: t1.id, dependsOnTaskId: t2.id, projectId: projectId),
        ]

        let result = DependencyResolver.topologicalSort(tasks: [t1, t2], dependencies: deps)
        XCTAssertNil(result, "Circular dependency should return nil")
    }

    func testEmptyInput() {
        let result = DependencyResolver.topologicalSort(tasks: [], dependencies: [])
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.count, 0)
    }

    // MARK: - Sort By Milestone

    func testSortByMilestone() {
        let projectId = UUID()
        let ms1 = UUID()
        let ms2 = UUID()

        var t1 = makeTask(name: "A", projectId: projectId)
        t1.milestoneId = ms1
        var t2 = makeTask(name: "B", projectId: projectId)
        t2.milestoneId = ms2
        var t3 = makeTask(name: "C", projectId: projectId)
        t3.milestoneId = ms1

        let result = DependencyResolver.sortTasksByMilestone(tasks: [t1, t2, t3], dependencies: [])
        XCTAssertEqual(result[ms1]?.count, 2)
        XCTAssertEqual(result[ms2]?.count, 1)
    }
}
