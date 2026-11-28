Движение по щелчку
==================

Щелчок левой кнопкой мыши — персонаж идёт в эту точку и останавливается точно в
ней. Так управляют героями в квестах и юнитами в стратегиях реального времени.

.. godot-demo:: recipes/movement/click_move
   :title: Движение по щелчку


Сцена
-----

.. code-block:: text

   Recipe (Node2D)
   ├── Arena (экземпляр arena.tscn)
   ├── Marker (Polygon2D) — ромбик в точке цели
   └── Player (CharacterBody2D) — скрипт click_move.gd
       ├── Shape (CollisionShape2D) — CircleShape2D радиусом 20
       └── Look (Polygon2D) — стрелка, смотрящая вправо

- :godot:`CharacterBody2D` — :term:`физическое тело <Физическое тело>`, которым
  управляет код: оно не проходит сквозь другие тела. У ``Player`` поставьте
  **Motion Mode** в **Floating**: при виде сверху у тела нет пола и потолка.
- :godot:`CollisionShape2D` задаёт :term:`форму столкновения <Форма
  столкновения>`.
- Стрелка смотрит вправо: в Godot нулевой поворот — взгляд вдоль оси X.
- ``arena.tscn`` — стены: :godot:`StaticBody2D` с прямоугольными формами и такими
  же :godot:`Polygon2D`, плюс :godot:`Camera2D` в центре.
- В поле **Marker** скрипта выберите узел ``Marker``.


Скрипт
------

.. example:: recipes/movement/click_move

Разбор:

- ``_unhandled_input`` получает щелчок левой кнопкой мыши — событие
  :godot:`InputEventMouseButton` — и запоминает цель.
  :godot:`CanvasItem.get_global_mouse_position()` даёт точку щелчка в глобальных
  координатах.
- ``offset`` — смещение до цели. Если до неё меньше пикселя, персонаж пришёл.
- :godot:`Node2D.look_at()` поворачивает персонажа к цели.
- :godot:`Vector2.limit_length()` укорачивает вектор до заданной длины, если он
  длиннее. ``offset.limit_length(speed * delta)`` — шаг за кадр, но не дальше
  цели; делённый на ``delta``, он становится скоростью
  :godot:`CharacterBody2D.velocity`.
- :godot:`CharacterBody2D.move_and_slide()` двигает тело на ``velocity * delta`` и
  останавливает у стены.

Почему не просто ``direction_to(target) * speed``? Тогда шаг за кадр всегда
одинаковый, и у цели персонаж проскакивает её, разворачивается, снова
проскакивает — дрожит на месте. Ограничение шага последним кадром приводит его
точно в цель.

Персонаж идёт по прямой. Если на пути стена, он упрётся и будет скользить вдоль
неё, а щелчок за препятствие не обойдёт: для этого нужен поиск пути.

.. docs::

   - :manual:`Мышь и координаты <tutorials/inputs/mouse_and_input_coordinates>`
   - :manual:`Использование CharacterBody2D <tutorials/physics/using_character_body_2d>`
   - :manual:`События ввода <tutorials/inputs/inputevent>`
