Бег и прыжок
============

Персонаж бегает на :kbd:`A` и :kbd:`D`, прыгает на :kbd:`Space` и падает под
действием гравитации. Короткое нажатие — низкий прыжок, удержание — высокий.
Вверх он летит мягче, чем падает вниз, — так прыжок ощущается упругим, а не
«лунным».

.. godot-demo:: recipes/movement/platformer
   :title: Бег и прыжок


Сцена
-----

.. code-block:: text

   Recipe (Node2D)
   ├── PlatformArena (экземпляр platform_arena.tscn)
   └── Player (CharacterBody2D) — скрипт platformer.gd
       ├── Shape (CollisionShape2D) — RectangleShape2D 32×48
       └── Look (Polygon2D) — прямоугольник 32×48

- :godot:`CharacterBody2D` — :term:`физическое тело <Физическое тело>`, которым
  управляет код: оно не проходит сквозь другие тела. **Motion Mode** оставьте
  **Grounded** — режим для платформеров, в нём у тела есть пол.
- :godot:`CollisionShape2D` задаёт :term:`форму столкновения <Форма
  столкновения>`.
- ``platform_arena.tscn`` — пол, стены и платформы: :godot:`StaticBody2D`
  (неподвижное тело) с прямоугольными формами и такими же :godot:`Polygon2D`,
  плюс :godot:`Camera2D`.
- В **Input Map** нужно действие ``jump`` на :kbd:`Space` и действия
  ``move_left``, ``move_right`` на :kbd:`A` и :kbd:`D`.


Скрипт
------

.. example:: recipes/movement/platformer

Разбор:

- :godot:`Input.get_axis()` возвращает ``-1``, ``1`` или ``0`` — влево, вправо,
  стоим.
- Горизонтальная скорость тянется к ``axis * speed`` функцией ``move_toward``: с
  ``acceleration``, когда клавиша нажата, и с ``friction``, когда отпущена.
- :godot:`CharacterBody2D.is_on_floor()` — стоит ли тело на полу после последнего
  ``move_and_slide()``. В воздухе к ``velocity.y`` каждый кадр прибавляется
  гравитация: ось Y смотрит вниз, поэтому падение — положительная скорость.
- Две гравитации: ``rise_gravity``, пока персонаж летит вверх, и
  ``fall_gravity`` — посильнее, когда падает.
- :godot:`Input.is_action_just_pressed()` — прыжок на одно нажатие: вертикальная
  скорость становится ``-jump_speed``, вверх.
- :godot:`Input.is_action_just_released()` — отпустили клавишу на взлёте: скорость
  вверх умножается на ``jump_cut``, и прыжок обрывается. Так высота прыжка
  зависит от того, сколько держать клавишу.
- :godot:`CharacterBody2D.move_and_slide()` двигает тело на ``velocity * delta``,
  останавливает на полу и у стен и обновляет ``is_on_floor()``.


Настройка
---------

- ``speed``, ``acceleration``, ``friction`` — бег: скорость, разгон и
  торможение. Малое ``friction`` даёт скольжение.
- ``jump_speed`` и ``rise_gravity`` задают высоту прыжка: ``jump_speed² / (2 ·
  rise_gravity)``. При ``720`` и ``1800`` — ``144`` пикселя.
- ``fall_gravity`` — насколько быстрее персонаж падает. Равная ``rise_gravity``
  даёт симметричную плавную дугу.
- ``jump_cut`` — какая часть скорости вверх остаётся, когда клавишу отпустили.
  ``1`` — высота прыжка не зависит от нажатия.
