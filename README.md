# Тихая гавань — прототип рыбалки

Godot 4.7. Дизайн-документ: [GDD.md](GDD.md).

## Запуск

```bash
godot --path .            # игра
godot -e --path .         # редактор
```

Управление: WASD/стрелки — ходьба, Пробел — заброс (удерживать), подсечка, подмотка (удерживать). C — коллекция. На тач-устройствах — джойстик и кнопка «ЛОВИТЬ».

## Тесты и отладка

```bash
godot --headless --path . -s res://tests/test_fishing_session.gd   # логика и баланс
godot --path . -- --autoplay --save=user://debug.json               # бот играет сам
godot --path . -- --touch-ui                                        # тач-контролы на десктопе
```

Остальные флаги (скриншоты, автовыход) описаны в `scripts/debug/debug_tools.gd`.
