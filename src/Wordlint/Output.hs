module Wordlint.Output where

import Data.List
import Text.PrettyPrint.Boxes 
import Wordlint.Args
import Wordlint.Linters
import Wordlint.Words
import Wordlint.Wordpairs

produceOutput :: (Show a, Eq a, Ord a, Num a, NumOps a) => Linter -> Wordpairs a -> IO ()
produceOutput linter wordpairs
    | ishuman =
      do mapM_ putStrLn (processHumanData wordpairs')
         putStrLn ""
         summary
    | iserrorfmt = putStrLn $ processDataError wordpairs' filename
    | otherwise = processMachineData wordpairs'
    where cargs = args linter
          filename = if file cargs /= "" then file cargs else "stdin"
          ishuman = human cargs
          sortflag = sort_ cargs
          iserrorfmt = sortflag == "error"
          wordpairs' = checkSortFlag sortflag wordpairs
          summary
            = summaryData (length wordpairs) (matchlength cargs)
                (length $ inputdata linter)

processHumanData :: (Show a) => Wordpairs a -> [String]
processHumanData [] = ["No (more) matches found"]
processHumanData (x:xs) = ("\'" ++ word ++ "\'"
                         ++ " at coordinates "
                         ++ coordinates
                         ++ " with an intervening distance of "
                         ++ distance') : processHumanData xs
                         where word = getWordPairString x
                               coordinates = show (getWordpairCoords x)
                               distance' = take 7 (show (pdiff x))

processMachineData :: (Show a) => Wordpairs a -> IO ()
processMachineData x = printBox $ hsep 2 left (map (vcat left . map text) 
                                    (transpose $ ["Coord1", "Coord2", "Word", "Distance"]:processMachineData' x))

processMachineData' :: (Show a) => Wordpairs a -> [[String]]
processMachineData' [] = []
processMachineData' (x:xs) = words (coordinates1 coordinates'
                                    ++ " "
                                    ++ coordinates2 coordinates'
                                    ++ " "
                                    ++ word
                                    ++ " "
                                    ++ distance') : processMachineData' xs
                                      where word = getWordPairString x
                                            coordinates' = getWordpairCoords x
                                            coordinates1 ((r1,s1),(_,_)) = show r1 ++ "," ++ show s1
                                            coordinates2 ((_,_),(r2,s2)) = show r2 ++ "," ++ show s2
                                            distance' = take 7 $ show (pdiff x)
-- Function if "error" is passed as --sort flag argument
processDataError :: (NumOps a) => Wordpairs a -> String -> String
processDataError [] _ = ""
processDataError (x:xs) fname = (fname ++ ":" ++ linum1 ++ ":"  ++  colnum1 ++ ":" ++ word ++ "\n") ++
                              (fname ++ ":" ++ linum2 ++ ":"  ++  colnum2 ++ ":" ++ word ++ "\n") ++
                        processDataError xs fname
                         where word = getWordPairString x
                               coordinates' = getWordpairCoords x
                               coordinates1 ((r1,_),(_,_)) = show r1
                               coordinates1' ((_,_),(r1,_)) = show r1
                               linum1 = coordinates1 coordinates'
                               linum2 = coordinates1' coordinates'
                               coordinates2 ((_,s1),(_,_)) = show s1 
                               coordinates2' ((_,_),(_,s1)) = show s1 
                               colnum1 = coordinates2 coordinates'
                               colnum2 = coordinates2' coordinates'
                               
-- Function that provides summary totals when -h flag is passed
summaryData :: Int -> Int -> Int -> IO()
summaryData x y z = do
            putStrLn ""
            putStrLn $ "Found " ++ show x  ++ " pairs of words "
              ++ show y ++ " or more characters in length out of "
              ++ show z ++ " words total."
