-- fenparser.hs
-- Run with:
-- $ stack runghc fenparser.hs "input goes here"

module FENParser (main) where

import Control.Monad
import Data.Char
import Data.Void
import System.Environment

import Text.Megaparsec
import Text.Megaparsec.Char
import qualified Text.Megaparsec.Char.Lexer as L

type Parser = Parsec Void String 

data PieceType
  = Rook
  | Knight
  | Bishop
  | Queen
  | King
  | Pawn
  deriving (Eq, Show)

data TeamColor
  = TeamColorWhite
  | TeamColorBlack
  deriving (Eq, Show)

type Piece = (PieceType, TeamColor)

-- Can be a piece or a 'skip' digit
data PiecePlacement
  = PlacementPiece Piece
  | PlacementInt Int
  deriving (Eq, Show)

data CastlingAvailability
  = WhiteKingside
  | WhiteQueenside
  | BlackKingside
  | BlackQueenside
  deriving (Eq, Show)

data Rank
  = RankOne
  | RankTwo
  | RankThree
  | RankFour
  | RankFive
  | RankSix
  | RankSeven
  | RankEight
  deriving (Eq, Show)

data File
  = FileA
  | FileB
  | FileC
  | FileD
  | FileE
  | FileF
  | FileG
  | FileH
  deriving (Eq, Show)

-- Piece placements
-- rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1
-- ^-----------------------------------------^

piece :: Parser Piece
piece = choice [
  (Pawn,    TeamColorWhite) <$ char 'P',
  (Knight,  TeamColorWhite) <$ char 'N',
  (Bishop,  TeamColorWhite) <$ char 'B',
  (Rook,    TeamColorWhite) <$ char 'R',
  (Queen,   TeamColorWhite) <$ char 'Q',
  (King,    TeamColorWhite) <$ char 'K',

  (Pawn,    TeamColorBlack) <$ char 'p',
  (Knight,  TeamColorBlack) <$ char 'n',
  (Bishop,  TeamColorBlack) <$ char 'b',
  (Rook,    TeamColorBlack) <$ char 'r',
  (Queen,   TeamColorBlack) <$ char 'q',
  (King,    TeamColorBlack) <$ char 'k' ]

piecePlacement :: Parser PiecePlacement
piecePlacement = 
  (PlacementPiece <$> piece) <|>
  (PlacementInt   <$> digitToInt <$> oneOf ['1'..'8'])

piecePlacements :: Parser [[PiecePlacement]]
piecePlacements = some piecePlacement `sepBy1` char('/')

-- Active color
-- rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1
--                                             ^

teamColor :: Parser TeamColor
teamColor = choice [
  TeamColorWhite <$ char 'w',
  TeamColorBlack <$ char 'b']

-- Castling availability
-- rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1
--                                               ^--^
castlingAvailability :: Parser [CastlingAvailability]
castlingAvailability = 
  (pure [] <$> (char '-')) <|>
  some (
    WhiteKingside  <$ char 'K' <|>
    WhiteQueenside <$ char 'Q' <|>
    BlackKingside  <$ char 'k' <|>
    BlackQueenside <$ char 'q')

-- Enpassant Target
-- rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1
--                                               ^--^

rank :: Parser Rank
rank = choice [
  RankOne    <$ char '1',
  RankTwo    <$ char '2',
  RankThree  <$ char '3',
  RankFour   <$ char '4',
  RankFive   <$ char '5',
  RankSix    <$ char '6',
  RankSeven  <$ char '7',
  RankEight  <$ char '8']

file :: Parser File
file = choice [
  FileA <$ char 'a',
  FileB <$ char 'b',
  FileC <$ char 'c',
  FileD <$ char 'd',
  FileE <$ char 'e',
  FileF <$ char 'f',
  FileG <$ char 'g',
  FileH <$ char 'h']

position :: Parser (File, Rank)
-- position = (,) <$> file <*> rank
position = liftM2 (,) file rank

enpassantTarget :: Parser (Maybe (File, Rank))
enpassantTarget = do
  (Nothing <$ (char '-')) <|> (Just <$> position)

-- Move Clocks
-- rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1
--                                                      ^-^
halfmoveClock = L.decimal
fullmoveClock = L.decimal

fen :: Parser ([[PiecePlacement]], TeamColor, [CastlingAvailability], Maybe (File, Rank), Int, Int)
fen = (,,,,,) <$> 
  (piecePlacements <* space1) <*> 
  (teamColor <* space1) <*>
  (castlingAvailability <* space1) <*>
  (enpassantTarget <* space1) <*>
  (halfmoveClock <* space1) <*> fullmoveClock


-- rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1
main = do
  -- input <- fmap head getArgs
  -- putStrLn (show input)
  case (parse (fen) "" "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq e3 0 1") of
    Left bundle -> putStrLn (errorBundlePretty bundle)
    Right xs -> putStrLn $ show xs
  -- parseTest (piecePlacement) "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR"
