enum StoreError: Error {
    case notFound
    case duplicate
    case persistence(Error)
    case invalidModel
}
