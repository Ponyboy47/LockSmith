infix operator ?!: NilCoalescingPrecedence

/// Unwrap or throw operator
func ?! <T>(lhs: T?, rhs: @autoclosure () -> Error) throws -> T {
    if let val = lhs { return val }
    throw rhs()
}
