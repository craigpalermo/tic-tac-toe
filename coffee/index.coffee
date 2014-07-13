# Firebase refs
whoseTurnRef = new Firebase("https://t3.firebaseio.com/whoseTurn")
boxesRef = new Firebase("https://t3.firebaseio.com/boxes")
listRef = new Firebase("https://t3.firebaseio.com/presence/")
presenceRef = new Firebase("https://t3.firebaseio.com/.info/connected")
userRef = listRef.push()

# add user to presence list
presenceRef.on "value", (snap) ->
  if snap.val()
    userRef.set(true)
    userRef.onDisconnect().remove()

# update number of players on page
listRef.on "value", (snap) ->
  $('#players').html(parseInt(snap.numChildren()))

# game values
gameOver = false
movesMade = 0
youHaveMoved = false

# select player
whoseTurnRef.once 'value', (snapshot) ->
  player = snapshot.val()
  if player is 'X' then opponent = 'O' else opponent = 'X'
  $('#player').html player
  $('#opponent').html opponent

# returns X or O if either has won, null otherwise
getCell = (id) ->
  return $('#'+id).html()

# returns l if all three boxes contained l
checkRow = (l, boxes) ->
  if (getCell(boxes[0]) is l and getCell(boxes[1]) is l and getCell(boxes[2]) is l)
    return l
  else
    return null

reset = false

# returns X or O if a player won, null if not
checkForWinners = ->
  cols = [[1,2,3], [4,5,6], [7,8,9], [1,5,9], [3,5,7], [1,4,7], [2,5,8], [3,6,9]]
  for l in ['X','O']
    for i in cols
      winner = checkRow(l, i)
      if winner
        return winner
  return null

# update board every time a move is made
boxesRef.on 'value', (snapshot) ->
  movesMade = 0

  # iterate over each box
  snapshot.forEach (child) ->
    num = child.name()
    player = child.val()['player']

    if player isnt 'empty'
      $("#" + parseInt(num)).html player
      movesMade += 1
    else
      $("#" + parseInt(num)).html ''
    return

  # check if anyone won yet, alert if they did
  # !need to ignore checking this on resets!
  if not reset and youHaveMoved
    winner = checkForWinners()
    if winner
      vex.dialog.alert "#{winner} wins!"
      gameOver = true
    else if movesMade >= 9
      vex.dialog.alert "It's a draw!"
      gameOver = true

  # to cover the case when opponent resets, turn off our reset flag
  reset = false

# change the player at box
checkBox = (box) ->
  whoseTurnRef.once 'value', (snapshot) ->
    whoseTurn = snapshot.val()
    player = $('#player').html()

    # check if it's your turn
    if gameOver
      return

    if whoseTurn is player
      if $('#' + parseInt(box)).html() is 'X' or $('#' + parseInt(box)).html() is 'O'
        vex.dialog.alert "You can't move there!"
      else
        # update letter in selected box
        boxesRef.child(box).set({player: player})

        # update whose turn it is
        if player is 'X' then whoseTurn = 'O' else whoseTurn = 'X'
        $('#whoseTurn').html whoseTurn
        whoseTurnRef.set(whoseTurn)

        # you have moved
        youHaveMoved = true
    else
      vex.dialog.alert "It's not your turn yet!"

# returns O if you're X, and X otherwise
getOpponent = ->
	if $('#player').html() is 'X' then return 'O' else return 'X'

# resets all spaces to empty
clearBoard = ->
  # only allow reset if there are pieces on board
  if movesMade > 0
    for num in [1..9]
      # clear out table cell
      $('#' + parseInt(num)).html ''

      # set current player in cell to empty
      boxesRef.child(num).set({player:'empty'})

      # change whoseTurn to other player
      whoseTurnRef.once 'value', (snapshot) ->
        whoseTurn = snapshot.val()
        player = $('#player').html()
        opponent = getOpponent()
        if whoseTurn is player then whoseTurnRef.set(opponent) else whoseTurnRef.set(player)

  # reset game over flag
  gameOver = false

####################
# doc ready
####################

jQuery ($) ->
  $("#board td").on 'click', ->
    box = parseInt($(this).attr 'id')
    checkBox(box)

  $('#reset').on 'click', ->
    reset = true
    clearBoard()

  whoseTurnRef.on 'value', (snapshot) ->
    $('#whoseTurn').html snapshot.val()
