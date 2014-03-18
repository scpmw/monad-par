{-# LANGUAGE CPP  #-}

-- This is a simplistic benchmark but is included just for comparison with Haskell CnC

-- Author: Ryan Newton 

import System.Environment
import qualified Control.Monad.Par.AList as A

#ifdef NEW_GENERIC
import qualified Data.Par as C
#else
import qualified Control.Monad.Par.Combinator as C
#endif
import Debug.Trace
#ifdef PARSCHED 
import PARSCHED
#else
import Control.Monad.Par
#endif

-- First a naive serial test for primality:
isPrime :: Int -> Bool
isPrime 2 = True
isPrime n = (prmlp 3 == n)
    where prmlp :: Int -> Int
  	  prmlp i = if (rem n i) == 0
 		    then i else prmlp (i + 2)

----------------------------------------

-- Next, a CnC program that calls the serial test in parallel.

primes :: Int -> Int -> Par (A.AList Int)
primes start end = 
-- parMapReduceRange (InclusiveRange start end)
 C.parMapReduceRangeThresh 100 (C.InclusiveRange start end)
		   (\n -> if 
		            -- TEMP: Need a strided range here:
                            (rem n 2 /= 0) && isPrime n 
		          then return$ A.singleton n
		          else return$ A.empty)
		   (\ a b -> return (A.append a b))
		   A.empty

-- This version never builds up the list, it simply counts:
-- countprimes :: Int -> Int -> Par Int
-- countprimes start end = 
		   
main :: IO ()
main = do args <- getArgs 
	  let size = case args of 
		      []  -> 1000 -- Should output 168
		      [n] -> (read n)

              ls = runPar $ primes 3 size
	      
--	  putStrLn (show ls)
	  putStrLn (show (1 + A.length ls)) -- Add one to include '2'.
          return ()
