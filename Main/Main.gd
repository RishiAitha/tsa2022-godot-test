#	TSA 2023 Video Game Design Project: Flip or Skip
#	
#	||---------------------------------------------------------------||
#	
#	Current Known Issues (commented where location of issue is known):
#		none! (for now)
#	
#	||---------------------------------------------------------------||
#	
#	To-Do:
#		Start menu (maybe choosing amount of players)
#		Make functions and instance vars more organized, delete excess
#		Sprites and animation
#		How to play
#		Add comments to code (again, I'll probably forget)
#		Lots of testing & bug fixes
#		Change testing values to release values

extends Node

export(PackedScene) var pawn_scene # used to create a new pawn child node when reviving

signal buttonsFinished(choice) # used to wait for input and action from multiple different button possibilities

var moving # is true while the player is in the middle of a move

# tracking pawns
var currentPawn # valid pawn that has been clicked to move (used to deal with invalid pawns clicked)
var oppositePawn # after a move, set to the pawn opposite of the current one

# tracking rolling and movement options
var rolled = false # is false and only true after a roll has occurred, after a move, it goes back to false
var roll # integer storing the roll number
var validTiles = ["", ""] # valid tiles that can be moved to based on the roll and currentPawn

# tracking rounds
var gameRound = 1 # the current game round
var cycles = 0 # the amount of full turn rotations gone, used to increment gameRound when all players have moved

# tracking tiles and pawns for specific uses
var tileCount = 28 # the total amount of tiles in play
var colorCount = 0 # the amount of pawns left in a certain color

# used for finding the next current player and managing which players are still in the game
var colors = ["Blue", "Red", "Yellow", "Green"] # current characters in play
var currentIndex = 0 # index used to increment the current player
var currentPlayer = colors[currentIndex] # current player color that can move

func _ready(): # ryns when the main scene is initialized into the scene tree
	randomize() # makes sure all numbers are random
	
	# hides correct tiles and buttons
	var tiles = get_tree().get_nodes_in_group("all_tiles")
	for tile in tiles:
		if (int(tile.name.get_slice("-", 0)) != 1):
			tile.hide()
	$FlipButton.hide()
	$ReviveButton.hide()
	$SkipButton.hide()
	$PlayAgain.hide()
	$MainMenu.hide()
	$EndingDisplay.text = ""

func _process(_delta): # runs every frame
	$TurnDisplay.text = "Current Turn: " + currentPlayer # displays the current player at all times

func _on_RollButton_pressed(): # runs when the roll button is pressed
	if (!rolled):
		if (gameRound != 4): # to make sure that rolls are adjusted for the smaller board
			roll = randi() % 6 + 1
		else:
			roll = randi() % 3 + 1
		rolled = true # shows that the roll is done
		$RollDisplay.text = "Roll: " + str(roll) # displaying the roll, which has been randomized

func _on_Pawn_clicked(clickedPawn): # runs when the pawn is clicked
	if (get_node(clickedPawn).color == currentPlayer): # if the pawn is the correct color
		moving = true # starting the move
		currentPawn = clickedPawn # setting the clickedPawn only if it is the correct color
		
		if (rolled): # if the player has rolled
			var checkTile = tileCheck(clickedPawn) # tile that the pawn is on
			
			# calculating the possible movement option tiles
			# note for later: when showing the valid tile sprites, make sure they show corresponding to the selected pawn and only if the tile is not covered by another pawn of the same color
			# (basically, only change the sprite of tiles that can actually be moved to for the selected pawn)
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

