-- main.lua - Balatro Chess Step 4: Enemy Piece System

function love.load()
    -- Game constants
    BOARD_SIZE = 8
    TILE_SIZE = 60
    BOARD_OFFSET_X = 100
    BOARD_OFFSET_Y = 50
    PIECES_ON_BOARD = 3  -- Number of pieces drawn from deck
    ENEMY_PIECES_ON_BOARD = 5  -- Number of enemy pieces to place
    MAX_MOVES = 4  -- Maximum moves per round
    MAX_DISCARDS = 3  -- Maximum discards per round
    
    -- Colors
    LIGHT_TILE = {0.9, 0.9, 0.8}  -- Light beige
    DARK_TILE = {0.6, 0.4, 0.3}   -- Dark brown
    GRID_COLOR = {0.2, 0.2, 0.2}  -- Dark gray for grid lines
    BG_COLOR = {0.1, 0.15, 0.2}   -- Dark blue background
    PIECE_COLOR = {0.2, 0.6, 1.0} -- Blue for player pieces
    ENEMY_COLOR = {1.0, 0.3, 0.3} -- Red for enemy pieces
    SELECTED_COLOR = {1.0, 1.0, 0.0} -- Yellow for selected piece
    VALID_MOVE_COLOR = {0.0, 1.0, 0.0, 0.5} -- Green for valid moves
    CAPTURE_COLOR = {1.0, 0.5, 0.0, 0.7} -- Orange for capturable enemies
    
    -- Piece definitions with base stats
    PIECE_STATS = {
        pawn = {chips = 5, mult = 1, symbol = "P"},
        rook = {chips = 25, mult = 2, symbol = "R"},
        knight = {chips = 15, mult = 3, symbol = "N"},
        bishop = {chips = 20, mult = 2, symbol = "B"},
        queen = {chips = 60, mult = 6, symbol = "Q"},
        king = {chips = 10, mult = 4, symbol = "K"}
    }
    
    -- Enemy piece definitions (they only have chip values for scoring)
    ENEMY_STATS = {
        pawn = {chips = 10, symbol = "p"},
        rook = {chips = 30, symbol = "r"},
        knight = {chips = 20, symbol = "n"},
        bishop = {chips = 25, symbol = "b"},
        queen = {chips = 50, symbol = "q"},
        king = {chips = 40, symbol = "k"}
    }
    
    -- Game state
    gameState = "playing"
    selectedPiece = nil -- {row, col} of selected piece
    validMoves = {} -- Array of valid move positions
    score = 0
    lastCapture = nil -- Store info about last capture for display
    captureHistory = {} -- Track all captures this round
    movesLeft = MAX_MOVES
    discardsLeft = MAX_DISCARDS
    discardMode = false -- Whether we're in discard mode
    
    -- Initialize game data
    initializeGame()
    
    -- Set window title
    love.window.setTitle("Balatro Chess")
    
    -- Set background color
    love.graphics.setBackgroundColor(BG_COLOR)
end

function initializeGame()
    -- Create standard deck (16 pieces)
    deck = {}
    -- 8 pawns, 2 rooks, 2 knights, 2 bishops, 1 queen, 1 king
    for i = 1, 8 do table.insert(deck, "pawn") end
    for i = 1, 2 do table.insert(deck, "rook") end
    for i = 1, 2 do table.insert(deck, "knight") end
    for i = 1, 2 do table.insert(deck, "bishop") end
    table.insert(deck, "queen")
    table.insert(deck, "king")
    
    -- Shuffle deck
    shuffleDeck()
    
    -- Initialize board (empty)
    board = {}
    for row = 1, BOARD_SIZE do
        board[row] = {}
        for col = 1, BOARD_SIZE do
            board[row][col] = nil
        end
    end
    
    -- Draw initial pieces to board
    drawPiecesToBoard()
    
    -- Place enemy pieces
    placeEnemyPieces()
    
    -- Reset score and capture history
    score = 0
    lastCapture = nil
    captureHistory = {}
    movesLeft = MAX_MOVES
    discardsLeft = MAX_DISCARDS
    discardMode = false
end

function shuffleDeck()
    for i = #deck, 2, -1 do
        local j = math.random(i)
        deck[i], deck[j] = deck[j], deck[i]
    end
end

