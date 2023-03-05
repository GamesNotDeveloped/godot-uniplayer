class_name UP_PlayerBase
extends CharacterBody3D

## Godot Uniplayer character controller class.
##
## This class inherits from [CharacterBody3D].
## It provides an interface for handling inputs, abilities,
## and internal signalling.

## Emitted when controller should reset the state.
## For example, an ability responsible of killing the player
## should emit this signal. Abilities dependent on player's health should
## conenct to the signal and handle resetting their internal state.
signal reset

## Emitted when state of the [member controllable] is changed.
## Allows custom abilities to react immediately when player 
## loses or gains control over the character.
signal controllable_changed

## A list of movement abilities, which will be always called
## in each step of [method _process_physics].
## Abilities can override [method UP_BaseAbility._process_movement()].
var movement_abilities:Array[UP_BaseAbility] = []

## A list of control abilities, which will be called in [method _process_physics]
## only when [member controllable] is set to true.
## Abilities can override [method UP_BaseAbility._process_control()].
var control_abilities:Array[UP_BaseAbility] = []

## If true, the [member control_abilities] will be processed
## in each physics step.
var controllable := true:
    set(x):
        if not controllable == x:
            controllable = x
            controllable_changed.emit()
        

func _ready():
    reset.connect(_reset)
    
## Allows to register default input bindings at startup, instead of forcing
## an user to configuring inputs in the Project Settings. Default bindings 
## will be registered only when they aren't configured in the Project Settings.
##
## Each item must be an array of three variables:
## action_name, keycode, mouse_button. Where action_name is a [String],
## keycode is a [enum InputEvent.Key],
## mouse_button is a [enum InputEventMouseButton.MouseButton].
##
## Both keycode and mouse_button variables are nullable.
## Example initialization of a custom ability:
##
## [codeblock]
## func _ready():
##     super()
##     player.register_default_input_bindings([
##         ["move_forward", KEY_W, null],
##         ["move_backward", KEY_S, null],
##         ["shoot", null, MOUSE_BUTTON_LEFT]
##     ])
## [/codeblock]
func register_default_input_bindings(bindings:Array):
    for x in bindings:
        var action = x[0]
        var key = x[1]
        var mouse_button = x[2]
        
        if not InputMap.has_action(action):
            InputMap.add_action(action)
            if key:
                var ev = InputEventKey.new() as InputEventKey
                ev.keycode = key
                InputMap.action_add_event(action, ev)
            if mouse_button:
                var ev = InputEventMouseButton.new()
                ev.button_index = mouse_button
                InputMap.action_add_event(action, ev)

## Register an ability in the [member movement_abilities] list.
## Ability can override [member UP_BaseAbility._process_movement].
func register_movement_ability(ability:UP_BaseAbility):
    movement_abilities.append(ability)

## Register an ability in the [member control_abilities] list.
## Ability can override [member UP_BaseAbility._process_control].
func register_control_ability(ability:UP_BaseAbility):
    control_abilities.append(ability)


func _process_movement(delta:float):
    if controllable:
        for ability in control_abilities:
            ability._process_control(delta)
                    
    for ability in movement_abilities:
        ability._process_movement(delta)

    move_and_slide()

func _physics_process(delta:float):
    _process_movement(delta)

func _reset():
    velocity = Vector3.ZERO
    controllable = true
