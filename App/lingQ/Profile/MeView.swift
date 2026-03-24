import SwiftUI
import SwiftData
import SharedModels
import VocabularyKit

struct MeView: View {
    let importRequestID: Int

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Course.createdAt, order: .reverse) private var courses: [Course]
    @Query(sort: \Word.createdAt, order: .reverse) private var words: [Word]

    @State private var showZipImport = false

    init(importRequestID: Int = 0) {
        self.importRequestID = importRequestID
    }

    var body: some View {
        List {
            Section("课程库") {
                NavigationLink {
                    CourseListView()
                } label: {
                    Label {
                        Text("全部课程")
                    } icon: {
                        Image(systemName: "headphones")
                    }
                    .badge(courses.count)
                }

                NavigationLink {
                    CollectionsView()
                } label: {
                    Label("收藏夹", systemImage: "folder")
                }
            }

            Section("导入") {
                Button {
                    showZipImport = true
                } label: {
                    Label("导入课程", systemImage: "square.and.arrow.down")
                }
            }

            Section("关于") {
                LabeledContent("版本", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("我的")
        .navigationBarTitleDisplayMode(.large)
        .onChange(of: importRequestID) { _, newValue in
            if newValue > 0 {
                showZipImport = true
            }
        }
        .sheet(isPresented: $showZipImport) {
            ZipImportView()
        }
    }
}
