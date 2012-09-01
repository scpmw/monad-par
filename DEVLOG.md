

This is an UGLY file full of development notes and debugging notes.
It's not meant for external consumption.

[2011.03.15] 
------------------------------------------------------------

I'm seeing some awful weird behavior with OpenLists's async_test.
(First, runParAsync doesn't return immediately as it should.  That's a
bug.)  But the real problem is that I'm seeing different behavior when
I make OpenList into a main module and compile it vs. when I compile
it as a library.

In particular, when compiled as a library, I get "thread blocked
indefinitely" errors.  

The other behavior is that it freezes while taking the head under
GHCI.  I think this is just the indefinite MVar block because it
doesn't burn CPU.

And the last behavior is that it will complete successfully (but the
chaintest still fails to return before the full chain is constructed).
(But now I'm having trouble reproducing this behavior.)

The underlying lazy_chaintest works fine when called from ghci!!

Hmm... this is quite finicky... printing the whole list instead of
taking the first three elements seems to avoid a freeze!?  

Ok... the problems seem to relate to whether its actually loaded
compiled.  After all, if compiled versions are around, ghci will use
them.


[2011.10.18] {Trying on SIF cluster}
------------------------------------------------------------

These are older Intel "Core" architecture Xeon's.  And they are pretty
slow.  For example building our example programs with "make -j" on
basalt takes 9.7 seconds and doing it on one SIF machine takes 45
seconds.


[2011.10.27] {Running full benchmark suite on smoketree}
------------------------------------------------------------

It did 624 configurations in 471 minutes:

    real    471m52.122s
    user    4450m51.630s
    sys     700m4.714s



[2011.12.07] {Debugging DistDirect.hs scheduler}
------------------------------------------------------------

RRN:

Currently seeing lockups (with no error) as well as some error
messages.  Here's one:

    parfib_dist: too few bytes. Failed reading at byte position 8

On my Mac I'm getting this erorr when I start up the worker:

    2011-12-08 06:18:29.156392 EST 2 pid://RyanMacbookAir:56105/8/ SYS
    Process got unhandled exception ConfigException "Can't talk to local
    node registry: QteNetworkError \"getAddrInfo: does not exist (nodename
    nor servname provided, or not known)\""

Regarding the non-deterministic freeze-up:

If I turn worker idling off then both the master and the slave
processes will converge on a state where they are using a minimal
amount of CPU (~3% each).

It looks like a lost continuation problem perhaps?  

I was able to reproduce it on parfib_dist invocations as small as 5
previously (no idling), now with idling turned on I'm having a bit of
trouble doing that...  But I can still get it to freeze at larger
sizes such as 15.



[2012.01.02] {Confirmed real-deque cabal installation under 7.4 on RHEL}
------------------------------------------------------------------------

  carray seems to have been updated.

[2012.01.02] {Reviving tests/}
------------------------------

I disabled the runParAsync test for now.  But ever after that I'm
seeing the following:

  * All tests pass when under -N1
  * at -N>=2: 'case_test_diamond' can fail with indefinitely blocked threads
  * at -N>=2: can fail by simply diverging

That was under under GHC 7.2.1.  But I then observed the same thing
under GHC 7.4.

It's difficult to tell for certain where it is hanging.  For example,
it appeared to hang just now after completing "oneIVar" which would be
in the test "forkNFill".  But on the other hand it could be that the
output is not being flushed by test-framework (though I sure hope it
is) such that my text console is stale.

Also, if the output IS up to date that means it is diverging in
SEVERAL of the tests: forkNFill, test diamond, async test1...


[2012.01.27] {Bug somewhere, divergance in ContFree / quicksort}
----------------------------------------------------------------

If this is a ContFree bug we don't care, but it's worth looking into
incase it's a bug in something else (like GHC):

    --------------------------------------------------------------------------------
      Running Config 32 of 47: quicksort/parquicksort_monad (args "") scheduler ContFree  threads 1
    --------------------------------------------------------------------------------

    (In directory /var/lib/jenkins/jobs/monad-par_github_master/workspace/JENKINS_GHC/ghc-7.4.0.20111219/examples)
    Next run who, reporting users other than the current user.  This may help with detectivework.
    Who_Output: rrnewton rrnewton rrnewton rrnewton
    Executing ./ntimes_minmedmax 1 ./quicksort/parquicksort_monad_ContFree_threaded.exe  +RTS -N1 -RTS
     # ERROR, benchmark.hs: test command "./ntimes_minmedmax 1 ./quicksort/parquicksort_monad_ContFree_threaded.exe  +RTS -N1 -RTS" failed with code ExitFailure 15
     #      Return code 143 Params:  -rtsopts, RTS  
    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
     >>> MIN/MEDIAN/MAX TIMES TIMEOUT TIMEOUT TIMEOUT




[2012.03.06] {}
------------------------------------------------------------

Seeing this on tank.  Funny thing is that its spewing out of my stdout
on a completely unrelated terminal.  Maybe it goes to all tty's?

    -bash: fork: retry: Resource temporarily unavailable
    -bash: fork: retry: Resource temporarily unavailable
    -bash: fork: Resource temporarily unavailable
    -bash: fork: retry: Resource temporarily unavailable

Wow, here I was SERIOUSLY bitten by the fact that forkIO threads do
not propagate exceptions.  createProcess was throwing a process
repeatedly but it just kept going.

Also, I need to try to kill the ssh processes!

Is readProcess is problematic?  It SHOULD be waiting until the process
exits (hence the exit code).

AH!  Maybe the problem is my idle polling... THAT still uses HSH's "run".



[2012.05.02] {Overhead from Accelerate/CUDA invocation}
------------------------------------------------------------

What I'm currently seeing is .75 - 1.5 seconds extra runtime as a
result of calling CUDA.run at all.  The time doesn't appear to
actually be IN the CUDA.run though.


[2012.05.14] {Jenkins freezing in SAME place on Windows and Linux}
------------------------------------------------------------------

A random subset of both my recent windows and linux builds froze while
compiling Control.Monad.Par:

    [5 of 5] Compiling Control.Monad.Par ( Control/Monad/Par.hs, dist/build/Control/Monad/Par.o )

Thate's just weird


[2012.08.27] {Errors with 'make validate' in examples}
------------------------------------------------------

I'm running into this:

    ERROR: echo thread: Got exception inside forked thread: bench_basalt.log: openFile: resource busy (file is locked)

It may be some spurious NFS problem.


[2012.08.31] {Debugging the notorious Issue21}
------------------------------------------------------------

I'm doing this in the context of Direct right now.  Hmm, I thought 
before that disabling Idling disabled the bug.  Seems not so presently.

If I disable idling, the system live locks and memory leaks when run
on issue21.hs with +RTS -N3.  Great.

But I could swear that previously it at least behaved properly when
NESTED_SCHEDS was disabled.  Yet now it exhibits the same live lock
without nesting...  One variable is that I recently turned ON PARPUTS.
But turning it off still live locks and still leaks memory while
IDLING is on...

Is the basic worker loop LEAKING memory?  Maybe we should do some heap profiling.

Turning idling back on makes it work much better.  (BUT this is in a
config with PARPUTS off, FORKPARENT off, and NESTED off.)  Running
issue21 100 times... worked fine.

Turning FORKPARENT back on... the program is largely getting
serialized, I'm not seeing much more than 100% CPU.  But... then again
this is a serial test, isn't it?  The (^) operator presumably does a
serial sequence of multiplications, so the parallelism inside the
multiply operator doesn't really help (no balance).


    FORKPARENT   NESTED   IDLING  PARPUTS
    1            0        1       1         Works

    1            1        1       1         BlockIndefinitely
    1            1        1       0         BlockIndefinitely
    0            1        1       0         BlockIndefinitely

    1            1        0       0         LiveLock and Leak
    0            0        0       0         LiveLock and Leak   # NOW INVALID...
    1            1        0       1         LiveLock and Leak


The heap residency profile in a livelock run looks like this:

    MAIN    912
    (164)GHC.IO.Encoding.CAF        768
    (206)GHC.Integer.Logarithm...   288
    (186)GHC.Event.Thread.CAF       296
    (172)GHC.IO.Encoding.Iconv.CAF  528
    (243)uniform2.x/uniform2/u...   176
    (241)nextIndex/uniform2.j/...   224
    (216)initialize/create/*/f...   100440
    (214)*/fib.(...)/fib/main/...   21424
    (238)nextIndex/uniform2/un...   144
    (231)uniformRange/uniformR...   3456
    (236)uniform/uniformRange....   1640
    (237)uniform2/uniform/unif...   7464
    (229)*/fib.(...)/fib/main       60365872
    END_SAMPLE 8.15

So the explosion is in fib/main itself.

Ok, let's see, I think with idling off there was an obvious leak in
the counter in the "go" loop.  what if we tweak idling so that it does
evaluate tha counter?  For now still leaving profiling and "-xc -h"
ON.

    FORKPARENT   NESTED   IDLING  PARPUTS  PROFILING
    1            1        0       1        1           LiveLock, NO LEAK

And then if it evaluate's the counter AND yields:

    1            1        0       1        1           LiveLock, NO LEAK

Without profiling:

    1            1        0       1        0           LiveLock, NO LEAK

Ok, so that fixed the leak at least.  Note that now -N3 uses 200% CPU.  What does that say?
Now that we fixed that obvious bug in IDLING, let's turn NESTED back off:

    1            0        0       1        0           Worked SLOWLY.

And NOW it used 300% CPU as well.  It took about 80 seconds to run
issue21.hs though!  (Which does 10M iterations by default and takes
about a second at its best.  In fact the above config takes about a
second with +RTS -N1!!)  80X parallel slowdown.  

But why does it do so well with -N1?  Direct very well COULD as an
optimization NOT fork worker threads in -N1.  But it DOESN'T do that
right now it looks like.

Ok, one more change.  This shouln't matter.  I'm just refactoring how
the NESTED_SCHEDS ifdef is handled, pushing the ifdef to the top of
the file and changing only the helper defs (amINested, registerWorker,
unregisterWorker).  Expecting the same behavior and getting it for
this config.  Now I'll check in.

    1            0        0       1        0           Worked SLOWLY.

----------------

Ok, checked in.

    1            1        0       1        0           Works, 200% cpu,  -N2
    1            1        0       1        0           LiveLock, no leak -N3 

Wait a sec... this idling off mode is still fishy.  It CANNOT stay in
the steal loop.  It needs to return to rescheduleR so as to check
killflag.  If I fix that I get a 200% cpu livelock on -N3.  Is there
some OTHER way that threads are failing to see the killflag?

Hmm... rerunning with apparently unrelated changes makes that a 300%
cpu livelock.  Ah it's nondeterministic.  The 200% behavior happens
comparatively less often.  

Turning on busyTakeMVar seems to ELIMINATE the 200% behavior.  But
this is odd.  Yes, the main thread should be waiting, fine.  But there
should still be THREE worker threads, not TWO.

The 200% must be from hitting some kind of blackhole to disable the worker?


< Testing one-level-deep nesting >
----------------------------------

This seems to work without deadlock / livelock.  That would be
consistent with the hypothesis that it is loop in nested runPars /
steals.





TEMP / SCRAP:
--------------------------------------------------------------------------------






