# Contributing to DesignAlgorithmsKit

This document provides guidelines and instructions for internal contributors to DesignAlgorithmsKit.

> **Note**: This project is currently internal-only. External contributions are not accepted at this time.

## Code of Conduct

This project adheres to a Code of Conduct that all contributors are expected to follow. Please read [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) before contributing.

## How to Contribute (Internal Contributors)

### Reporting Bugs

If you find a bug, please:
- Open an issue with a clear, descriptive title
- Include steps to reproduce the issue
- Describe expected vs actual behavior
- Provide Swift version and platform information
- Include code samples if applicable

### Suggesting Enhancements

Enhancement suggestions are welcome! Please open an issue with:
- A clear description of the enhancement
- Use cases and examples
- Potential implementation approach (if you have one)

### Contributing Code

1. **Create a new branch** from `main`
   ```bash
   git checkout -b feat/your-feature-name
   ```

2. **Follow the coding standards**:
   - Follow [Apple's Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
   - Write clear, self-documenting code
   - Add comments for complex logic
   - Keep functions focused and small

3. **Write tests**:
   - All new features must include unit tests
   - Aim for high code coverage
   - Tests should be clear and well-organized

4. **Update documentation**:
   - Update README.md if adding new features
   - Add DocC documentation comments for public APIs
   - Update CHANGELOG.md under `[Unreleased]`

5. **Commit your changes**:
   - Use [Conventional Commits](https://www.conventionalcommits.org/) format
   - Examples:
     - `feat(patterns): Add Observer pattern implementation`
     - `fix(merkle): Fix proof verification logic`
     - `docs(readme): Update installation instructions`
     - `test(bloom): Add edge case tests`

6. **Push and create a Pull Request**:
   ```bash
   git push -u origin feat/your-feature-name
   ```
   - Create a PR with a clear title and description
   - Reference any related issues
   - Ensure all CI checks pass
   - Request review from team members

## Development Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/rickhohler/DesignAlgorithmsKit.git
   cd DesignAlgorithmsKit
   ```

2. Build the package:
   ```bash
   swift build
   ```

3. Run tests:
   ```bash
   swift test
   ```

4. Run tests with coverage:
   ```bash
   swift test --enable-code-coverage
   ```

## Design Patterns

When adding new design patterns:

1. Follow the existing pattern structure
2. Use protocols for extensibility
3. Ensure thread safety (use NSLock or Actor)
4. Add comprehensive unit tests
5. Document with DocC comments
6. Update README.md with usage examples

## Algorithms

When adding new algorithms:

1. Provide clear documentation
2. Include complexity analysis (time/space)
3. Add unit tests with edge cases
4. Consider performance optimizations
5. Update README.md with usage examples

## Pull Request Process

1. Ensure your code follows the project's style guidelines
2. Make sure all tests pass locally
3. Update documentation as needed
4. Add your changes to CHANGELOG.md
5. Request review from maintainers
6. Address any feedback promptly

## Questions?

For internal contributors, feel free to:
- Open an issue for questions or discussions
- Reach out directly to the maintainers
- Discuss in team channels

Thank you for contributing to DesignAlgorithmsKit! 🎉

