# Corona-Skillz
Skillz Plugin for Corona

1. This code is really old and it his here for educational purposes only. No support will be given.
2. At one point this code was used for 3 apps on Skillz.
3. ios only.
4. The following lua signature are implemented.
```
    .init(listerner, { key=<"skillzKey">, orientation=<"portriat" or "landscape">, allowExit=<true or false> } )
    .show() -- Show the skillz UI.
    .randomeNumber(number1, number2) -- Returns lua lumber with value between 1 and 2 from Skillz.
    .updateScore(number) -- Update score.
    .endMatch(number) -- End match with final score.
```
5. The library will fire a callback when skillz ui exits and when match will begin.
