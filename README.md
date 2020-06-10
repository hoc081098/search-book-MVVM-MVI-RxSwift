# Search book MVI RxSwift

:cyclone: Learning :zap: Search book MVVM / MVI + RxSwift :cherry_blossom: Just combine, filter, transform Stream...

### Port [search-book-flutter-BLoC-pattern-RxDart](https://github.com/hoc081098/search-book-flutter-BLoC-pattern-RxDart.git) to Swift + RxSwift + MVVM version
  
| Demo 1  | Demo 2 |
| ------------- | ------------- |
| <img src="https://github.com/hoc081098/hoc081098.github.io/blob/master/demo1.gif?raw=true" height="480">  | <img src="https://github.com/hoc081098/hoc081098.github.io/blob/master/demo2.gif?raw=true" height="480">  |

### Contributors

[Petrus Nguyễn Thái Học](https://github.com/hoc081098)

### Summary

This app uses the Model-View-Intent architecture and uses RxSwift to implement the reactive characteristic of the architecture

The MVI architecture embraces reactive and functional programming. The two main components of this architecture, the _View_ and the _ViewModel_ can be seen as functions, taking an input and emiting outputs to each other. The _View_ takes input from the _ViewModel_ and emit back _intents_. The _ViewModel_ takes input from the _View_ and emit back _view states_. This means the _View_ has only one entry point to forward data to the _ViewModel_ and vice-versa, the _ViewModel_ only has one way to pass information to the _View_.  
This is reflected in their API. For instance, The _View_ has only two exposed methods:
