class_name FamilyConnection
extends Resource

enum ConnectionType {
	Unknown = -1,
	Father,
	Mother,
	Child
}

var kind := ConnectionType.Unknown
var child_index := -1

static func ctor(connection_type: ConnectionType, index: int) -> FamilyConnection:
	var instance := FamilyConnection.new()
	instance.kind = connection_type
	instance.child_index = index
	return instance

func is_parent():
	return kind in [ConnectionType.Father, ConnectionType.Mother]
