-- A table with values of type _Value_ and numeric keys 1..n with no gaps
export type Array<Value> = { [number]: Value }
-- A table with values of type _Value_ and numeric keys, possibly with gaps
export type Args<Value> = { [number]: Value }
-- A table with keys of type _Key_ and values of type _Value_
export type Map<Key, Value> = { [Key]: Value }
-- A table with keys of a fixed type _Key_ and a true value representing
-- membership of the set (nil is not a member of the set)
export type Set<Key> = { [Key]: true? }
-- A table of any type
export type Table = { [any]: any }
-- A class has a constructor returning an instance of _Object_ type
export type Class<Object> = {
	new: () -> Object,
}
-- Represents a function which takes any arguments and returns any value
export type AnyFunction = (...any) -> any?
-- Represents a callback function with no arguments and no return value
export type Callback = () -> ()
