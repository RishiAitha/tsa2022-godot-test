#	TSA 2023 Video Game Design Project
#	
#	||---------------------------------------------------------------||
#	
#	Current Known Issues (commented where location of issue is known):
#		"opposite tile check" to see whether or not to run flip to kill is failing and switching to revive for some unknown reason
#		(or could be an issue with displaying the wrong buttons)
#		
#		getting null currentPawn when swapping positions
#	
#	||---------------------------------------------------------------||
#	
#	To-Do:
#		Add comments to code
#		Implement game over
#		Start menu (maybe choosing amount of players)
#		Make functions and instance vars more organized, delete excess
#		Sprites and animation
#		Add comments to code (again, I'll probably forget)
#		Lots of testing & bug fixes
#		Change testing values to release values

extends Node

export(PackedScene) var pawn_scene

signal buttonsFinished(choice)
signal reviveFinished

var moving
var currentTile
var oppositeTile
var currentPawn
var oppositePawn
var rolled = false
var roll
var validTiles = ["", ""]
var gameRound = 1
var tileCount = 28
var colorCount = 0
var cycles = 0
var debug = 0

var colors = ["Blue", "Red", "Yellow", "Green"]
var currentIndex = 0
var currentPlayer = colors[currentIndex]

func _ready():
	randomize()
	var tiles = get_tree().get_nodes_in_group("all_tiles")
	for tile in tiles:
		if (int(tile.name.get_slice("-", 0)) != 1):
			tile.hide()
	$FlipButton.hide()
	$ReviveButton.hide()
	$PassButton.hide()

func _process(_delta):
	$TurnDisplay.text = "Current Turn: " + currentPlayer

func _on_RollButton_pressed():
	if (!rolled):
		if (gameRound != 4):
			roll = randi() % 6 + 1
		else:
			roll = randi() % 3 + 1
		rolled = true
		$RollDisplay.text = "Roll: " + str(roll)

func _on_Pawn_clicked(clickedPawn):
	if (get_node(clickedPawn).color == currentPlayer):
		moving = true
		currentPawn = clickedPawn
		
		if (rolled):
			var checkTile = tileCheck(clickedPawn)
			
			var tileNum
			var backNum
			var forNum
			
			tileNum = int(checkTile.name.get_slice("-", 1))
			if (tileNum - roll < 1):
				backNum = tileCount + (tileNum - roll)
			else:
				backNum = tileNum - roll
			if (tileNum + roll > tileCount):
				forNum = (tileNum + roll) - tileCount
			else:
				forNum = tileNum + roll
			
			var option1 = str(gameRound) + "-" + str(backNum)
			var option2 = str(gameRound) + "-" + str(forNum)
			
			validTiles = [option1, option2]

func _on_Tile_clicked(clickedTile):
	currentTile = clickedTile
	if (rolled && moving && (get_node(clickedTile).name in validTiles)):
		var tilePawn = pawnCheck(clickedTile)
		var moved = false
		
		if (tilePawn == null):
			get_node(currentPawn).position = get_node(clickedTile).position
			moving = false
			
			moved = true
		elif (get_node(currentPawn).color != tilePawn.color): # null value sometimes for unknown reason
			var temp_pos = tilePawn.position
			tilePawn.position = get_node(currentPawn).position
			get_node(currentPawn).position = temp_pos
			
			moved = true
		
		if (moved):
			rolled = false
			oppositeTile = get_node(get_node(clickedTile).opposite_tile)
			oppositePawn = pawnCheck(oppositeTile.name)
			
			if (oppositePawn != null):
				if (oppositePawn.color != get_node(currentPawn).color): # error: failing sometimes for no reason
					$FlipButton.show()
					$PassButton.show()
					yield(self, "buttonsFinished")
				else:
					revive()
					yield(self, "reviveFinished")
			
			updateColors()
			
			# turn over
			
			var lastPlayer = "none"
			for color in colors:
				if (color != "dead"):
					lastPlayer = color
			debug += 1
			
			if (currentPlayer == lastPlayer):
				cycles += 1
			
			if (cycles >= 1): # change to 3 after testing
				yield(get_tree().create_timer(1), "timeout") # just to see what's happening easier
				cycles = 0
				gameRound += 1
				tileCount -= 8
				var tiles = get_tree().get_nodes_in_group("all_tiles")
				for tile in tiles:
					var unsafePawn = pawnCheck(tile.name)
					
					if (unsafePawn != null && !tile.safe && int(tile.name.get_slice("-", 0)) == (gameRound - 1)):
						unsafePawn.queue_free()
				updateColors()
				
				for tile in tiles:
					if (int(tile.name.get_slice("-", 0)) == gameRound):
						tile.show()
					else:
						tile.hide()
				
				var pawns = get_tree().get_nodes_in_group("all_pawns")
				
				for pawn in pawns:
					if (!pawn.is_queued_for_deletion()):
						for tile in tiles:
							var tileRound = int(tile.name.get_slice("-", 0))
							if (((pawn.color in tile.spawn) || tile.spawn == "everything") && pawnCheck(tile.name) == null && tileRound == gameRound):
								pawn.position = tile.position
								break
			
			var increment = 0
			while(currentPlayer == "dead" || increment == 0):
				if (currentIndex < 3):
					currentIndex += 1
				else:
					currentIndex = 0
				currentPlayer = colors[currentIndex]
				increment = 1

