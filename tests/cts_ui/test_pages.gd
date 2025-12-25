extends GutTest

## Tests for PlayerBook pages

var event_bus: Node
var mock_data_provider: Node

func before_each():
	event_bus = Node.new()
	add_child_autofree(event_bus)
	
	mock_data_provider = Node.new()
	add_child_autofree(mock_data_provider)

## BookPage Tests

func test_book_page_creation():
	var page = BookPage.new()
	add_child_autofree(page)
	
	assert_not_null(page, "BookPage should be created")
	assert_eq(page.page_title, "Page", "Should have default title")

func test_book_page_setup():
	var page = BookPage.new()
	add_child_autofree(page)
	
	# Base class setup should not throw errors
	page.setup(event_bus, mock_data_provider)
	
	assert_not_null(page, "Page should exist after setup")

## InventoryGridPage Tests

func test_inventory_grid_page_creation():
	var page = InventoryGridPage.new()
	add_child_autofree(page)
	
	await get_tree().process_frame
	
	assert_not_null(page, "InventoryGridPage should be created")
	assert_not_null(page._grid, "Grid should be created")
	assert_not_null(page._search_bar, "Search bar should be created")

func test_inventory_grid_page_setup():
	var page = InventoryGridPage.new()
	add_child_autofree(page)
	
	await get_tree().process_frame
	
	# Setup without inventory container (should not crash)
	page.setup(event_bus, mock_data_provider)
	
	assert_not_null(page._grid, "Grid should still exist after setup")

## EquipmentPage Tests

func test_equipment_page_creation():
	var page = EquipmentPage.new()
	add_child_autofree(page)
	
	await get_tree().process_frame
	
	assert_not_null(page, "EquipmentPage should be created")
	assert_not_null(page._slots_container, "Slots container should be created")

func test_equipment_page_setup():
	var page = EquipmentPage.new()
	add_child_autofree(page)
	
	await get_tree().process_frame
	
	# Setup without equipment container (should not crash)
	page.setup(event_bus, mock_data_provider)
	
	assert_not_null(page._slots_container, "Slots container should still exist")

## CharacterSheetPage Tests

func test_character_sheet_page_creation():
	var page = CharacterSheetPage.new()
	add_child_autofree(page)
	
	await get_tree().process_frame
	
	assert_not_null(page, "CharacterSheetPage should be created")
	assert_not_null(page._stats_container, "Stats container should be created")

func test_character_sheet_page_setup():
	var page = CharacterSheetPage.new()
	add_child_autofree(page)
	
	await get_tree().process_frame
	
	# Setup without stats container (should not crash)
	page.setup(event_bus, mock_data_provider)
	
	assert_not_null(page._stats_container, "Stats container should still exist")
	assert_not_null(page._binding, "Binding should be created")
