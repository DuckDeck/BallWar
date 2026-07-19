class_name HitResolver
extends RefCounted

func resolve(collider: Node, context: HitContext, effects: Array[BallEffect]) -> HitResult:
	for effect: BallEffect in effects:
		effect.modify_hit_context(context)
	var result: HitResult = collider.call(&"receive_hit", context) as HitResult
	if result == null:
		result = HitResult.new()
	for effect: BallEffect in effects:
		effect.modify_hit_result(context, result)
	return result
