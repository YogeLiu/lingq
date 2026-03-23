import Foundation
import zlib

enum ZipImporter {
    static let coursesFolder = "courses"

    struct ImportResult {
        let title: String
        let audioFilePath: String
        let subtitleFilePath: String
        let coverImagePath: String?
    }

    enum ImportError: LocalizedError {
        case invalidArchive(String)
        case unsupportedCompression(UInt16)
        case encryptedArchive
        case noAudioFile
        case noSubtitleFile
        case extractionFailed(String)

        var errorDescription: String? {
            switch self {
            case .invalidArchive(let message):
                "ZIP 文件无效：\(message)"
            case .unsupportedCompression(let method):
                "暂不支持这种 ZIP 压缩格式（method \(method)）。请重新用常规 ZIP 导出。"
            case .encryptedArchive:
                "暂不支持加密 ZIP。请移除密码后重新导入。"
            case .noAudioFile:
                "ZIP 中未找到音频文件（支持 .mp3、.m4a、.wav、.aac）。"
            case .noSubtitleFile:
                "ZIP 中未找到字幕文件（.srt）。"
            case .extractionFailed(let message):
                "解压失败：\(message)"
            }
        }
    }

    static func importZip(from sourceURL: URL) throws -> ImportResult {
        let archiveData = try Data(contentsOf: sourceURL, options: [.mappedIfSafe])
        let fileManager = FileManager.default
        let courseFolderName = UUID().uuidString
        let relativeCoursePath = "\(coursesFolder)/\(courseFolderName)"
        let courseDirectory = documentsDirectory.appendingPathComponent(relativeCoursePath, isDirectory: true)

        try fileManager.createDirectory(at: courseDirectory, withIntermediateDirectories: true)

        do {
            let parser = try ZipArchiveParser(data: archiveData)
            try parser.extractAll(to: courseDirectory)

            let files = try discoveredFiles(in: courseDirectory)
            guard let audioFile = preferredFile(in: files, extensions: ["mp3", "m4a", "wav", "aac"]) else {
                throw ImportError.noAudioFile
            }
            guard let subtitleFile = preferredFile(in: files, extensions: ["srt"]) else {
                throw ImportError.noSubtitleFile
            }
            let coverFile = preferredFile(in: files, extensions: ["jpg", "jpeg", "png", "webp"])

            let audioFilename = "audio.\(audioFile.pathExtension.lowercased())"
            let subtitleFilename = "subtitle.srt"
            let audioDestination = courseDirectory.appendingPathComponent(audioFilename)
            let subtitleDestination = courseDirectory.appendingPathComponent(subtitleFilename)

            if audioFile.standardizedFileURL != audioDestination.standardizedFileURL {
                try replaceItemIfNeeded(at: audioDestination)
                try fileManager.moveItem(at: audioFile, to: audioDestination)
            }

            if subtitleFile.standardizedFileURL != subtitleDestination.standardizedFileURL {
                try replaceItemIfNeeded(at: subtitleDestination)
                try fileManager.moveItem(at: subtitleFile, to: subtitleDestination)
            }

            var coverRelativePath: String?
            if let coverFile {
                let coverFilename = "cover.\(coverFile.pathExtension.lowercased())"
                let coverDestination = courseDirectory.appendingPathComponent(coverFilename)
                if coverFile.standardizedFileURL != coverDestination.standardizedFileURL {
                    try replaceItemIfNeeded(at: coverDestination)
                    try fileManager.moveItem(at: coverFile, to: coverDestination)
                }
                coverRelativePath = "\(relativeCoursePath)/\(coverFilename)"
            }

            return ImportResult(
                title: sourceURL.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "_", with: " "),
                audioFilePath: "\(relativeCoursePath)/\(audioFilename)",
                subtitleFilePath: "\(relativeCoursePath)/\(subtitleFilename)",
                coverImagePath: coverRelativePath
            )
        } catch let error as ImportError {
            try? fileManager.removeItem(at: courseDirectory)
            throw error
        } catch {
            try? fileManager.removeItem(at: courseDirectory)
            throw ImportError.extractionFailed(error.localizedDescription)
        }
    }

    static func deleteCourseFiles(audioFilePath: String?, subtitleFilePath: String?, coverImagePath: String?) {
        let candidates = [audioFilePath, subtitleFilePath, coverImagePath].compactMap { $0 }
        guard let relativePath = candidates.first else { return }

        let components = relativePath.split(separator: "/")
        guard components.count >= 2, components[0] == Substring(coursesFolder) else { return }

        let courseDirectory = documentsDirectory
            .appendingPathComponent(coursesFolder, isDirectory: true)
            .appendingPathComponent(String(components[1]), isDirectory: true)

        try? FileManager.default.removeItem(at: courseDirectory)
    }

    private static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    private static func replaceItemIfNeeded(at url: URL) throws {
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }

    private static func discoveredFiles(in directory: URL) throws -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var files: [URL] = []
        for case let fileURL as URL in enumerator {
            let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
            if values.isRegularFile == true {
                files.append(fileURL)
            }
        }
        return files.sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
    }

    private static func preferredFile(in files: [URL], extensions: Set<String>) -> URL? {
        let matches = files.filter { extensions.contains($0.pathExtension.lowercased()) }
        let preferredKeywords = ["cover", "audio", "subtitle", "lesson", "track"]

        return matches.sorted { lhs, rhs in
            let lhsName = lhs.deletingPathExtension().lastPathComponent.lowercased()
            let rhsName = rhs.deletingPathExtension().lastPathComponent.lowercased()
            let lhsPriority = preferredKeywords.firstIndex(where: lhsName.contains) ?? preferredKeywords.count
            let rhsPriority = preferredKeywords.firstIndex(where: rhsName.contains) ?? preferredKeywords.count
            if lhsPriority != rhsPriority {
                return lhsPriority < rhsPriority
            }
            return lhs.path.count < rhs.path.count
        }.first
    }
}

