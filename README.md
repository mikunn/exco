# Exco

Functions for concurrent processing.

## Installation

The library is not yet officially released and thus not available at [Hex](https://hex.pm). Do a `git clone` if you want to try it out.

## Overview

`Exco` is all about providing helper functions to run things concurrently. There are concurrent versions of functions in `Enum` module such as `Exco.map/2` and `Exco.each/2`. You can set the maximum number of concurrent processes and set whether the processes are linked to the caller or not.

This library is intended to be used to add concurrency to simple operations. If you need to squeeze out every millisecond of performance or have specific fault tolerance requirements, this library might not be for you.

The following topics will hopefully give you a better idea of what the library can do.

## Fault tolerance

What happens when a task (a process that executes the function for an item) or the caller terminate? When using the functions with the `link` option set to `true` or left unset, all tasks and the caller will terminate as well. This is because all the processes will be linked.

If this is not desired, setting `link: false` will fire each task unlinked to the caller. In short, a terminating task doesn't have any effect on other tasks or the caller. If the caller dies, the spawned processes run to completion, but the caller is then not able to spawn the rest of the processes or collect the results.

`Exco` won't currently restart terminated tasks.

## Concurrency and performance

If the operation is simple enough, the standard `Enum` functions will generally give you better performance than the corresponding functions in `Exco`. However, when the operations get a bit more CPU or especially I/O bound, running the `Exco` versions will start to make sense.

By default, `Exco` will run concurrently no more items than the number of schedulers online determined by `System.schedulers_online/1`. If you want to make this explicit, you can set the `max_concurrency` option to `:schedulers`. You can also set `max_concurrency` to either an integer or `:full`. When `:full`, a new process is started for each item.

Finally, `Exco` doesn't use streams for collecting and processing the data from tasks, so be wary of that.

