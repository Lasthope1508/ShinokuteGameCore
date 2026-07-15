class_name ShinokuteInventoryContainer
extends RefCounted

var _capacity := 0
var _default_max_stack := 1
var _stacks: Array = []

func configure(options: Dictionary = {}) -> void:
	_capacity = int(max(0, int(options.get("capacity", 0))))
	_default_max_stack = int(max(1, int(options.get("default_max_stack", 1))))
	_stacks = Array(options.get("stacks", [])).duplicate(true)

func add_item(item: Dictionary) -> Dictionary:
	var id := String(item.get("id", ""))
	var quantity := int(max(0, int(item.get("quantity", 1))))
	var max_stack := int(max(1, int(item.get("max_stack", _default_max_stack))))
	if id.is_empty() or quantity <= 0:
		return {"accepted": false, "accepted_quantity": 0, "rejected_quantity": quantity}
	var remaining := quantity
	for index in range(_stacks.size()):
		if remaining <= 0:
			break
		var stack := Dictionary(_stacks[index])
		if String(stack.get("id", "")) != id:
			continue
		var stack_max := int(max(1, int(stack.get("max_stack", max_stack))))
		var room := max(0, stack_max - int(stack.get("quantity", 0)))
		if room <= 0:
			continue
		var moved := min(room, remaining)
		stack["quantity"] = int(stack.get("quantity", 0)) + moved
		_stacks[index] = stack
		remaining -= moved
	while remaining > 0 and (_capacity <= 0 or _stacks.size() < _capacity):
		var moved_to_new_stack := min(max_stack, remaining)
		var new_stack := item.duplicate(true)
		new_stack["id"] = id
		new_stack["quantity"] = moved_to_new_stack
		new_stack["max_stack"] = max_stack
		_stacks.append(new_stack)
		remaining -= moved_to_new_stack
	var accepted_quantity := quantity - remaining
	return {
		"accepted": accepted_quantity > 0,
		"accepted_quantity": accepted_quantity,
		"rejected_quantity": remaining
	}

func remove_item(id: String, quantity: int) -> Dictionary:
	var remaining := int(max(0, quantity))
	var removed := 0
	for index in range(_stacks.size() - 1, -1, -1):
		if remaining <= 0:
			break
		var stack := Dictionary(_stacks[index])
		if String(stack.get("id", "")) != id:
			continue
		var available := int(max(0, int(stack.get("quantity", 0))))
		var moved := min(available, remaining)
		stack["quantity"] = available - moved
		removed += moved
		remaining -= moved
		if int(stack.get("quantity", 0)) <= 0:
			_stacks.remove_at(index)
		else:
			_stacks[index] = stack
	return {"id": id, "removed_quantity": removed, "missing_quantity": remaining}

func quantity(id: String) -> int:
	var total := 0
	for item in _stacks:
		if item is Dictionary and String(Dictionary(item).get("id", "")) == id:
			total += int(Dictionary(item).get("quantity", 0))
	return total

func snapshot() -> Array:
	return _stacks.duplicate(true)

func restore(stacks: Array) -> void:
	_stacks = stacks.duplicate(true)

func clear() -> void:
	_stacks.clear()

func stacks() -> Array:
	return _stacks.duplicate(true)