func _on_Tile_clicked(clickedTile): # runs when a tile is clicked
	if (rolled && moving && (get_node(clickedTile).name in validTiles)): # if you have rolled, selected a tile, and the clickedTile is a valid movement option
		var tilePawn = pawnCheck(clickedTile) # pawn that is on the tile
		var moved = false # the move hasn't ended yet, so it is set to false
		
		if (tilePawn == null): # if there isnt a pawn on the tile
			get_node(currentPawn).position = get_node(clickedTile).position # moving the pawn to that position
			moving = false # no longer in a move, so set to false
			
			moved = true # move is over, so set to true
		elif (get_node(currentPawn).color != tilePawn.color): # there is a pawn on the tile that is being moved too
			# swapping the piece positions
			var temp_pos = tilePawn.position
			tilePawn.position = get_node(currentPawn).position
			get_node(currentPawn).position = temp_pos
			
			moved = true # move is over, so set to true
		
		if (moved): # if the move is over
			rolled = false # the roll has not been set for the next move
			var oppositeTile = get_node(get_node(clickedTile).opposite_tile) # getting the opposite tile of the just finished move
			oppositePawn = pawnCheck(oppositeTile.name) # taking the opposite pawn as well
			
			if (oppositePawn != null): # if the opposite pawn exists
				if (oppositePawn.color != get_node(currentPawn).color): # if the opposite pawn is a different color
					# show buttons for flip to kill
					$FlipButton.show()
					$SkipButton.show()
					yield(self, "buttonsFinished") # wait for the buttons function to finish
				else: # the opposite pawn is the same color
					call_deferred("revive") # calling the revive function, this makes sure that the player should be allowed to revive
			
			updateColors() # updates which players still remain because pawns may have been killed
			
			# turn over
			
			# finding the last player alive
			var lastPlayer = "none"
			for color in colors:
				if (color != "dead"):
					lastPlayer = color
			
			# updating the cycles if the last player has moved
			if (currentIndex >= colors.find(lastPlayer)):
				cycles += 1
			
			# if the round is over
			if (cycles >= 1): # change to 3 after testing
				$RollButton.hide()
				yield(get_tree().create_timer(1), "timeout") # just to see what's happening easier, will replace with animations
				
				# updating values
				cycles = 0
				tileCount -= 8
				gameRound += 1
				
				if (gameRound > 4): # if there are no more rounds left, it should be a draw
					call_deferred("gameOver", "roundsOver")
				
				# killing pawns that are on unsafe squares
				var tiles = get_tree().get_nodes_in_group("all_tiles")
				for tile in tiles:
					var unsafePawn = pawnCheck(tile.name)
					
					if (unsafePawn != null && !tile.safe && int(tile.name.get_slice("-", 0)) == (gameRound - 1)):
						unsafePawn.queue_free()
				updateColors() # updates which players still remain because pawns may have been killed
				
				# showing the next round's tiles
				for tile in tiles:
					if (int(tile.name.get_slice("-", 0)) == gameRound):
						tile.show()
					else:
						tile.hide()
				
				# moving pawns to their new positions on the next round's tiles
				var pawns = get_tree().get_nodes_in_group("all_pawns")
				
				for pawn in pawns:
					if (!pawn.is_queued_for_deletion()):
						for tile in tiles:
							var tileRound = int(tile.name.get_slice("-", 0))
							if (((pawn.color in tile.spawn) || tile.spawn == "everything") && pawnCheck(tile.name) == null && tileRound == gameRound):
								pawn.position = tile.position
								break
				
				$RollButton.show()
			
			# incrementing the current player at the end of a move, after everything has been updated and is ready for the next turn
			var increment = 0
			while(currentPlayer == "dead" || increment == 0):
				if (currentIndex < 3):
					currentIndex += 1
				else:
					currentIndex = 0
				currentPlayer = colors[currentIndex]
				increment = 1

func revive(): # called to check if the revive should happen or not (technically could be put directly in the tile signal method)
	var pawn = get_node(currentPawn)
	var pawns = get_tree().get_nodes_in_group("all_pawns")
	var tiles = get_tree().get_nodes_in_group("all_tiles")
	colorCount = 0
	for forPawn in pawns:
		if (forPawn.color == pawn.color && !forPawn.is_queued_for_deletion()):
			colorCount += 1
	if (colorCount < 4 && gameRound < 4): # you can't revive on the last round
		$ReviveButton.show() # shows the option to revive if there is space for another pawn of the color
		yield(self, "buttonsFinished") # waits for the button function to be done

func _on_FlipButton_pressed(): # when the flip to kill option is chosen
	# chooses the flip, displays the info, queues the correct pawn for deletion, and waits for one frame to delete the pawn
	var flip = randi() % 2 + 1
	if (flip == 1):
		$FlipDisplay.text = "Flip: Heads!"
		oppositePawn.queue_free()
		yield(get_tree(), "idle_frame")
	else:
		$FlipDisplay.text = "Flip: Tails :("
		get_node(currentPawn).queue_free()
		yield(get_tree(), "idle_frame")
	
	# hides buttons and emits signals saying that the buttons are done
	$FlipButton.hide()
	$SkipButton.hide()
	emit_signal("buttonsFinished", "flipped")

