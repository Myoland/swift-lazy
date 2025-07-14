import HTTPTypes


extension HTTPFields {
    public var contentLength: Int? {
        guard let value = self[.contentLength] else {
            return nil
        }
        return Int(value)
    }
    
    public var contentType: String? {
        self[.contentType]
    }
}