func revive():
	var pawn = get_node(currentPawn)
	var pawns = get_tree().get_nodes_in_group("all_pawns")
	var tiles = get_tree().get_nodes_in_group("all_tiles")
	colorCount = 0
	for forPawn in pawns:
		if (forPawn.color == pawn.color && !forPawn.is_queued_for_deletion()):
			colorCount += 1
	if (colorCount < 4):
		$ReviveButton.show()
		yield(self, "buttonsFinished")
	emit_signal("reviveFinished")

func _on_FlipButton_pressed():
	var flip = randi() % 2 + 1
	if (flip == 1):
		$FlipDisplay.text = "Flip: Heads!"
		oppositePawn.queue_free()
		yield(get_tree(), "idle_frame")
	else:
		$FlipDisplay.text = "Flip: Tails :("
		get_node(currentPawn).queue_free()
		yield(get_tree(), "idle_frame")
	
	$FlipButton.hide()
	$PassButton.hide()
	emit_signal("buttonsFinished", "flipped")

func _on_ReviveButton_pressed():
	var pawn = get_node(currentPawn)
	var tiles = get_tree().get_nodes_in_group("all_tiles")
	
	var flip = randi() % 2 + 1
	if (flip == 1):
		$FlipDisplay.text = "Flip: Heads!"
		var newPawn = pawn_scene.instance()
		newPawn.name = pawn.color + str(colorCount + 1)
		newPawn.color = pawn.color
		newPawn.connect("clicked", self, "_on_Pawn_clicked")

		for tile in tiles:
			var tileRound = int(tile.name.get_slice("-", 0))
			if (((pawn.color in tile.spawn) || tile.spawn == "everything") && pawnCheck(tile.name) == null && tileRound == gameRound):
				newPawn.position = tile.position
				add_child(newPawn)
				break
	else:
		$FlipDisplay.text = "Flip: Tails :("
	
	$ReviveButton.hide()
	$PassButton.hide()
	emit_signal("buttonsFinished", "revived")

func _on_PassButton_pressed():
	$FlipButton.hide()
	$ReviveButton.hide()
	$PassButton.hide()
	emit_signal("buttonsFinished", "passed")

func pawnCheck(tile):
	var pawns = get_tree().get_nodes_in_group("all_pawns")
	for pawn in pawns:
		if (get_node(tile).position == pawn.position):
			return pawn
	
	return null

func tileCheck(pawn):
	var tiles = get_tree().get_nodes_in_group("all_tiles")
	for tile in tiles:
		if (get_node(pawn).position == tile.position):
			return tile
	
	return null

func updateColors():
	var colorsLeft = [false, false, false, false]
	var pawns = get_tree().get_nodes_in_group("all_pawns")
	for pawn in pawns:
		if (!pawn.is_queued_for_deletion()):
			if (pawn.color == "Blue"):
				colorsLeft[0] = true
			elif (pawn.color == "Red"):
				colorsLeft[1] = true
			elif (pawn.color == "Yellow"):
				colorsLeft[2] = true
			elif (pawn.color == "Green"):
				colorsLeft[3] = true
	
	var i = 0
	for color in colorsLeft:
		if (color == false):
			colors[i] = "dead"
		i += 1
	print_debug(colors)

func game_over(reason):
	print_debug(str(reason))
