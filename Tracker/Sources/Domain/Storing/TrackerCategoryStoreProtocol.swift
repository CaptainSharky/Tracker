protocol TrackerCategoryStoreProtocol {
    func getOrCreate(title: String) throws
    func allTitles() throws -> [String]
}
