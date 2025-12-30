# PIS Input Test Scene

## Purpose
Test if the PIS (Programmed Input System) can successfully simulate keyboard and mouse inputs.

## Structure
```
scenes/pis_test/
├── pis_test.tscn          # Main test scene
├── pis_test.gd            # Test controller script
├── pis_input_test.json    # PIS test macro
└── README.md              # This file
```

## Test Cases

1. **Keyboard Action A** - Tests if PIS can trigger input action `test_button_a`
2. **Keyboard Action B** - Tests if PIS can trigger input action `test_button_b`
3. **Keyboard Action C** - Tests if PIS can trigger input action `test_button_c`
4. **Mouse Click** - Tests if PIS can simulate mouse button clicks on UI Controls

## How to Run

1. Open `pis_test.tscn` in Godot
2. Run the scene (F6)
3. Wait 2 seconds for auto-test to start
4. Watch the buttons activate and results update

## Expected Results

All 4 buttons should turn green with checkmarks:
- Button 1 ✓ ACTIVATED
- Button 2 ✓ ACTIVATED
- Button 3 ✓ ACTIVATED
- Mouse Click ✓ ACTIVATED

Results label should show: "Results: 4/4 tests passed" in green

## What This Tests

- ✅ PIS can simulate key press/release events
- ✅ PIS events trigger Godot's input action system
- ✅ PIS can simulate mouse movement
- ✅ PIS can simulate mouse button clicks
- ✅ UI Controls (Buttons) respond to PIS input

## Troubleshooting

**No buttons activate:**
- Check console for PIS_Manager errors
- Verify `pis_input_test.json` exists
- Check if CTS_CLI_Manager autoload is enabled

**Some buttons don't activate:**
- Check which specific inputs fail
- Keyboard working but not mouse = viewport/collision issue
- Mouse working but not keyboard = input action issue

**PIS Manager not found:**
- Verify CTS_CLI_Manager is in autoload list
- Check if PIS addon is enabled

## Next Steps

If this test passes:
- PIS input simulation works correctly
- Issue with entity context menu is Area2D/viewport specific
- Solution: Use Control nodes or _input() handler instead

If this test fails:
- PIS has fundamental issues
- Need to debug PIS event injection
- May need alternative input recording system
