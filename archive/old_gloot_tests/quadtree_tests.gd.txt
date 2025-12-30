extends TestSuite

const QuadTree = preload("res://addons/gloot/core/constraints/quadtree.gd")

func init_suite() -> void:
    tests = [
        "test_can_subdivide",
        "test_get_quadrant_rects",
        "test_constructor",
        "test_add",
        "test_remove",
        "test_get_first",
        "test_get_all",
    ]


func test_can_subdivide() -> void:
    assert(QuadTree.QtNode._can_subdivide(Vector2i(2, 2)))
    assert(QuadTree.QtNode._can_subdivide(Vector2i(5, 5)))
    assert(!QuadTree.QtNode._can_subdivide(Vector2i(1, 5)))
    assert(!QuadTree.QtNode._can_subdivide(Vector2i(5, 1)))
    assert(!QuadTree.QtNode._can_subdivide(Vector2i(1, 1)))


func test_get_quadrant_rects() -> void:
    var test_data := [
        {input = Rect2i(0, 0, 2, 2), expected = [Rect2i(0, 0, 1, 1), Rect2i(1, 0, 1, 1), Rect2i(0, 1, 1, 1), Rect2i(1, 1, 1, 1)]},
        {input = Rect2i(0, 0, 5, 5), expected = [Rect2i(0, 0, 3, 3), Rect2i(3, 0, 2, 3), Rect2i(0, 3, 3, 2), Rect2i(3, 3, 2, 2)]},
        {input = Rect2i(2, 2, 4, 4), expected = [Rect2i(2, 2, 2, 2), Rect2i(4, 2, 2, 2), Rect2i(2, 4, 2, 2), Rect2i(4, 4, 2, 2)]},
        {input = Rect2i(2, 2, 5, 5), expected = [Rect2i(2, 2, 3, 3), Rect2i(5, 2, 2, 3), Rect2i(2, 5, 3, 2), Rect2i(5, 5, 2, 2)]},
    ]

    for data in test_data:
        var quadrant_rects := QuadTree.QtNode._get_quadrant_rects(data.input)
        for i in range(quadrant_rects.size()):
            assert(quadrant_rects[i] == data.expected[i])


func test_constructor() -> void:
    var quadtree := QuadTree.new(Vector2i(42, 42))
    assert(quadtree._size == Vector2i(42, 42))


func test_add() -> void:
    var quadtree := QuadTree.new(Vector2i(4, 4))
    quadtree.add(Rect2i(0, 0, 1, 1), 42)
    assert(!quadtree.is_empty())
    assert(quadtree._root.qt_rects.size() == 1)
    assert(quadtree._root.quadrants[0] == null)
    assert(quadtree._root.quadrants[1] == null)
    assert(quadtree._root.quadrants[2] == null)
    assert(quadtree._root.quadrants[3] == null)

    quadtree.add(Rect2i(1, 1, 1, 1), 43)
    assert(!quadtree.is_empty())
    assert(quadtree._root.qt_rects.is_empty())
    assert(quadtree._root.quadrants[0] != null)
    assert(quadtree._root.quadrants[0].qt_rects.is_empty())
    assert(quadtree._root.quadrants[0].quadrants[0].qt_rects.size() == 1)
    assert(quadtree._root.quadrants[0].quadrants[1] == null)
    assert(quadtree._root.quadrants[0].quadrants[2] == null)
    assert(quadtree._root.quadrants[0].quadrants[3].qt_rects.size() == 1)
    assert(quadtree._root.quadrants[1] == null)
    assert(quadtree._root.quadrants[2] == null)
    assert(quadtree._root.quadrants[3] == null)


func test_remove() -> void:
    var quadtree := QuadTree.new(Vector2i(4, 4))
    quadtree.add(Rect2i(0, 0, 1, 1), 42)
    quadtree.add(Rect2i(1, 1, 1, 1), 43)
    quadtree.remove(42)
    assert(quadtree._root.quadrants[0] == null)
    assert(quadtree._root.quadrants[1] == null)
    assert(quadtree._root.quadrants[2] == null)
    assert(quadtree._root.quadrants[3] == null)
    assert(quadtree._root.qt_rects.size() == 1)
    assert(quadtree._root.qt_rects[0].metadata == 43)


func test_get_first() -> void:
    var quadtree := QuadTree.new(Vector2i(4, 4))
    quadtree.add(Rect2i(0, 0, 1, 1), 42)
    quadtree.add(Rect2i(1, 1, 1, 1), 43)

    var first := quadtree.get_first(Rect2i(0, 0, 2, 2))
    assert(first != null)
    assert(first.rect == Rect2i(0, 0, 1, 1))
    assert(first.metadata == 42)

    first = quadtree.get_first(Rect2i(0, 0, 2, 2), 42)
    assert(first != null)
    assert(first.rect == Rect2i(1, 1, 1, 1))
    assert(first.metadata == 43)
    
    first = quadtree.get_first(Vector2i(0, 0))
    assert(first != null)
    assert(first.rect == Rect2i(0, 0, 1, 1))
    assert(first.metadata == 42)

    first = quadtree.get_first(Vector2i(0, 0), 42)
    assert(first == null)


func test_get_all() -> void:
    var quadtree := QuadTree.new(Vector2i(4, 4))
    quadtree.add(Rect2i(0, 0, 1, 1), 42)
    quadtree.add(Rect2i(1, 1, 1, 1), 43)

    var all := quadtree.get_all(Rect2i(0, 0, 2, 2))
    assert(all.size() == 2)
    assert(all[0].rect == Rect2i(0, 0, 1, 1))
    assert(all[0].metadata == 42)
    assert(all[1].rect == Rect2i(1, 1, 1, 1))
    assert(all[1].metadata == 43)

    all = quadtree.get_all(Vector2i(1, 1))
    assert(all.size() == 1)
    assert(all[0].rect == Rect2i(1, 1, 1, 1))
    assert(all[0].metadata == 43)
