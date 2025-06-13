// The Swift Programming Language
// https://docs.swift.org/swift-book

import HTTPTypes


#if canImport(NIO)
import AsyncHTTPClient
#else

#endif


public protocol HttpClientAbstract {

    func send(request: Request) async throws -> Response
}

extension HttpClientAbstract {
#if canImport(NIO)
    public typealias Request = AsyncHTTPClient.HTTPClientRequest
    public typealias Response = AsyncHTTPClient.HTTPClientResponse
#else

#endif
}

#if canImport(NIO)
extension AsyncHTTPClient.HTTPClient: HttpClientAbstract {
    public func send(request: HTTPClientRequest) async throws -> HTTPClientResponse {
        try await self.execute(request, deadline: .distantFuture)
    }
}
#else

#endif