function drawPiecesToBoard()
    local piecesPlaced = 0
    
    while piecesPlaced < PIECES_ON_BOARD and #deck > 0 do
        -- Find random empty position on board
        local attempts = 0
        local row, col
        
        repeat
            row = math.random(1, BOARD_SIZE)
            col = math.random(1, BOARD_SIZE)
            attempts = attempts + 1
        until board[row][col] == nil or attempts > 100
        
        if attempts <= 100 then
            -- Place piece from deck
            local pieceType = table.remove(deck, 1) -- Take from top of deck
            board[row][col] = {
                type = pieceType,
                chips = PIECE_STATS[pieceType].chips,
                mult = PIECE_STATS[pieceType].mult,
                isPlayer = true
            }
            piecesPlaced = piecesPlaced + 1
        else
            break -- Safety break if board is full
        end
    end
end

function placeEnemyPieces()
    local enemyTypes = {"pawn", "pawn", "pawn", "rook", "knight", "bishop", "queen", "king"}
    local enemiesPlaced = 0
    
    while enemiesPlaced < ENEMY_PIECES_ON_BOARD and enemiesPlaced < #enemyTypes do
        -- Find random empty position on board
        local attempts = 0
        local row, col
        
        repeat
            row = math.random(1, BOARD_SIZE)
            col = math.random(1, BOARD_SIZE)
            attempts = attempts + 1
        until board[row][col] == nil or attempts > 100
        
        if attempts <= 100 then
            -- Place enemy piece
            local enemyType = enemyTypes[enemiesPlaced + 1]
            board[row][col] = {
                type = enemyType,
                chips = ENEMY_STATS[enemyType].chips,
                isPlayer = false,
                isEnemy = true
            }
            enemiesPlaced = enemiesPlaced + 1
        else
            break -- Safety break if board is full
        end
    end
    
    print("Placed " .. enemiesPlaced .. " enemy pieces")
end

function love.update(dt)
    -- Game update logic will go here
end

function love.draw()
    -- Draw the chess board
    drawBoard()
    
    -- Draw UI info
    drawUI()
end

function drawBoard()
    -- Draw board tiles
    for row = 1, BOARD_SIZE do
        for col = 1, BOARD_SIZE do
            local x = BOARD_OFFSET_X + (col - 1) * TILE_SIZE
            local y = BOARD_OFFSET_Y + (row - 1) * TILE_SIZE
            
            -- Alternate tile colors (checkerboard pattern)
            if (row + col) % 2 == 0 then
                love.graphics.setColor(LIGHT_TILE)
            else
                love.graphics.setColor(DARK_TILE)
            end
            
            -- Highlight selected piece
            if selectedPiece and selectedPiece.row == row and selectedPiece.col == col then
                love.graphics.setColor(SELECTED_COLOR)
            end
            
            -- Draw tile
            love.graphics.rectangle("fill", x, y, TILE_SIZE, TILE_SIZE)
            
            -- Draw valid move highlights
            if isValidMove(row, col) then
                local piece = board[row][col]
                if piece and piece.isEnemy then
                    -- Highlight capturable enemy pieces differently
                    love.graphics.setColor(CAPTURE_COLOR)
                else
                    love.graphics.setColor(VALID_MOVE_COLOR)
                end
                love.graphics.rectangle("fill", x, y, TILE_SIZE, TILE_SIZE)
            end
            
            -- Draw grid lines
            love.graphics.setColor(GRID_COLOR)
            love.graphics.rectangle("line", x, y, TILE_SIZE, TILE_SIZE)
            
            -- Draw piece if present
            local piece = board[row][col]
            if piece then
                drawPiece(piece, x, y)
            end
        end
    end
end

function drawPiece(piece, x, y)
    -- Set piece color based on type
    if piece.isPlayer then
        love.graphics.setColor(PIECE_COLOR)
    elseif piece.isEnemy then
        love.graphics.setColor(ENEMY_COLOR)
    end
    
    -- Draw piece background circle
    local centerX = x + TILE_SIZE / 2
    local centerY = y + TILE_SIZE / 2
    love.graphics.circle("fill", centerX, centerY, TILE_SIZE / 3)
    
    -- Draw piece symbol
    love.graphics.setColor(1, 1, 1) -- White text
    love.graphics.setFont(love.graphics.newFont(20))
    local symbol
    if piece.isPlayer then
        symbol = PIECE_STATS[piece.type].symbol
    elseif piece.isEnemy then
        symbol = ENEMY_STATS[piece.type].symbol
    end
    
    local textWidth = love.graphics.getFont():getWidth(symbol)
    local textHeight = love.graphics.getFont():getHeight()
    love.graphics.print(symbol, centerX - textWidth/2, centerY - textHeight/2)
    
    -- Draw stats below piece (small text)
    love.graphics.setFont(love.graphics.newFont(10))
    local statsText
    if piece.isPlayer then
        statsText = piece.chips .. "c/" .. piece.mult .. "m"
    elseif piece.isEnemy then
        statsText = piece.chips .. "c"
    end
    local statsWidth = love.graphics.getFont():getWidth(statsText)
    love.graphics.print(statsText, centerX - statsWidth/2, centerY + 15)
