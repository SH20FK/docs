extends SceneTree

func _init():
    print("Loading main.gd...")
    var p = load("res://mods/strategist/main.gd")
    if p:
        print("Success")
    else:
        print("Failed")
    quit()