private struct ZipArchiveParser {
    private let data: Data

    init(data: Data) throws {
        guard data.count > 22 else {
            throw ZipImporter.ImportError.invalidArchive("文件过小")
        }
        self.data = data
    }

    func extractAll(to destinationDirectory: URL) throws {
        for entry in try entries() {
            try extract(entry: entry, to: destinationDirectory)
        }
    }

    private func entries() throws -> [ZipEntry] {
        let endOfCentralDirectoryOffset = try locateEndOfCentralDirectory()
        let totalEntries = Int(try data.readUInt16LE(at: endOfCentralDirectoryOffset + 10))
        let centralDirectoryOffset = Int(try data.readUInt32LE(at: endOfCentralDirectoryOffset + 16))

        var cursor = centralDirectoryOffset
        var results: [ZipEntry] = []

        for _ in 0..<totalEntries {
            guard try data.readUInt32LE(at: cursor) == 0x02014b50 else {
                throw ZipImporter.ImportError.invalidArchive("central directory header 缺失")
            }

            let generalPurposeFlag = try data.readUInt16LE(at: cursor + 8)
            let compressionMethod = try data.readUInt16LE(at: cursor + 10)
            let compressedSize = Int(try data.readUInt32LE(at: cursor + 20))
            let uncompressedSize = Int(try data.readUInt32LE(at: cursor + 24))
            let fileNameLength = Int(try data.readUInt16LE(at: cursor + 28))
            let extraFieldLength = Int(try data.readUInt16LE(at: cursor + 30))
            let commentLength = Int(try data.readUInt16LE(at: cursor + 32))
            let localHeaderOffset = Int(try data.readUInt32LE(at: cursor + 42))
            let fileNameOffset = cursor + 46
            let fileNameBytes = try data.readBytes(in: fileNameOffset..<(fileNameOffset + fileNameLength))

            results.append(
                ZipEntry(
                    path: String(decoding: fileNameBytes, as: UTF8.self),
                    generalPurposeFlag: generalPurposeFlag,
                    compressionMethod: compressionMethod,
                    compressedSize: compressedSize,
                    uncompressedSize: uncompressedSize,
                    localHeaderOffset: localHeaderOffset
                )
            )

            cursor += 46 + fileNameLength + extraFieldLength + commentLength
        }

        return results
    }

    private func locateEndOfCentralDirectory() throws -> Int {
        let minOffset = max(0, data.count - 66_000)
        var offset = data.count - 22

        while offset >= minOffset {
            if try data.readUInt32LE(at: offset) == 0x06054b50 {
                return offset
            }
            offset -= 1
        }

        throw ZipImporter.ImportError.invalidArchive("未找到 end of central directory")
    }

    private func extract(entry: ZipEntry, to destinationDirectory: URL) throws {
        if entry.generalPurposeFlag & 0x1 != 0 {
            throw ZipImporter.ImportError.encryptedArchive
        }

        let sanitizedDestination = try sanitizedURL(for: entry.path, under: destinationDirectory)
        if entry.isDirectory {
            try FileManager.default.createDirectory(at: sanitizedDestination, withIntermediateDirectories: true)
            return
        }

        guard try data.readUInt32LE(at: entry.localHeaderOffset) == 0x04034b50 else {
            throw ZipImporter.ImportError.invalidArchive("local file header 缺失")
        }

        let localFileNameLength = Int(try data.readUInt16LE(at: entry.localHeaderOffset + 26))
        let localExtraFieldLength = Int(try data.readUInt16LE(at: entry.localHeaderOffset + 28))
        let payloadOffset = entry.localHeaderOffset + 30 + localFileNameLength + localExtraFieldLength
        let payloadEnd = payloadOffset + entry.compressedSize
        let compressedBytes = try data.readData(in: payloadOffset..<payloadEnd)

        let outputData: Data
        switch entry.compressionMethod {
        case 0:
            outputData = compressedBytes
        case 8:
            outputData = try inflateDeflatedData(compressedBytes, expectedSize: entry.uncompressedSize)
        default:
            throw ZipImporter.ImportError.unsupportedCompression(entry.compressionMethod)
        }

        try FileManager.default.createDirectory(at: sanitizedDestination.deletingLastPathComponent(), withIntermediateDirectories: true)
        try outputData.write(to: sanitizedDestination, options: .atomic)
    }

