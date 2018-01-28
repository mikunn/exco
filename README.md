# Exco

Concurrent versions of some of the functions in the `Enum` module.

## Installation

The library is not yet officially released and thus not available at [Hex](https://hex.pm). Do a `git clone` if you want to try it out.

## Overview

*Exco* is all about providing concurrent versions of functions in the `Enum` module such as `Enum.map/2` and `Enum.each/2`. New functions will be added in the future as we see fit and sensible.

There are two modules providing the same functions: `Exco` and `Exco.Nolink`. If you need the spawned processes to be linked to the caller, use the functions in `Exco`. If you want the processes to be unlinked, use `Exco.Nolink`. See more information in the *Fault tolerance* section.

The functions in *Exco* are designed to provide the same interface as the corresponding functions in the `Enum` module. Internally, it uses different functions in the `Task` and `Task.Supervisor` modules depending on the options.

This library is intended to be used to add concurrency to simple operations. If you need to squeeze out every millisecond of performance or have specific fault tolerance requirements, this library might not be for you.

The following topics will hopefully give you a better idea of what the library can do.

## Fault tolerance

What happens when a task (a process that executes the function for an item) or the caller terminates. When using the functions in the `Exco` module, all tasks and the caller will terminate as well. This is because all the processes will be linked.

If this is not desired, the corresponding functions in `Exco.Nolink` will fire each task unlinked to the caller. In short, a terminating task doesn't have any effect on other tasks or the caller. A terminating caller causes a more interesting behaviour. Further description of that can be found from the docs of the `Exco.Nolink` module.

*Exco* won't currently restart terminated tasks.

## Concurrency and performance

If the operation is simple enough, the standard `Enum` functions will generally give you better performance. However, when the operations get a bit more CPU or especially I/O bound, running the *Exco* versions will start to make sense.

By default, `Exco` will spawn a new process for each item in the collection using `Task.async/1` and `Task.await/2`. You can change this using the `:max_concurrency` option taking an integer as the max number of processes to run concurrently. It will then switch to use `Task.Supervisor.async_stream/3`.

`Exco.Nolink` works a bit differently. By default, it will run in parallel as many tasks as there are schedulers online. This is because `Exco.Nolink` uses `Task.Supervisor.async_stream_nolink/3` internally, and using too many parallel tasks by default can harm the performance.

Finally, *Exco* doesn't use streams for collecting and processing the data from tasks, so be wary of that.

