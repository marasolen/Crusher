module AI (choosePlay, aiTests) where

import Test.HUnit
import CrusherBoard
import Piece
import Util
import Control.Parallel

depth = 3
parallel = True
posMult = 1.5
negMult = -1.0

{-
calculateValue is a function that takes a Board and a Piece and evaluates the
board from that Piece's side, returning a Double between negMult and posMult
that represents how good the situation is.
-}
calculateValue :: Board -> Piece -> Double
calculateValue board me
    | x == 0    = 0
    | sign > 0  = posMult*(sqrt (x / (1.0 + x)))
    | otherwise = negMult*(sqrt (x / (1.0 + x)))
    where x = fromIntegral (abs ((countAll board me) - (countAll board (getOtherPlayer me))))
          sign = (x / (sqrt (x * x)))

{-
calculateOddsSingle takes a list of Boards, a Board, two Pieces, and an Int and
calculates the value of this state by taking the average of each value from each
of the possible moves from this state.
-}
calculateOddsSingle :: [Board] -> Board -> Piece -> Piece -> Int -> Double
calculateOddsSingle visited board me curr depth
    | countAll board curr == 0 = if curr == me then negMult else posMult
    | plays == [] = if curr == me then negMult else posMult
    | depth == 0 = calculateValue board me
    | otherwise = (calculateOddsMult (board:visited) plays me (getOtherPlayer curr) depth) / (fromIntegral (length plays))
    where plays = generatePlayset visited board curr

{-
calculateOddsMult calculates the average value for each Board in its second list
of Boards.
-}
calculateOddsMult :: [Board] -> [Board] -> Piece -> Piece -> Int -> Double
calculateOddsMult _ [] _ _ _ = 0.0
calculateOddsMult visited (h:t) me curr depth
    | parallel  = par p1 (pseq p2 (p1 + p2))
    | otherwise = p1 + p2
    where p1 = calculateOddsSingle visited h me curr (depth - 1)
          p2 = calculateOddsMult visited t me curr depth

{-
generatePlayset takes a list of Boards, a Board, and a Piece and generates a
list of all the possible moves that the player with type Piece can make.
-}
generatePlayset :: [Board] -> Board -> Piece -> [Board]
generatePlayset visited board p = generatePlaysetHelp visited board pieces p
    where pieces = snd (placePieceMarkers visited board p)

{-
generatePlaysetHelp takes a list of Boards, a Board, a list of Points, and a
Piece and generates all the possible moves for a Piece at each Point.
-}
generatePlaysetHelp :: [Board] -> Board -> [Point] -> Piece -> [Board]
generatePlaysetHelp _ _ [] _ = []
generatePlaysetHelp visited board (h:t) p = single ++ rest
    where moves = snd (getMoves visited board h)
          stomps = snd (getStomps visited board p h)
          single = generateMoves board h (moves ++ stomps)
          rest = generatePlaysetHelp visited board t p

{-
generateMoves takes a Board, a Point, and List of Points and it generates a list
of all the boards that can be made from moving the first Point to the Points ins
the list.
-}
generateMoves :: Board -> Point -> [Point] -> [Board]
generateMoves _ _ [] = []
generateMoves board old (new:t) = (doMove board old new):(generateMoves board old t)

{-
choosePlay is the main function in AI, it takes a list of Boards, a Board, a
Piece, and returns a new Board which is the move that it calculated to have the
best odds for the given Piece to win.
-}
choosePlay :: [Board] -> Board -> Piece -> Board
choosePlay visited board p
    | (length plays) == 0 = board
    | otherwise = find plays (maximum probs) probs
    where plays = generatePlayset visited board p
          probs = getProbs visited plays p

{-
getProbs takes two lists of Boards and a Piece and gets a list of all the odds
associated with each possible move it can make.
-}
getProbs :: [Board] -> [Board] -> Piece -> [Double]
getProbs _ [] _ = []
getProbs visited (h:t) p = single:rest
    where single = calculateOddsSingle visited h p p depth
          rest = getProbs visited t p

{-
find takes a list of Boards, a Double, and a list of Doubles and returns the
Board associated with the given Double.
-}
find :: [Board] -> Double -> [Double] -> Board
find (h1:t1) m (h2:t2)
    | h2 == m    = h1
    | otherwise  = find t1 m t2

-- AI Tests
aiTests = TestList []
