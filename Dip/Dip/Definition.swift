//
// Dip
//
// Copyright (c) 2015 Olivier Halligon <olivier@halligon.net>
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

///Internal representation of a key used to associate definitons and factories by tag, type and factory.
public struct DefinitionKey : Hashable, Equatable, CustomStringConvertible {
  private(set) public var protocolType: Any.Type
  private(set) public var factoryType: Any.Type
  private(set) public var associatedTag: DependencyContainer.Tag?
  
  public var hashValue: Int {
    return "\(protocolType)-\(factoryType)-\(associatedTag)".hashValue
  }
  
  public var description: String {
    return "type: \(protocolType), factory: \(factoryType), tag: \(associatedTag)"
  }
}

public func ==(lhs: DefinitionKey, rhs: DefinitionKey) -> Bool {
  return
    lhs.protocolType == rhs.protocolType &&
      lhs.factoryType == rhs.factoryType &&
      lhs.associatedTag == rhs.associatedTag
}

///Describes the lifecycle of instances created by container.
public enum ComponentScope {
  /// Indicates that a new instance of the component will be created each time it's resolved.
  case Prototype
  /// Indicates that instances will be reused during resolve but will be discurded when topmost `resolve` method returns.
  case ObjectGraph
  /// Indicates that resolved component should be retained by container and always reused.
  case Singleton
}

/**
 Definition of type T describes how instances of this type should be created when this type is resolved by container.
 
 - Generic parameter `T` is the type of the instance to resolve 
 - Generic parameter `F` is the type of block-factory that creates an instance of T.
 
 For example `DefinitionOf<Service,(String)->Service>` is the type of definition that during resolution will produce instance of type `Service` using closure that accepts `String` argument.
*/
public final class DefinitionOf<T, F>: Definition {
  
  /**
   Sets the block that will be used to resolve dependencies of the component. 
   This block will be called before `resolve` returns.
   
   - parameter block: block to use to resolve dependencies
   
   - note:  
   If you have circular dependencies at least one of them should use this block
   to resolve it's dependencies. Otherwise code enter infinite loop.
   
   **Example**
   
   ```swift
   container.register { ClientImp(service: container.resolve() as Service) as Client }

   var definition = container.register { ServiceImp() as Service }
   definition.resolveDependencies { container, service in
      service.delegate = try container.resolve() as Client
   }
   ```
   
   */
  public func resolveDependencies(block: (DependencyContainer, T) throws -> ()) -> DefinitionOf<T, F> {
    guard resolveDependenciesBlock == nil else {
      fatalError("You can not change resolveDependencies block after it was set.")
    }
    resolveDependenciesBlock = block
    return self
  }
  
  let factory: F
  var scope: ComponentScope
  var resolveDependenciesBlock: ((DependencyContainer, T) throws -> ())?
  
  init(factory: F, scope: ComponentScope) {
    self.factory = factory
    self.scope = scope
  }
  
  ///Will be stored only if scope is `Singleton`
  var resolvedInstance: T? {
    get {
      guard scope == .Singleton else { return nil }
      return _resolvedInstance
    }
    set {
      guard scope == .Singleton else { return }
      _resolvedInstance = newValue
    }
  }
  
  private var _resolvedInstance: T?
}

///Dummy protocol to store definitions for different types in collection
protocol Definition: class {}

extension DefinitionOf: CustomStringConvertible {
  public var description: String {
    return "type: \(T.self), factory: \(F.self), scope: \(scope), resolved instance: \(resolvedInstance)"
  }
}
