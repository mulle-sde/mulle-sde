# <|ONESHOT_NAME|>-craftinfo

Craftinfo for mulle-sde to build [<|ONESHOT_NAME|>](//github.com/<|GITHUB_USER|>/<|ONESHOT_NAME|>)

``` bash
mulle-sde dependency add --github <|GITHUB_USER|> <|ONESHOT_NAME|>
mulle-sde dependency mark <|ONESHOT_NAME|> singlephase
# mulle-sde dependency set <|ONESHOT_NAME|> aliases <|ONESHOT_NAME|>-other
# mulle-sde dependency set <|ONESHOT_NAME|> include <|ONESHOT_NAME|>-other.h
# mulle-sde environment --global set MULLE_CRAFT_USE_SCRIPTS <|ONESHOT_NAME|>-build
```

## Tips

* If you want to define `CFLAGS` use `definition/set/append/CFLAGS` instead of `definition/set/CFLAGS` so that you can still add flags with the environment variable `CFLAGS`. Or use `mulle-sde dependency craftinfo  set --append <|ONESHOT_NAME|> CFLAGS "-DX=0`
* use `CPPFLAGS` instead of `CFLAGS` to match C++, C and Objective-C
* you can use `definition/set/append0` to append a string without an intervening space
* you can use `definition/set/remove` to remove a definition


