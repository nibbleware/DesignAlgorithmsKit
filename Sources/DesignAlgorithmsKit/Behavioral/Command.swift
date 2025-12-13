//
//  Command.swift
//  DesignAlgorithmsKit
//
//  Command Pattern - Encapsulate a request as an object
//

import Foundation

/// Protocol for commands
public protocol Command {
    /// Execute the command
    func execute()
    
    /// Undo the command (optional)
    func undo()
}

/// Base command implementation
open class BaseCommand: Command {
    public init() {}
    
    open func execute() {
        // To be implemented by subclasses
    }
    
    open func undo() {
        // To be implemented by subclasses
    }
}

/// A command that wraps a simple closure
public class ClosureCommand: Command {
    private let action: () -> Void
    private let undoAction: (() -> Void)?
    
    public init(action: @escaping () -> Void, undoAction: (() -> Void)? = nil) {
        self.action = action
        self.undoAction = undoAction
    }
    
    public func execute() {
        action()
    }
    
    public func undo() {
        undoAction?()
    }
}

/// Invoker responsible for executing commands
open class CommandInvoker {
    private var history: [Command] = []
    private var undoStack: [Command] = []
    
    public init() {}
    
    /// Execute a command
    public func execute(_ command: Command) {
        command.execute()
        history.append(command)
        undoStack.removeAll() // Clear redo stack on new operation
    }
    
    /// Undo the last command
    public func undo() {
        guard let command = history.popLast() else { return }
        command.undo()
        undoStack.append(command)
    }
    
    /// Redo the last undone command
    public func redo() {
        guard let command = undoStack.popLast() else { return }
        command.execute()
        history.append(command)
    }
}
