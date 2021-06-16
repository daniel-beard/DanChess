-- fenparser.hs
-- Run with:
-- $ stack runghc fenparser.hs "input goes here"

module FENParser (main) where

import Control.Monad
import Data.Void
import Text.Megaparsec
import Text.Megaparsec.Char
import System.Environment

type Parser = Parsec Void String 

data PieceType
  = Rook
  | Knight
  | Bishop
  | Queen
  | King
  | Pawn
  deriving (Eq, Show)

data TeamColor = TeamColorWhite | TeamColorBlack
  deriving (Eq, Show)

type Piece = (PieceType, TeamColor)

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
position = do
  f <- file
  r <- rank
  return (f, r)

-- Parse team color
teamColor :: Parser TeamColor 
teamColor = choice [
  TeamColorWhite <$ char 'w',
  TeamColorBlack <$ char 'b']

piece :: Parser Piece
piece = choice [
  (Pawn,    TeamColorWhite) <$ char 'P',
  (Knight,  TeamColorWhite) <$ char 'N'
  (Bishop,  TeamColorWhite) <$ char 'B',
  (Rook,    TeamColorWhite) <$ char 'R',
  (Queen,   TeamColorWhite) <$ char 'Q',
  (King,    TeamColorWhite) <$ char 'K',

  (Pawn,    TeamColorBlack) <$ char 'p',
  (Knight,  TeamColorBlack) <$ char 'n'
  (Bishop,  TeamColorBlack) <$ char 'b',
  (Rook,    TeamColorBlack) <$ char 'r',
  (Queen,   TeamColorBlack) <$ char 'q',
  (King,    TeamColorBlack) <$ char 'k' ]

-- piecePlacements :: Parser 

-- rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1
main = do
    -- input <- fmap head getArgs
    -- putStrLn (show input)
    parseTest (position) "e4"
