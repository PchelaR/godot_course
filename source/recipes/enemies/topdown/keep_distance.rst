Держать дистанцию
=================

Враг не лезет в ближний бой: подходит, если игрок далеко, отступает, если игрок
слишком близко, а на удобном расстоянии кружит вокруг него. Так ведут себя
стрелки, маги и лучники.

.. godot-demo:: recipes/enemies/keep_distance
   :title: Держать дистанцию

Два круга вокруг игрока — ближняя и дальняя граница. Враг старается держаться
между ними.


Сцена
-----

.. code-block:: text

   Recipe (Node2D)
   ├── Arena (экземпляр arena.tscn)
   ├── Player (CharacterBody2D) — управляется WASD
   │   ├── Near (Line2D) — круг радиусом 200
   │   └── Far (Line2D) — круг радиусом 320
   └── Enemy (CharacterBody2D) — скрипт keep_distance.gd
       ├── Shape (CollisionShape2D) — круг радиусом 18
       └── Look (Polygon2D) — стрелка, смотрящая вправо

- :godot:`CharacterBody2D` — :term:`физическое тело <Физическое тело>`; **Motion
  Mode** — **Floating**.
- ``arena.tscn`` — стены и :godot:`Camera2D`.
- В поле **Target** скрипта выберите ``Player``.


Скрипт
------

.. example:: recipes/enemies/keep_distance

Разбор:

- ``offset`` — вектор от врага к игроку, ``toward`` — то же направление длиной
  ``1``, ``distance`` — расстояние.
- Дальше ``max_distance`` — идём к игроку, ближе ``min_distance`` — от него.
- Между ними — вбок: :godot:`Vector2.orthogonal()` поворачивает вектор на
  четверть оборота. Двигаясь всегда поперёк направления на игрока, враг ходит
  вокруг него по кругу.
- :godot:`CharacterBody2D.get_slide_collision_count()` — сколько столкновений было
  в последнем ``move_and_slide()``. Упёрся в стену — кружит в другую сторону.
- :godot:`Node2D.look_at()` — враг всегда смотрит на игрока.


Настройка
---------

- ``min_distance`` и ``max_distance`` — границы удобного расстояния. Чем ближе
  они друг к другу, тем чаще враг будет дёргаться вперёд-назад.
- ``speed`` — скорость подхода и отступления, ``strafe_speed`` — кружения.

Стрельбы здесь нет: это отдельная механика, её добавляют отдельным скриптом или
узлом.

.. docs::

   - :manual:`Использование CharacterBody2D <tutorials/physics/using_character_body_2d>`
   - :manual:`Использование Area2D <tutorials/physics/using_area_2d>`
