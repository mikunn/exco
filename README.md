# Exco

Functions for concurrent processing.

## Installation

The library is not yet officially released and thus not available at [Hex](https://hex.pm). Do a `git clone` if you want to try it out.

## Overview

`Exco` is all about providing helper functions to run things concurrently. There are concurrent versions of functions in `Enum` and `Stream` module in `Exco` and `Exco.Stream` modules, respectively. To launch multiple tasks, you may want to check out `Exco.TaskList`. 

This library is intended to be used to add concurrency to simple operations. If you need to squeeze out every millisecond of performance or have specific fault tolerance requirements, this library might not be for you.

The following topics will hopefully give you a better idea of what the library can do.

## Fault tolerance

What happens when a task (a process that executes the function for an item) or the caller terminate? When using the functions without the `_nolink` postfix, all tasks and the caller will terminate as well. This is because all the processes will be linked.

If this is not desired, calling the functions ending with `_nolink` will fire each task unlinked to the caller. In short, a terminating task doesn't have any effect on other tasks or the caller. If the caller dies, the spawned processes run to completion, but the caller is then not able to spawn the rest of the processes or collect the results.

`Exco` won't currently restart terminated tasks.

## Concurrency and performance

The functions in `Exco` and `Exco.Stream` modules will usually provide worse performance compared to the versions in the standard library with CPU bound tasks. However, when the operations get a bit more CPU or especially I/O bound, running the `Exco` versions will start to make sense.

By default, the functions in `Exco` and `Exco.Stream` will run concurrently no more items than the number of schedulers online determined by `System.schedulers_online/1`. If you want to make this explicit, you can set the `max_concurrency` option to `:schedulers`. You can also set `max_concurrency` to either an integer or `:full`. When `:full`, there is no explicit limit.
