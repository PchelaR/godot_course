Godot: нулевой уровень
======================

.. container:: hero

   .. rst-class:: hero-lead

   Документация по движку Godot 4.7 и языку GDScript на русском языке. Каждый
   раздел сопровождается примерами, которые можно скачать и открыть в редакторе.
   Материал рассчитан на читателей без опыта программирования и работы с игровыми
   движками.

   .. container:: hero-actions

      .. link-button:: intro/install

         Начать с установки

      .. link-button:: gdscript/first_script
         :secondary:

         Первый скрипт

.. godot-demo:: showcase
   :title: Нулевой квартал
   :hint: Машины, жители, светофоры, стрельба и полиция — на одних простых фигурах. WASD — ходьба и руль, мышь — прицел, ЛКМ — огонь, E — сесть в машину или угнать чужую, пробел — ручник.
   :touch-hint: Машины, жители, светофоры, стрельба и полиция — на одних простых фигурах. Стик под экраном — ходьба и руль, кнопки — огонь, посадка в машину и ручник.

.. grid:: 1 1 2 2
   :gutter: 3

   .. grid-item-card:: 0. Знакомство с Godot
      :link: intro/index
      :link-type: doc

      Устройство движка, сравнение с Unity и Unreal Engine, язык GDScript,
      установка.

   .. grid-item-card:: 1. GDScript
      :link: gdscript/index
      :link-type: doc

      Синтаксис языка: переменные, типы, операторы, условия, циклы, функции,
      массивы, словари, строки, перечисления и классы.

   .. grid-item-card:: 2. Основы Godot
      :link: basics/index
      :link-type: doc

      Связь скрипта и узла, сцены, обращение к узлам, координаты, ввод, сигналы,
      создание объектов из кода.

   .. grid-item-card:: 3. Разработка простой игры
      :link: game/index
      :link-type: doc

      Аналог Pac-Man от замысла до экспорта: движение по клеткам, враги со
      своим характером, интерфейс.

   .. grid-item-card:: 4. Разработка игры посложнее
      :link: defense/index
      :link-type: doc

      Tower defense по мотивам Kingdom Rush: волны врагов, три вида башен,
      деньги, звёзды за прохождение и выбор уровня.

   .. grid-item-card:: 5. Рецепты
      :link: recipes/index
      :link-type: doc

      Готовые приёмы для своих игр: движение персонажа в разных жанрах, враги,
      камера и другие механики.

.. toctree::
   :hidden:
   :caption: Содержание

   intro/index
   gdscript/index
   basics/index
   game/index
   defense/index
   recipes/index

.. toctree::
   :hidden:
   :caption: Справочник

   appendix/glossary
   appendix/trophies
