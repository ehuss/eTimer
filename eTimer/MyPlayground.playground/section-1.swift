// Playground - noun: a place where people can play

import UIKit

class A {
    var foo = 42
}

class B: A {

}

var b = B()

var a: A? = b

//var c = a as B

var d = a as? B
if !d {
    42
}
d!.foo

var e = a as B?
e!.foo

var f = a as B!
f.foo

let q: Dictionary<String, AnyObject> = [:]
//let m = q["foo"] as? String
121212
