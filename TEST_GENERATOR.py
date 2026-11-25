"""
AI-Powered Test Generation for Flutter/Dart HRMS

This module analyzes existing code and generates comprehensive test cases
covering happy paths, error scenarios, edge cases, and integration tests.

Usage:
    from test_generator import TestAnalyzer
    
    analyzer = TestAnalyzer()
    test_code = analyzer.analyze_and_generate("path/to/bloc.dart")
    print(test_code)
"""

import anthropic
from typing import Optional, List
import re

class TestAnalyzer:
    """AI-powered test case generator for Flutter/Dart code"""
    
    def __init__(self):
        self.client = anthropic.Anthropic()
        self.model = "claude-3-5-sonnet-20241022"
    
    def analyze_and_generate_bloc_tests(self, bloc_code: str, bloc_name: str) -> str:
        """
        Analyze BLoC code and generate comprehensive test cases
        
        Args:
            bloc_code: The complete BLoC implementation
            bloc_name: Name of the BLoC (e.g., "EmployeeBloc")
        
        Returns:
            Complete test file code
        """
        
        prompt = f"""
        Analyze this BLoC implementation and generate comprehensive test cases.
        
        BLoC Name: {bloc_name}
        
        Code:
        ```dart
        {bloc_code}
        ```
        
        Generate test file that includes:
        
        1. **Initial State Tests**
           - Verify initial state is correct
           - Verify no events are emitted on creation
        
        2. **Event Handler Tests** (for EACH event in the BLoC)
           - Happy path: successful operation
           - Error scenarios: various exception types
           - Edge cases: empty inputs, null values, boundary values
           - Concurrency: multiple events fired simultaneously
        
        3. **State Transition Tests**
           - Verify correct state sequence (Initial -> Loading -> Success)
           - Verify error states properly set error messages
           - Verify data is preserved across state changes
        
        4. **Mock Setup**
           - Use mockito for mocking dependencies
           - Create proper mock setup functions
           - Verify mocks are called with correct arguments
        
        5. **Error Handling Tests**
           - Network errors
           - Server errors (400, 500, etc.)
           - Timeout errors
           - Parsing/serialization errors
        
        6. **Edge Cases**
           - Empty lists
           - Null values
           - Very large data
           - Duplicate items
           - Invalid state transitions
        
        Test Framework: bloc_test package
        Mocking Framework: mockito
        
        Requirements:
        - Use blocTest for all BLoC tests
        - Proper setUp() and tearDown()
        - Clear test descriptions
        - Verify all event handlers
        - Test all branches of code
        - Mock all dependencies
        - No actual API calls or database access
        
        Output:
        - Production-ready Dart test code
        - Complete test file (ready to copy-paste)
        - All imports included
        - Minimum 15 test cases
        
        Format as: test_bloc_name.dart
        """
        
        response = self.client.messages.create(
            model=self.model,
            max_tokens=4096,
            messages=[{"role": "user", "content": prompt}]
        )
        return response.content[0].text
    
    def analyze_and_generate_repository_tests(self, repo_code: str, repo_name: str) -> str:
        """
        Analyze Repository code and generate tests
        """
        
        prompt = f"""
        Generate comprehensive test cases for this Repository.
        
        Repository: {repo_name}
        
        Code:
        ```dart
        {repo_code}
        ```
        
        Generate tests that cover:
        1. All public methods
        2. Success paths with valid data
        3. Error handling (network, server, parsing errors)
        4. Null/empty data handling
        5. Data transformation (DTO to Entity mapping)
        6. Pagination and filtering
        7. Caching behavior (if applicable)
        8. Concurrent operations
        
        Mock:
        - Remote datasource
        - Local datasource
        - Mapper classes
        
        Output: Complete test file using test package
        """
        
        response = self.client.messages.create(
            model=self.model,
            max_tokens=4096,
            messages=[{"role": "user", "content": prompt}]
        )
        return response.content[0].text
    
    def analyze_and_generate_widget_tests(self, widget_code: str, widget_name: str) -> str:
        """
        Analyze Widget/Page code and generate widget tests
        """
        
        prompt = f"""
        Generate comprehensive widget tests for this Flutter widget.
        
        Widget: {widget_name}
        
        Code:
        ```dart
        {widget_code}
        ```
        
        Generate tests that verify:
        1. Widget renders correctly
        2. All widgets are present (find.byType, find.byText, etc.)
        3. User interactions work (tap, scroll, input)
        4. BLoC states render correct UI
        5. Error states display error messages
        6. Loading states show loading indicator
        7. Success states display data
        8. Navigation works correctly
        9. Form validation works
        10. Responsiveness (different screen sizes)
        
        Use:
        - testWidgets framework
        - WidgetTester
        - MockBuild for BLoCs
        
        Output: Complete widget test file
        """
        
        response = self.client.messages.create(
            model=self.model,
            max_tokens=4096,
            messages=[{"role": "user", "content": prompt}]
        )
        return response.content[0].text
    
    def suggest_missing_test_cases(self, code: str, existing_tests: Optional[str] = None) -> str:
        """
        Analyze code and suggest missing test cases
        """
        
        prompt = f"""
        Analyze this code and suggest missing test cases.
        
        Code to analyze:
        ```dart
        {code}
        ```
        
        {f'Existing tests: ```dart\\n{existing_tests}\\n```' if existing_tests else ''}
        
        Identify:
        1. Untested methods
        2. Uncovered branches (if/else paths)
        3. Missing error scenarios
        4. Missing edge cases
        5. Missing integration tests
        
        For each missing test case, provide:
        - Test name
        - What it tests
        - Input data
        - Expected output
        - Code example
        
        Format as: Markdown with code blocks
        """
        
        response = self.client.messages.create(
            model=self.model,
            max_tokens=4096,
            messages=[{"role": "user", "content": prompt}]
        )
        return response.content[0].text
    
    def generate_integration_test(self, features: List[str], app_structure: str) -> str:
        """
        Generate integration test scenarios
        """
        
        prompt = f"""
        Generate integration test cases for Flutter app.
        
        Features to test: {', '.join(features)}
        
        App Structure:
        ```
        {app_structure}
        ```
        
        Create integration tests that verify:
        1. Complete user workflows (end-to-end)
        2. Navigation between screens
        3. Data persistence across screens
        4. API integration with real endpoints
        5. Error recovery flows
        6. Offline mode (if applicable)
        
        Use: integration_test package
        
        Output: integration_test file with 5-10 test scenarios
        """
        
        response = self.client.messages.create(
            model=self.model,
            max_tokens=4096,
            messages=[{"role": "user", "content": prompt}]
        )
        return response.content[0].text
    
    def analyze_code_coverage_gaps(self, code: str, test_code: str) -> str:
        """
        Analyze code coverage and identify gaps
        """
        
        prompt = f"""
        Analyze code coverage and identify gaps.
        
        Code:
        ```dart
        {code}
        ```
        
        Existing Tests:
        ```dart
        {test_code}
        ```
        
        Provide:
        1. Lines that are not covered
        2. Branches that are not tested
        3. Exception paths not covered
        4. Priority (critical, high, medium) for each gap
        5. Test case suggestions to cover gaps
        
        Format as: Structured analysis with line numbers
        """
        
        response = self.client.messages.create(
            model=self.model,
            max_tokens=4096,
            messages=[{"role": "user", "content": prompt}]
        )
        return response.content[0].text
    
    def generate_performance_tests(self, code: str, component_name: str) -> str:
        """
        Generate performance and optimization tests
        """
        
        prompt = f"""
        Generate performance tests for this component.
        
        Component: {component_name}
        
        Code:
        ```dart
        {code}
        ```
        
        Create tests that verify:
        1. Response time is within acceptable limits
        2. Memory usage doesn't increase significantly
        3. No unnecessary rebuilds of widgets
        4. Database queries are optimized
        5. API calls are batched/debounced if applicable
        6. Large data sets are handled efficiently
        
        Use benchmarking and profiling approaches:
        - Stopwatch for timing
        - Memory profiling (if applicable)
        - Build/frame tracking for widgets
        
        Output: Performance test file with benchmarks
        """
        
        response = self.client.messages.create(
            model=self.model,
            max_tokens=4096,
            messages=[{"role": "user", "content": prompt}]
        )
        return response.content[0].text