    private func sanitizedURL(for path: String, under root: URL) throws -> URL {
        let parts = path
            .split(separator: "/")
            .map(String.init)
            .filter { !$0.isEmpty && $0 != "." && $0 != "__MACOSX" }

        guard !parts.contains("..") else {
            throw ZipImporter.ImportError.invalidArchive("ZIP 内包含非法路径")
        }

        var url = root
        for part in parts {
            url.appendPathComponent(part, isDirectory: false)
        }

        guard url.standardizedFileURL.path.hasPrefix(root.standardizedFileURL.path) else {
            throw ZipImporter.ImportError.invalidArchive("ZIP 内路径越界")
        }

        return url
    }

    private func inflateDeflatedData(_ compressedData: Data, expectedSize: Int) throws -> Data {
        if compressedData.isEmpty {
            return Data()
        }

        var stream = z_stream()
        let initStatus = inflateInit2_(&stream, -MAX_WBITS, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
        guard initStatus == Z_OK else {
            throw ZipImporter.ImportError.extractionFailed("inflateInit2 失败")
        }
        defer { inflateEnd(&stream) }

        var output = [UInt8](repeating: 0, count: max(expectedSize, 64 * 1024))

        return try compressedData.withUnsafeBytes { rawBuffer -> Data in
            guard let inputBaseAddress = rawBuffer.bindMemory(to: Bytef.self).baseAddress else {
                return Data()
            }

            stream.next_in = UnsafeMutablePointer<Bytef>(mutating: inputBaseAddress)
            stream.avail_in = uInt(compressedData.count)

            while true {
                if Int(stream.total_out) >= output.count {
                    output.append(contentsOf: repeatElement(0, count: max(expectedSize, 64 * 1024)))
                }

                let status: Int32 = output.withUnsafeMutableBufferPointer { buffer in
                    stream.next_out = buffer.baseAddress?.advanced(by: Int(stream.total_out))
                    stream.avail_out = uInt(buffer.count - Int(stream.total_out))
                    return inflate(&stream, Z_NO_FLUSH)
                }

                switch status {
                case Z_OK:
                    continue
                case Z_STREAM_END:
                    output.removeSubrange(Int(stream.total_out)..<output.count)
                    return Data(output)
                default:
                    throw ZipImporter.ImportError.extractionFailed("inflate 失败，状态码 \(status)")
                }
            }
        }
    }
}

private struct ZipEntry {
    let path: String
    let generalPurposeFlag: UInt16
    let compressionMethod: UInt16
    let compressedSize: Int
    let uncompressedSize: Int
    let localHeaderOffset: Int

    var isDirectory: Bool {
        path.hasSuffix("/")
    }
}

private extension Data {
    func readUInt16LE(at offset: Int) throws -> UInt16 {
        guard offset >= 0, offset + 2 <= count else {
            throw ZipImporter.ImportError.invalidArchive("越界读取 UInt16")
        }
        return UInt16(self[offset]) | (UInt16(self[offset + 1]) << 8)
    }

    func readUInt32LE(at offset: Int) throws -> UInt32 {
        guard offset >= 0, offset + 4 <= count else {
            throw ZipImporter.ImportError.invalidArchive("越界读取 UInt32")
        }
        return UInt32(self[offset])
            | (UInt32(self[offset + 1]) << 8)
            | (UInt32(self[offset + 2]) << 16)
            | (UInt32(self[offset + 3]) << 24)
    }

    func readBytes(in range: Range<Int>) throws -> [UInt8] {
        guard range.lowerBound >= 0, range.upperBound <= count else {
            throw ZipImporter.ImportError.invalidArchive("越界读取字节")
        }
        return Array(self[range])
    }

    func readData(in range: Range<Int>) throws -> Data {
        guard range.lowerBound >= 0, range.upperBound <= count else {
            throw ZipImporter.ImportError.invalidArchive("越界读取数据")
        }
        return subdata(in: range)
    }
}
