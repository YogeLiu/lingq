import Foundation
import SwiftData
import Testing
@testable import SharedModels

@MainActor
@Test func collectionStoresTitleAndCreationDate() throws {
    let collection = CourseCollection(title: "Podcast")

    #expect(collection.title == "Podcast")
    #expect(collection.createdAt <= Date())
    #expect(collection.courses.isEmpty)
}

@MainActor
@Test func courseCanBelongToACollection() throws {
    let collection = CourseCollection(title: "Daily Input")
    let course = Course(title: "Cat Podcast", audioBookmark: Data(), subtitleBookmark: Data())

    course.collection = collection

    #expect(course.collection?.title == "Daily Input")
}