func _on_ReviveButton_pressed(): # when the revive options is chosen
	var pawn = get_node(currentPawn)
	var tiles = get_tree().get_nodes_in_group("all_tiles")
	
	# flips to see if the revive happens, and does corresponding changes
	var flip = randi() % 2 + 1
	if (flip == 1): # if the flip is heads
		$FlipDisplay.text = "Flip: Heads!" # displays the flip
		
		# creates a new pawn and sets the values
		var newPawn = pawn_scene.instance()
		newPawn.name = pawn.color + str(colorCount + 1)
		newPawn.color = pawn.color
		newPawn.connect("clicked", self, "_on_Pawn_clicked")
		var defaultPos = Vector2(0, 0)
		newPawn.position = defaultPos
		
		# sets the new pawn's starting position
		for tile in tiles:
			var tileRound = int(tile.name.get_slice("-", 0))
			if (((pawn.color in tile.spawn) || tile.spawn == "everything") && pawnCheck(tile.name) == null && tileRound == gameRound):
				newPawn.position = tile.position
				break
		
		if (newPawn.position == defaultPos):
			for tile in tiles:
				var tileRound = int(tile.name.get_slice("-", 0))
				if (pawnCheck(tile.name) == null && tileRound == gameRound):
					newPawn.position = tile.position
					break
		
		if (newPawn.position != defaultPos):
			add_child(newPawn)
	else:
		$FlipDisplay.text = "Flip: Tails :("
	
	# hides buttons and emits the signal saying that the buttons are done
	$ReviveButton.hide()
	$SkipButton.hide()
	emit_signal("buttonsFinished", "revived")

func _on_SkipButton_pressed(): # if the player chooses to skip instead of flipping
	# hides all the buttons and emits the signal saying that the buttons are done
	$FlipButton.hide()
	$ReviveButton.hide()
	$SkipButton.hide()
	emit_signal("buttonsFinished", "skipped")

func _on_PlayAgain_pressed():
	get_tree().reload_current_scene()
	emit_signal("buttonsFinished", "playagain")

func _on_MainMenu_pressed():
	$PlayAgain.hide()
	$MainMenu.hide()
	emit_signal("buttonsFinished", "mainmenu")

func pawnCheck(tile): # gets the pawn on the given tile name, if it doesn't exist, then it returns null
	var pawns = get_tree().get_nodes_in_group("all_pawns")
	for pawn in pawns:
		if (get_node(tile).position == pawn.position):
			return pawn
	
	return null

func tileCheck(pawn): # gets the tile that the given pawn name is on, if it doesn't exist (it should), then it returns null
	var tiles = get_tree().get_nodes_in_group("all_tiles")
	for tile in tiles:
		if (get_node(pawn).position == tile.position):
			return tile
	
	return null

func updateColors(): # updates the current players based on if there are any pawns alive
	var colorsLeft = [false, false, false, false] # array to see which players are alive
	var pawns = get_tree().get_nodes_in_group("all_pawns")
	for pawn in pawns:
		if (!pawn.is_queued_for_deletion()): # to make sure the pawn isn't being deleted
			# checks if the pawn is a certain color, to see if the color has any pawns alive
			if (pawn.color == "Blue"):
				colorsLeft[0] = true
			elif (pawn.color == "Red"):
				colorsLeft[1] = true
			elif (pawn.color == "Yellow"):
				colorsLeft[2] = true
			elif (pawn.color == "Green"):
				colorsLeft[3] = true
	
	# updates the remaining colors array based on which players are alive
	# also counts the amount of remaining players left in the game
	var i = 0
	var remainingPlayers = 0
	for color in colorsLeft:
		if (color == false):
			colors[i] = "dead"
		else:
			remainingPlayers += 1
		i += 1
	
	if (remainingPlayers == 1): # if there is one player left, they win
		call_deferred("gameOver", "winner")
	elif (remainingPlayers == 0): # if there are no players left, it is a draw
		call_deferred("gameOver", "allDead")

func gameOver(reason): # called when the game ends, taking the reason that the game ended
	$RollButton.hide()
	
	for child in self.get_children():
		child.hide()
	
	$EndingDisplay.show()
	if (reason == "winner"):
		var winner = ""
		for color in colors:
			if (color != "dead"):
				winner = color
		$EndingDisplay.text = "Winner: " + winner
	elif (reason == "allDead"):
		$EndingDisplay.text = "Draw: Everyone Ran Out of Pawns"
	elif (reason == "roundsOver"):
		$EndingDisplay.text = "Draw: Last Round Ended Without a Winner"
	
	$PlayAgain.show()
	$MainMenu.show()
	
	yield(self, "buttonsFinished")
