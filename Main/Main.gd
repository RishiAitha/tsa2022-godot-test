extends Node

var moving
var currentTile
var currentPawn
var rolled = false
var roll
var validTiles = ["", ""]
var gameRound = 1
var turnsPassed = 0

var colors = ["Blue", "Red", "Yellow", "Green"]
var currentIndex = 0
var currentPlayer = colors[currentIndex]

func _ready():
	randomize()

func _process(delta):
	$TurnDisplay.text = currentPlayer

func _on_RollButton_pressed():
	if (!rolled):
		roll = randi() % 6 + 1
		rolled = true
		$RollDisplay.text = str(roll)

func _on_Tile_clicked(clickedTile):
	if (rolled && moving && (get_node(clickedTile).name in validTiles)):
		var tilePawn = pawnCheck(clickedTile)
		var moved = false
		
		if (tilePawn == null):
			get_node(currentPawn).position = get_node(clickedTile).position
			moving = false
			
			moved = true
		elif (get_node(currentPawn).color != tilePawn.color):
			var temp_pos = tilePawn.position
			tilePawn.position = get_node(currentPawn).position
			get_node(currentPawn).position = temp_pos
			
			moved = true
		
		if (moved):
			if (currentIndex < 3):
				currentIndex += 1
			else:
				currentIndex = 0
				turnsPassed += 1
			currentPlayer = colors[currentIndex]
			
			rolled = false
			
			var oppositeTile = get_node(get_node(clickedTile).opposite_tile)
			var oppositePawn = pawnCheck(oppositeTile.name)
			
			if (oppositePawn != null):
				if (oppositePawn.color != get_node(currentPawn).color):
					kill(get_node(currentPawn), oppositePawn)
				else:
					revive(get_node(currentPawn))

func _on_Pawn_clicked(clickedPawn):
	if (get_node(clickedPawn).color == currentPlayer):
		moving = true
		currentPawn = clickedPawn
		
		if (rolled):
			var currentTile = tileCheck(clickedPawn)
			
			var tileNum
			var backNum
			var forNum
			if (gameRound == 1):
				tileNum = int(currentTile.name.get_slice("-", 1))
				if (tileNum - roll < 1):
					backNum = 28 + (tileNum - roll)
				else:
					backNum = tileNum - roll
				if (tileNum + roll > 28):
					forNum = (tileNum + roll) - 28
				else:
					forNum = tileNum + roll
				
				var option1 = "1-" + str(backNum)
				var option2 = "1-" + str(forNum)
				
				validTiles = [option1, option2]

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

func kill(pawn, oppositePawn):
	print_debug(pawn.name + " || " + oppositePawn.name)

func revive(pawn):
	print_debug(pawn.name)

