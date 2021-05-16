# 🪄 🤖 magicmake is now 525% faster

Thanks to migrating from the ungodly slow [strace], [magicmake] is now much faster thanks to using [bpfcc-tools] instead. 🥳

Before (using [strace]):

![magicmake demo](https://github.com/truthly/demos/blob/master/magicmake-strace.gif "strace magicmake demo")

After (using [bpfcc-tools]):

![magicmake demo](https://github.com/truthly/demos/blob/master/magicmake.gif "bpfcc-tools magicmake demo")

[magicmake]: https://github.com/truthly/magicmake
[strace]: https://strace.io/
[bpfcc-tools]: https://github.com/iovisor/bcc
