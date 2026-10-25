import Testing

struct SampleTests {
    @Test("US1 FR-AAA-01: the app opens")
    func opens() {}

    @Test(
        "US2 FR-AAA-01 FR-BBB-01: a long name on its own line"
    )
    func movesAfterOpening() {}

    @Test("US3: no requirement here")
    func helper() {}
}
