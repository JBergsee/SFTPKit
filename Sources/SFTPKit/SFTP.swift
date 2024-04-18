// The Swift Programming Language
// https://docs.swift.org/swift-book

//import SSHClient
//
//public class SFTP {
//
//    private var connection: SSHConnection?
//    private var sftp: SFTPClient?
//
//    func setupSFTP() async {
//        let auth = SSHAuthentication(username: "frenchbee@bergsee-aviation.se",
//                                     method: .password(.init("LFPO!A350")),
//                                     hostKeyValidation: .acceptAll())
//        connection = SSHConnection(host: "eta.hostup.se",
//                                   port: 22,
//                                   authentication: auth)
//
//        do {
//            try await connection?.start()
//            sftp = try await connection?.requestSFTPClient()
//            let files = try await sftp?.listDirectory(at: "flightbriefing")
//            guard let zipFiles = files?.compactMap({ file in
//                if file.filename.string.components(separatedBy: ".").last == "zip" {
//                    return file.filename
//                } else {
//                    return nil
//                }
//            }) else {
//                print("No zip files")
//                return
//            }
//
//
//            try await sftp?.withFile(at: zipFiles.first!,
//                                     flags: .read) { file in
//                do {
//                    let data = try await file.read()
//                    print("Data read! It was \(data.count) bytes.")
//                } catch {
//                    print("Error reading data")
//                }
//
//            }
//
//        } catch  {
//            print("Error: \(error) (\(error.localizedDescription))")
//        }
//
//    }
//
//}

import Citadel
import NIOFoundationCompat
import NIO
import Foundation

public class SFTP {
    
    private var client: SSHClient?
    private var sftp: SFTPClient?

    /// Initialise an SFTP using the given parameters
    public init(host: String, username: String, password: String) async throws {

        self.client = try await SSHClient.connect(
            host: host,
            authenticationMethod: .passwordBased(username: username,
                                                 password: password),
            hostKeyValidator: .acceptAnything(),
            reconnect: .never
        )

        self.sftp = try await client?.openSFTP()
    }


    /// List the directory contents, returning an array of paths
    public func list(directory: String) async throws -> [String]? {

        let directoryContents = try await sftp?.listDirectory(atPath: directory)

        let paths = directoryContents?.first?.components

        return paths?.map({ path in
            path.longname
        })
    }

    /// Read the file at the given path.
    public func readFile(atPath path: String) async throws -> Data {

        // read file
        let bytes = try await sftp?.withFile(
            filePath: path,
            flags: .read
        ) { file in
            try await file.readAll()
        }
        guard let bytes else {
            throw SFTPError.noData
        }
        return Data(buffer: bytes)
    }

    /// Writes the data to the given path.
    /// If a file exists at that path it will be overwritten without warning.
    public func writeFile(data: Data?, atRemotePath path: String) async throws {
        guard let data else {
            throw SFTPError.noData
        }

        let file = try await sftp?.openFile(filePath: path, flags: [.write, .create, .truncate])
        try await file?.write(ByteBuffer(data: data), at: 0)
        try await file?.close()
    }
}

enum SFTPError: Error {
    case noData
}

extension SFTPError: CustomStringConvertible {
    var description: String {
        switch self {
        case .noData:
            "There was no data to write/read."
        }
    }
}

extension SFTPError: LocalizedError {
}
