//
//  ServerSentEvent.swift
//  dify-forward
//
//  Created by AFuture on 2025/4/5.
//
import Foundation
import RegexBuilder
import AsyncAlgorithms
import LazyKit
import Logging
import SynchronizationKit

enum ASCII {
    /// The carriage return `<CR>` character.
    static let cr: UInt8 = 0x0d
    
    /// The line feed `<LF>` character.
    static let lf: UInt8 = 0x0a
    
    /// The colon `:` character.
    static let colon: UInt8 = 0x3a
    
    /// The space ` ` character.
    static let space: UInt8 = 0x20
}

/// A structure representing a Server-Sent Event.
public struct ServerSentEvent: Sendable {
    /// The event's ID.
    public let id: String?
    /// The event's type.
    public let event: String
    /// The event's data.
    public let data: String
    /// The reconnection time for the event stream.
    public let retry: Int?
}

public extension ServerSentEvent {
    /// The MIME type for Server-Sent Events.
    static let MIME_String: String = "text/event-stream"
    
    /// The character encoding for Server-Sent Events.
    static let encoding: String.Encoding = .utf8
}



/// An interpreter for processing Server-Sent Events (SSE).
///
/// This class processes a stream of `Data` and interprets it as a sequence of `ServerSentEvent` objects
/// according to the [W3C specification](https://html.spec.whatwg.org/multipage/server-sent-events.html#event-stream-interpretation).
public final class ServerSentEventsInterpreter: Sendable {

    private let clientLastEventId: LazyLockedValue<String?> = .init(nil)
    /// A logger for the interpreter.
    public let logger: Logger = .init(label: "me.afuture.server.sse")

    private let fields: LazyLockedValue<[String: String]> = .init([:])
    
    private let pendingLine: LazyLockedValue<String> = .init("")
    
    private let cachedChunk: LazyLockedValue<[UInt8]> = .init([])
    
    /// Processes a `Data` buffer and returns an array of `ServerSentEvent` objects.
    ///
    /// - Parameter buffer: The `Data` buffer to process.
    /// - Returns: An array of `ServerSentEvent` objects parsed from the buffer.
    public func process(buffer: Data) -> [ServerSentEvent] {
        let bytes = [UInt8](buffer)
        
        var chunks: [[UInt8]] = []
        do {
            for byte in bytes {
                cachedChunk.withLock { $0.append(byte) }
                let chunk = cachedChunk.withLock { $0 }
                
                // when fired, it is guaranteed that the chunk
                // must contains an empty line.
                // so that evey chunk correspond to a event.
                if !chunkCanFire(chunk) {
                    continue
                }
                
                cachedChunk.withLock { $0 = [] }
                
                logger.debug("[*] chunk: \(String(data: .init(chunk), encoding: .utf8)!.debugDescription)")
                chunks.append(chunk)
            }
        }
        
        // Streams must be decoded using the UTF-8 decode algorithm.
        let utf8StrChunk = chunks.compactMap { String(data: .init($0), encoding: .utf8) }

        var events: [ServerSentEvent?] = []
        for chunk in utf8StrChunk {
            let event = processOneChunk(chunk)
            events.append(event)
        }
        
        return events.compactMap { $0 }
    }
    
    internal func chunkCanFire(_ chunk: [UInt8]) -> Bool {
        let len = chunk.count
        if len < 2 {
            return false
        }
        
        let last1 = chunk[len - 1]
        let last2 = chunk[len - 2]
        
        if last2 == ASCII.lf && last1 == ASCII.lf {
            // "\n\n"
            return true
        } else if last2 == ASCII.cr && last1 == ASCII.cr {
            // "\r\r"
            return true
        } else if len >= 4, chunk[len - 4] == ASCII.cr && chunk[len - 3] == ASCII.lf && last2 == ASCII.cr && last1 == ASCII.lf {
            // "\r\n\r\n"
            return true
        } else {
            return false
        }
    }
    
    public func processOneChunk(_ chunk: String) ->  ServerSentEvent? {
        let lines = chunk.split(separator: Self.lineRegex, omittingEmptySubsequences: false)
        for line in lines {
            if line == "" {
                // empty line. dispatch the event
                let event = fields.withLock { fields in
                    let event = buildEvent(fields)
                    fields = [:]
                    return event
                }
                
                return event
            }
            
            if line.starts(with: ":") {
                // the comment line.
                continue
            }
            
            if line.starts(with: "event:") {
                let event = line.split(separator: #/: ?/#, maxSplits: 1).last
                
                fields.withLock {
                    $0["event"] = String(event ?? "")
                }
                
            } else if line.starts(with: "id:") {
                let value = line.split(separator: #/: ?/#, maxSplits: 1).last
                if let id = value {
                    fields.withLock {
                        $0["id"] = String(id)
                    }
                }
                
            } else if line.starts(with: "retry:") {
                // TODO: Support retry logic
            } else if line.starts(with: "data:") {
                let data = line.split(separator: #/: ?/#, maxSplits: 1).last
                fields.withLock {
                    $0["data"] = ($0["data"] ?? "").appending(String(data ?? "") + "\n")
                }
            } else {
                let key = String(line)
                fields.withLock {
                    $0[key] = ""
                }
            }
        }
        
        return nil
    }

    public func buildEvent(_ fields: [String: String]) -> ServerSentEvent? {
        let eventType = fields["event"] ?? "message"

        guard var data = fields["data"], !data.isEmpty else {
            return nil
        }

        if data.hasSuffix("\n") {
            data.removeLast()
        }

        let id = clientLastEventId.withLock { $0 }

        let event = ServerSentEvent(id: id, event: eventType, data: data, retry: nil)

        clientLastEventId.withLock { theID in
            theID = fields["id"] ?? theID
        }

        return event
    }
}

extension ServerSentEventsInterpreter {

    static let lineCharacters = ["\r\n", "\n", "\r"]
    nonisolated(unsafe) static let lineRegex: any RegexComponent = Regex {
        ChoiceOf {
            "\r\n"
            "\n"
            "\r"
        }
    }
}

// Rewrite using state machine.
// The current implement is for convenience.
/// An `AsyncSequence` that interprets a stream of `Data` as Server-Sent Events.
public final class AsyncServerSentEventsInterpreter: AsyncSequence, Sendable {
    /// The element type of the sequence, which is `ServerSentEvent`.
    public typealias Element = ServerSentEvent

    let stream: AnyAsyncSequence<Data>
    
    /// Initializes a new `AsyncServerSentEventsInterpreter` with the given stream of `Data`.
    /// - Parameter stream: The stream of `Data` to interpret.
    public init(stream: AnyAsyncSequence<Data>) {
        self.stream = stream
    }

    /// Creates an asynchronous iterator that produces elements of this sequence.
    public func makeAsyncIterator() -> AnyAsyncSequence<ServerSentEvent>.AsyncIterator {
        let interpreter = ServerSentEventsInterpreter()
        return stream.map {
            interpreter.process(buffer: $0)
        }.flatMap { $0.async }.eraseToAnyAsyncSequence().makeAsyncIterator()
    }
}

extension AsyncSequence where Self: Sendable, Self.Element == Data {
    /// Maps an asynchronous sequence of `Data` to an asynchronous sequence of `ServerSentEvent`.
    /// - Returns: An `AsyncServerSentEventsInterpreter` that interprets the `Data` stream.
    public func mapToServerSentEvert() -> AsyncServerSentEventsInterpreter {
        AsyncServerSentEventsInterpreter(stream: .init(self))
    }
}