end

function drawUI()
    -- Reset color to white for text
    love.graphics.setColor(1, 1, 1)
    
    -- Draw title
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.print("Balatro Chess", 10, 10)
    
    -- Draw score with enhanced display
    love.graphics.setFont(love.graphics.newFont(20))
    love.graphics.setColor(0.2, 1.0, 0.2) -- Green for score
    love.graphics.print("Score: " .. score, 300, 10)
    
    -- Draw moves and discards counter
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.setColor(0.8, 0.8, 1.0) -- Light blue
    love.graphics.print("Moves: " .. movesLeft .. "/" .. MAX_MOVES, 500, 10)
    love.graphics.print("Discards: " .. discardsLeft .. "/" .. MAX_DISCARDS, 500, 30)
    
    -- Show current mode
    if discardMode then
        love.graphics.setColor(1.0, 0.8, 0.2) -- Orange for discard mode
        love.graphics.print("DISCARD MODE", 500, 50)
    else
        love.graphics.setColor(0.2, 1.0, 0.2) -- Green for move mode
        love.graphics.print("MOVE MODE", 500, 50)
    end
    
    -- Draw last capture info
    if lastCapture then
        love.graphics.setFont(love.graphics.newFont(14))
        love.graphics.setColor(1.0, 0.8, 0.2) -- Gold for capture info
        local captureText = "Last: " .. lastCapture.playerPiece .. " × " .. lastCapture.enemyPiece .. 
                           " = " .. lastCapture.chips .. " × " .. lastCapture.mult .. " = " .. lastCapture.score
        love.graphics.print(captureText, 300, 70)
    end
    
    -- Reset color to white
    love.graphics.setColor(1, 1, 1)
    
    -- Draw board coordinates for testing
    love.graphics.setFont(love.graphics.newFont(12))
    
    -- Column labels (a-h)
    for col = 1, BOARD_SIZE do
        local x = BOARD_OFFSET_X + (col - 1) * TILE_SIZE + TILE_SIZE/2 - 5
        local y = BOARD_OFFSET_Y + BOARD_SIZE * TILE_SIZE + 10
        love.graphics.print(string.char(96 + col), x, y) -- 'a' + col
    end
    
    -- Row labels (1-8)
    for row = 1, BOARD_SIZE do
        local x = BOARD_OFFSET_X - 20
        local y = BOARD_OFFSET_Y + (row - 1) * TILE_SIZE + TILE_SIZE/2 - 6
        love.graphics.print(tostring(9 - row), x, y) -- Chess notation (8 at top)
    end
    
    -- Game info
    love.graphics.print("Deck remaining: " .. #deck, 10, 550)
    local playerPieces, enemyPieces = countPiecesOnBoard()
    love.graphics.print("Player pieces: " .. playerPieces .. " | Enemy pieces: " .. enemyPieces, 10, 570)
    
    -- Show total enemy chips available
    local totalEnemyChips = getTotalEnemyChips()
    love.graphics.print("Total enemy chips: " .. totalEnemyChips, 200, 570)
    
    -- Selection info
    if selectedPiece then
        local piece = board[selectedPiece.row][selectedPiece.col]
        love.graphics.print("Selected: " .. piece.type .. " (" .. #validMoves .. " valid moves)", 10, 590)
        -- Show potential capture scores
        love.graphics.setColor(0.8, 0.8, 1.0) -- Light blue
        love.graphics.print("Potential score: " .. piece.chips .. " × " .. piece.mult .. " = " .. (piece.chips * piece.mult), 250, 590)
        love.graphics.setColor(1, 1, 1) -- Reset to white
    else
        love.graphics.print("No piece selected", 10, 590)
    end
    
    -- Show capture history
    if #captureHistory > 0 then
        love.graphics.print("Capture History:", 10, 610)
        for i = math.max(1, #captureHistory - 2), #captureHistory do
            local capture = captureHistory[i]
            local historyText = i .. ". " .. capture.playerPiece .. " × " .. capture.enemyPiece .. 
                               " at " .. capture.position .. " = " .. capture.score
            love.graphics.print(historyText, 10, 625 + (i - math.max(1, #captureHistory - 2)) * 15)
        end
    end
    
    -- Show deck contents for testing
    love.graphics.print("Deck contents:", 300, 650)
    local deckText = ""
    for i, pieceType in ipairs(deck) do
        deckText = deckText .. PIECE_STATS[pieceType].symbol
        if i < #deck then deckText = deckText .. ", " end
    end
    love.graphics.print(deckText, 300, 670)
    
    -- Debug info
    love.graphics.print("Step 6: Moves & Discards System", 10, 50)
    love.graphics.print("Click piece to select, click enemy to capture", 10, 70)
    love.graphics.print("Press D to toggle discard mode, N for new round", 10, 90)
    love.graphics.print("Press SPACE to redraw, R to reshuffle, E for new enemies, C to clear score", 10, 110)
end

-- Add the utility function back
-- Utility function to check if coordinates are within board
function isValidBoardPosition(x, y)
    return x >= 1 and x <= BOARD_SIZE and y >= 1 and y <= BOARD_SIZE
end

function countPiecesOnBoard()
    local playerCount = 0
    local enemyCount = 0
    
    for row = 1, BOARD_SIZE do
        for col = 1, BOARD_SIZE do
            local piece = board[row][col]
            if piece then
                if piece.isPlayer then
                    playerCount = playerCount + 1
                elseif piece.isEnemy then
                    enemyCount = enemyCount + 1
                end
            end
        end
    end
    
    return playerCount, enemyCount
end

function love.mousepressed(x, y, button)
    if button == 1 then -- Left mouse button
        -- Convert mouse coordinates to board position
        local boardX = math.floor((x - BOARD_OFFSET_X) / TILE_SIZE) + 1
        local boardY = math.floor((y - BOARD_OFFSET_Y) / TILE_SIZE) + 1
        
        -- Check if click is within board bounds
        if boardX >= 1 and boardX <= BOARD_SIZE and boardY >= 1 and boardY <= BOARD_SIZE then
            local file = string.char(96 + boardX)
            local rank = tostring(9 - boardY)
            
            local piece = board[boardY][boardX]
            
            -- If clicking on a player piece, select it
            if piece and piece.isPlayer then
                selectedPiece = {row = boardY, col = boardX}
                calculateValidMoves(boardY, boardX, piece.type)
                print("Selected " .. piece.type .. " at " .. file .. rank)
            
            -- If clicking on empty square or enemy piece with a piece selected, try to move
            elseif selectedPiece then
                if isValidMove(boardY, boardX) then
                    local capturedPiece = board[boardY][boardX]
                    movePiece(selectedPiece.row, selectedPiece.col, boardY, boardX)
                    selectedPiece = nil
                    validMoves = {}
                    
                    -- If we captured an enemy piece, show capture info
                    if capturedPiece and capturedPiece.isEnemy then
                        print("Captured enemy " .. capturedPiece.type .. " worth " .. capturedPiece.chips .. " chips!")
                    end
                else
                    print("Invalid move to " .. file .. rank)
                end
            
            -- If clicking empty square with no selection, deselect
            else
                selectedPiece = nil
                validMoves = {}
                print("Clicked empty square: " .. file .. rank)
            end
        end
    end
end

function calculateValidMoves(row, col, pieceType)
    validMoves = {}
    
    if pieceType == "pawn" then
        -- Pawn moves forward one square (up the board) if empty
        if row > 1 and board[row - 1][col] == nil then
            addValidMoveIfPossible(row - 1, col)
        end
        
        -- Pawn captures diagonally (only if enemy piece is present)
        if row > 1 then
            -- Diagonal left capture
            if col > 1 then
                local leftDiagonal = board[row - 1][col - 1]
                if leftDiagonal and leftDiagonal.isEnemy then
                    addValidMoveIfPossible(row - 1, col - 1)
                end
            end
            -- Diagonal right capture
            if col < BOARD_SIZE then
                local rightDiagonal = board[row - 1][col + 1]
                if rightDiagonal and rightDiagonal.isEnemy then
                    addValidMoveIfPossible(row - 1, col + 1)
                end
            end
        end
    
    elseif pieceType == "rook" then
        -- Rook moves horizontally and vertically
        -- Horizontal moves
        for c = 1, BOARD_SIZE do
            if c ~= col then
                addValidMoveIfPossible(row, c)
            end
        end
        -- Vertical moves
        for r = 1, BOARD_SIZE do
            if r ~= row then
                addValidMoveIfPossible(r, col)
            end
        end
    
    elseif pieceType == "knight" then
        -- Knight moves in L-shape
        local knightMoves = {
            {-2, -1}, {-2, 1}, {-1, -2}, {-1, 2},
            {1, -2}, {1, 2}, {2, -1}, {2, 1}
        }
        for _, move in ipairs(knightMoves) do
            local newRow = row + move[1]
            local newCol = col + move[2]
            if isValidBoardPosition(newRow, newCol) then
                addValidMoveIfPossible(newRow, newCol)
            end
        end
    
    elseif pieceType == "bishop" then
        -- Bishop moves diagonally
        local directions = {{-1, -1}, {-1, 1}, {1, -1}, {1, 1}}
        for _, dir in ipairs(directions) do
            for i = 1, BOARD_SIZE do
                local newRow = row + dir[1] * i
                local newCol = col + dir[2] * i
                if isValidBoardPosition(newRow, newCol) then
                    addValidMoveIfPossible(newRow, newCol)
                else
                    break
                end
            end
        end
    
    elseif pieceType == "queen" then
        -- Queen combines rook and bishop moves
        -- Horizontal and vertical
        for c = 1, BOARD_SIZE do
            if c ~= col then
                addValidMoveIfPossible(row, c)
            end
        end
        for r = 1, BOARD_SIZE do
            if r ~= row then
                addValidMoveIfPossible(r, col)
            end
        end
        -- Diagonal
        local directions = {{-1, -1}, {-1, 1}, {1, -1}, {1, 1}}
        for _, dir in ipairs(directions) do
            for i = 1, BOARD_SIZE do
                local newRow = row + dir[1] * i
                local newCol = col + dir[2] * i
                if isValidBoardPosition(newRow, newCol) then
                    addValidMoveIfPossible(newRow, newCol)
                else
                    break
                end
            end
        end
    
    elseif pieceType == "king" then
        -- King moves one square in any direction
        local kingMoves = {
            {-1, -1}, {-1, 0}, {-1, 1},
            {0, -1},           {0, 1},
            {1, -1},  {1, 0},  {1, 1}
        }
        for _, move in ipairs(kingMoves) do
            local newRow = row + move[1]
            local newCol = col + move[2]
            if isValidBoardPosition(newRow, newCol) then
                addValidMoveIfPossible(newRow, newCol)
            end
        end
    end
    
    print("Calculated " .. #validMoves .. " valid moves for " .. pieceType)
end

function addValidMoveIfPossible(row, col)
    local piece = board[row][col]
    -- Can move to empty square or capture enemy piece (but not friendly pieces)
    if piece == nil or piece.isEnemy then
        table.insert(validMoves, {row = row, col = col})
    end
end

function isValidMove(row, col)
    for _, move in ipairs(validMoves) do
        if move.row == row and move.col == col then
            return true
        end
    end
    return false
end

function movePiece(fromRow, fromCol, toRow, toCol)
    local piece = board[fromRow][fromCol]
    local targetPiece = board[toRow][toCol]
    local file = string.char(96 + toCol)
    local rank = tostring(9 - toRow)
    
    -- Calculate score if capturing an enemy piece
    if targetPiece and targetPiece.isEnemy then
        local captureScore = piece.chips * piece.mult
        score = score + captureScore
        
        -- Store capture info for display
        lastCapture = {
            playerPiece = piece.type,
            enemyPiece = targetPiece.type,
            chips = piece.chips,
            mult = piece.mult,
            score = captureScore,
            position = file .. rank
        }
        
        -- Add to capture history
        table.insert(captureHistory, {
            playerPiece = piece.type,
            enemyPiece = targetPiece.type,
            score = captureScore,
            position = file .. rank
        })
        
        print("Captured " .. targetPiece.type .. " with " .. piece.type .. ": " .. piece.chips .. " × " .. piece.mult .. " = " .. captureScore .. " points! (Total: " .. score .. ")")
    else
        -- Clear last capture info if just moving
        lastCapture = nil
    end
    
    -- Move the piece
    board[toRow][toCol] = piece
    board[fromRow][fromCol] = nil
    
    print("Moved " .. piece.type .. " to " .. file .. rank)
end

function love.keypressed(key)
    if key == "space" then
        -- Clear board of player pieces and redraw them
        for row = 1, BOARD_SIZE do
            for col = 1, BOARD_SIZE do
                if board[row][col] and board[row][col].isPlayer then
                    -- Return piece to deck
                    table.insert(deck, board[row][col].type)
                    board[row][col] = nil
                end
            end
        end
        shuffleDeck()
        drawPiecesToBoard()
        selectedPiece = nil
        validMoves = {}
        print("Redrawn player pieces from deck")
        
    elseif key == "r" then
        -- Reshuffle deck
        -- First collect all player pieces from board
        for row = 1, BOARD_SIZE do
            for col = 1, BOARD_SIZE do
                if board[row][col] and board[row][col].isPlayer then
                    table.insert(deck, board[row][col].type)
                    board[row][col] = nil
                end
            end
        end
        shuffleDeck()
        drawPiecesToBoard()
        selectedPiece = nil
        validMoves = {}
        print("Deck reshuffled and pieces redrawn")
        
    elseif key == "e" then
        -- Respawn enemy pieces
        -- First clear existing enemy pieces
        for row = 1, BOARD_SIZE do
            for col = 1, BOARD_SIZE do
                if board[row][col] and board[row][col].isEnemy then
                    board[row][col] = nil
                end
            end
        end
        placeEnemyPieces()
        selectedPiece = nil
        validMoves = {}
        print("Enemy pieces respawned")
        
    elseif key == "c" then
        -- Clear score (for testing)
        score = 0
        print("Score reset")
        
    elseif key == "d" then
        -- Toggle discard mode
        discardMode = not discardMode
        selectedPiece = nil
        validMoves = {}
        if discardMode then
            print("Discard mode ON - Click player pieces to discard them")
        else
            print("Discard mode OFF - Back to normal move mode")
        end
        
    elseif key == "n" then
        -- Start new round (reset moves and discards)
        movesLeft = MAX_MOVES
        discardsLeft = MAX_DISCARDS
        discardMode = false
        selectedPiece = nil
        validMoves = {}
        print("New round started! Moves: " .. movesLeft .. ", Discards: " .. discardsLeft)
    end
end


function discardPiece(row, col)
    local piece = board[row][col]
    local file = string.char(96 + col)
    local rank = tostring(9 - row)
    
    -- Return piece to deck
    table.insert(deck, piece.type)
    board[row][col] = nil
    
    -- Shuffle deck and draw a new piece
    shuffleDeck()
    
    -- Find a new random position for the replacement piece
    local attempts = 0
    local newRow, newCol
    
    repeat
        newRow = math.random(1, BOARD_SIZE)
        newCol = math.random(1, BOARD_SIZE)
        attempts = attempts + 1
    until board[newRow][newCol] == nil or attempts > 100
    
    if attempts <= 100 and #deck > 0 then
        -- Place new piece from deck
        local newPieceType = table.remove(deck, 1)
        board[newRow][newCol] = {
            type = newPieceType,
            chips = PIECE_STATS[newPieceType].chips,
            mult = PIECE_STATS[newPieceType].mult,
            isPlayer = true
        }
        
        local newFile = string.char(96 + newCol)
        local newRank = tostring(9 - newRow)
        print("Discarded " .. piece.type .. " at " .. file .. rank .. ", drew " .. newPieceType .. " at " .. newFile .. newRank)
    else
        print("Discarded " .. piece.type .. " at " .. file .. rank .. " but couldn't place replacement (deck empty or board full)")
    end
    
    discardsLeft = discardsLeft - 1
    
    -- Check if round is over
    if movesLeft == 0 and discardsLeft == 0 then
        print("Round over! No moves or discards left.")
    end
end

function getTotalEnemyChips()
    local total = 0
    for row = 1, BOARD_SIZE do
        for col = 1, BOARD_SIZE do
            local piece = board[row][col]
            if piece and piece.isEnemy then
                total = total + piece.chips
            end
        end
    end
    return total
end