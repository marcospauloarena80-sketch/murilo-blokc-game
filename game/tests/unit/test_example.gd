extends GutTest
## Teste exemplo — confirma que o GUT roda headless no CI (F1).
## Substituir por testes reais a partir da F2 (worldgen).


func test_sanidade() -> void:
	assert_eq(1 + 1, 2, "matemática básica deve funcionar")
