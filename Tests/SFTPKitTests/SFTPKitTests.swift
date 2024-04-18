import XCTest
@testable import SFTPKit

final class SFTPKitTests: XCTestCase {

    private var sut: SFTP?

    override func setUp() async throws {
        sut = try await SFTP(host: SECRET.HOST,
                             username: SECRET.USER,
                             password: SECRET.PWD)
    }

    func testListing() async throws {
        let contents = try await sut?.list(directory: "flightbriefing")
        XCTAssert(!contents!.isEmpty, "No file found")
    }

    func testReading() async throws {
        let file = try await sut?.readFile(atPath: "flightbriefing/KFJK-GOBD.zip")
        XCTAssert(file?.count == 2442847, "Wrong file size")
    }


    func testWriting() async throws {
        let filename = Date().ISO8601Format()
        let path = "flightbriefing/\(filename).txt"
        let data = "Hello world, \(filename)".data(using: .utf8)
        do {
            try await sut?.writeFile(data: data, atRemotePath: path)
        } catch {
            print(error)
            XCTFail()
        }
        // verify written file
        let file = try await sut?.readFile(atPath: path)
        XCTAssert(file == data)
    }

    func testErrors() async {
        // no data
        do {
            try await sut?.writeFile(data: nil, atRemotePath: "test/noFile.txt")
            XCTFail("Call should throw")
        } catch SFTPError.noData {
            // Correct
        } catch {
            XCTFail("Wrong error thrown: \(error)")
        }

        // no file
        do {
            _ = try await sut?.readFile(atPath: "test/noFile.txt")
            XCTFail("Call should throw")
        } catch {
            // Correct
        }
    }
}
