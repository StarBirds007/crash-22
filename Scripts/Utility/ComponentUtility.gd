extends Node
class_name ComponentUtility


static func get_component(node: Node, component: Script) -> Node:
	for child in node.get_children():
		if is_instance_of(child, component):
			return child
	return null


static func get_component_recursive(node: Node, component: Script) -> Array[Node]:
	var result: Array[Node]
	for child in node.get_children():
		if is_instance_of(child, component):
			result.append(child)
	return result


static func get_property(node: Node, property_type: String) -> Variant:
	for property in node.get_property_list():
		if property["class_name"] == property_type:
			return node.get(property["name"])
	return null


static func get_property_recursive(node: Node, property_type: String) -> Array[Variant]:
	var result: Array[Variant]
	for property in node.get_property_list():
		if property["class_name"] == property_type:
			result.append(node.get(property["name"]))
	return result
