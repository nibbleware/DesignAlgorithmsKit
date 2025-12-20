import XCTest
@testable import DesignAlgorithmsKit

final class CommandTests: XCTestCase {
    
    func testClosureCommand() {
        var value = 0
        let command = ClosureCommand(
            action: { value += 1 },
            undoAction: { value -= 1 }
        )
        
        command.execute()
        XCTAssertEqual(value, 1)
        
        command.undo()
        XCTAssertEqual(value, 0)
    }
    
    func testInvokerExecuteUndoRedo() {
        let invoker = CommandInvoker()
        var value = 0
        
        let incrementCommand = ClosureCommand(
            action: { value += 1 },
            undoAction: { value -= 1 }
        )
        
        // Execute
        invoker.execute(incrementCommand)
        XCTAssertEqual(value, 1)
        
        invoker.execute(incrementCommand)
        XCTAssertEqual(value, 2)
        
        // Undo
        invoker.undo()
        XCTAssertEqual(value, 1)
        
        invoker.undo()
        XCTAssertEqual(value, 0)
        
        // Redo
        invoker.redo()
        XCTAssertEqual(value, 1)
        
        invoker.redo()
        XCTAssertEqual(value, 2)
    }
    
    func testInvokerHistoryClearOnNewExecute() {
        let invoker = CommandInvoker()
        var value = 0
        
        // Cmd1: Set to 1
        let cmd1 = ClosureCommand(
            action: { value = 1 },
            undoAction: { value = 0 }
        )
        
        // Cmd2: Set to 2
        let cmd2 = ClosureCommand(
            action: { value = 2 },
            undoAction: { value = 1 }
        )
        
        invoker.execute(cmd1) // Val: 1
        invoker.undo()        // Val: 0
        // Here undo stack has cmd1
        
        // New execution should clear redo stack
        invoker.execute(cmd2) // Val: 2
        XCTAssertEqual(value, 2)
        
        invoker.redo() // Should do nothing because redo stack was cleared
        XCTAssertEqual(value, 2)
        
        // Undo cmd2
        invoker.undo()
        XCTAssertEqual(value, 1) // Should revert to 1 (if cmd2's undo is correct) or 0 if we assume absolute state?
        // Ah, the undoAction logic above is slightly flawed if we want true history.
        // But the test is verifying the INVOKER behavior (managing stacks), not the command logic itself per se.
        // Let's assume the undo actions are correct for this test.
    }
    
    func testDoubleUndoRedoSafety() {
        let invoker = CommandInvoker()
        var value = 0
        let cmd = ClosureCommand(
            action: { value += 1 },
            undoAction: { value -= 1 }
        )
        
        invoker.execute(cmd)
        XCTAssertEqual(value, 1)
        
        invoker.undo()
        XCTAssertEqual(value, 0)
        
        // Undo again (empty stack)
        invoker.undo()
        XCTAssertEqual(value, 0)
        
        invoker.redo()
        XCTAssertEqual(value, 1)
        
        // Redo again (empty stack)
        invoker.redo()
        XCTAssertEqual(value, 1)
    }
    
    class ComplexCommand: Command {
        var execCount = 0
        var undoCount = 0
        
        func execute() { execCount += 1 }
        func undo() { undoCount += 1 }
    }
    
    func testCommandOrder() {
        let invoker = CommandInvoker()
        let cmd1 = ComplexCommand()
        let cmd2 = ComplexCommand()
        
        invoker.execute(cmd1)
        invoker.execute(cmd2)
        
        XCTAssertEqual(cmd1.execCount, 1)
        XCTAssertEqual(cmd2.execCount, 1)
        
        invoker.undo() // cmd2
        XCTAssertEqual(cmd2.undoCount, 1)
        XCTAssertEqual(cmd1.undoCount, 0)
        
        invoker.undo() // cmd1
        XCTAssertEqual(cmd1.undoCount, 1)
    }
    
    func testBaseCommandDefaults() {
        let base = BaseCommand()
        // Should not crash
        base.execute()
        base.undo()
    }
}