# ============================================================
# Example Usage
# ============================================================

def demonstrate_test_generation():
    """
    Demonstrate test generation capabilities
    """
    
    analyzer = TestAnalyzer()
    
    # Example BLoC code to analyze
    sample_bloc = """
    class EmployeeBloc extends Bloc<EmployeeEvent, EmployeeState> {
      final GetEmployeeUsecase getEmployeeUsecase;
      final CreateEmployeeUsecase createEmployeeUsecase;
      
      EmployeeBloc(this.getEmployeeUsecase, this.createEmployeeUsecase)
          : super(const EmployeeState.initial()) {
        on<EmployeeRequested>(_onEmployeeRequested);
        on<EmployeeCreated>(_onEmployeeCreated);
      }
      
      Future<void> _onEmployeeRequested(
        EmployeeRequested event,
        Emitter<EmployeeState> emit,
      ) async {
        emit(state.copyWith(status: Status.loading));
        try {
          final employee = await getEmployeeUsecase(event.employeeId);
          emit(state.copyWith(status: Status.success, employee: employee));
        } catch (e) {
          emit(state.copyWith(status: Status.failure, error: e.toString()));
        }
      }
      
      Future<void> _onEmployeeCreated(
        EmployeeCreated event,
        Emitter<EmployeeState> emit,
      ) async {
        emit(state.copyWith(status: Status.loading));
        try {
          await createEmployeeUsecase(event.employee);
          emit(state.copyWith(status: Status.success));
        } catch (e) {
          emit(state.copyWith(status: Status.failure, error: e.toString()));
        }
      }
    }
    """
    
    print("=" * 70)
    print("Test Generation POC - Analyzing BLoC")
    print("=" * 70)
    
    print("\n📝 Analyzing EmployeeBloc...")
    tests = analyzer.analyze_and_generate_bloc_tests(sample_bloc, "EmployeeBloc")
    
    print("\n✅ Generated Tests:")
    print(tests[:500] + "...")  # Show first 500 chars
    
    # Suggest missing test cases
    print("\n" + "=" * 70)
    print("Finding Missing Test Cases")
    print("=" * 70)
    
    missing = analyzer.suggest_missing_test_cases(sample_bloc)
    print("\n📋 Suggested Missing Tests:")
    print(missing[:500] + "...")


if __name__ == "__main__":
    demonstrate_test_generation()
