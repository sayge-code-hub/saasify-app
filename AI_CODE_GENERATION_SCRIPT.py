#!/usr/bin/env python3
"""
AI-Powered Code Generation for Flutter/Dart HRMS

This script demonstrates automated code generation for:
1. Entities with Equatable and copyWith
2. Mappers (DTO ↔ Domain Entity)
3. Repository interfaces and implementations
4. Usecases with dependency injection
5. BLoCs with events and states
6. Comprehensive test cases

Usage:
    python3 generate_hrms_feature.py --entity Employee --fields "id,name,email,phone"

Requirements:
    pip install anthropic
"""

import anthropic
import json
from typing import Optional
import sys

# Initialize Anthropic client
client = anthropic.Anthropic()

def generate_entity(entity_name: str, fields: dict, description: str = "") -> str:
    """
    Generate a complete Dart Entity class with:
    - Equatable for equality comparison
    - Immutable fields (final)
    - copyWith() method
    - toString() override
    - toJson() and fromJson()
    """
    
    prompt = f"""
    Generate a complete Dart/Flutter entity class for {entity_name}.
    
    Entity Name: {entity_name}
    Fields: {json.dumps(fields, indent=2)}
    Description: {description}
    
    Requirements:
    1. Use @immutable and final fields
    2. Extend Equatable with all fields in props
    3. Implement copyWith() for all fields
    4. Implement toJson() and fromJson()
    5. Implement toString() for debugging
    6. Include proper null handling
    7. Add field validation where appropriate
    8. Follow Dart/Flutter naming conventions
    
    Example fields format:
    {{
        "id": "String",
        "name": "String",
        "email": "String?",
        "salary": "double",
        "isActive": "bool"
    }}
    
    Output: Production-ready Dart code only
    Include: All imports needed
    No explanations, only code
    """
    
    response = client.messages.create(
        model="claude-3-5-sonnet-20241022",
        max_tokens=4096,
        messages=[{"role": "user", "content": prompt}]
    )
    return response.content[0].text

def generate_mapper(entity_name: str, fields: dict) -> str:
    """
    Generate a Mapper class to convert between:
    - DTO (Data Transfer Object) ↔ Entity
    - Supabase response → Dart entity
    """
    
    prompt = f"""
    Generate a Dart Mapper class for {entity_name}.
    
    Entity Name: {entity_name}
    Fields: {json.dumps(fields, indent=2)}
    
    Create:
    1. {entity_name}Model (DTO class) - for API responses
    2. {entity_name}Mapper - static methods for conversion
    3. Extensions for automatic conversion
    
    Methods:
    - toDomain({entity_name}Model model) -> {entity_name}
    - toModel({entity_name} entity) -> {entity_name}Model
    - Extension: .toDomain() on {entity_name}Model
    - Extension: .toModel() on {entity_name}
    
    Include:
    - Null safety handling
    - Type conversions
    - Default value handling
    - Error handling for malformed data
    
    Output: Production-ready Dart code
    No explanations, only code
    """
    
    response = client.messages.create(
        model="claude-3-5-sonnet-20241022",
        max_tokens=4096,
        messages=[{"role": "user", "content": prompt}]
    )
    return response.content[0].text

def generate_repository(entity_name: str, operations: list) -> str:
    """
    Generate Repository interface and Supabase implementation
    
    operations: ["get", "create", "update", "delete", "list"]
    """
    
    prompt = f"""
    Generate a complete Repository for {entity_name}.
    
    Entity: {entity_name}
    Operations: {json.dumps(operations)}
    Datasource: Supabase
    
    Create:
    1. I{entity_name}Repository (abstract interface)
    2. {entity_name}Repository (implementation with Supabase)
    3. {entity_name}RemoteDatasource (Supabase queries)
    
    For each operation, include:
    - Proper error handling (ServerException, CacheException)
    - Null safety
    - Pagination where applicable
    - Filtering/sorting capabilities
    - Proper async/await
    
    Use this pattern:
    - Repository uses datasource
    - Datasource uses Supabase client
    - Proper separation of concerns
    
    Output: Production-ready Dart code
    Include: All necessary imports
    No explanations, only code
    """
    
    response = client.messages.create(
        model="claude-3-5-sonnet-20241022",
        max_tokens=4096,
        messages=[{"role": "user", "content": prompt}]
    )
    return response.content[0].text

def generate_usecases(entity_name: str, operations: list) -> str:
    """
    Generate Usecase classes for each operation
    """
    
    prompt = f"""
    Generate Usecase classes for {entity_name}.
    
    Entity: {entity_name}
    Operations: {json.dumps(operations)}
    
    Create a usecase for each operation:
    Example: Get{entity_name}Usecase, Create{entity_name}Usecase, etc.
    
    Each usecase should:
    1. Extend UseCase<Type, Params> base class
    2. Have call() method with proper signature
    3. Include dependency injection in constructor
    4. Handle errors properly
    5. Use repository for data access
    6. Include input validation
    
    Use clean architecture pattern:
    - Params class for input
    - Return type for output
    - Proper error handling
    
    Output: Production-ready Dart code
    No explanations, only code
    """
    
    response = client.messages.create(
        model="claude-3-5-sonnet-20241022",
        max_tokens=4096,
        messages=[{"role": "user", "content": prompt}]
    )
    return response.content[0].text

def generate_bloc(entity_name: str, fields: dict, operations: list) -> str:
    """
    Generate complete BLoC with events and states
    """
    
    prompt = f"""
    Generate a complete BLoC for {entity_name}.
    
    Entity: {entity_name}
    Fields: {json.dumps(fields, indent=2)}
    Operations: {json.dumps(operations)}
    
    Create:
    1. {entity_name}Event (abstract)
       - Requested{entity_name}Event
       - {entity_name}CreatedEvent
       - {entity_name}UpdatedEvent
       - {entity_name}DeletedEvent
       - etc. (one for each operation)
    
    2. {entity_name}State (abstract)
       - Initial, Loading, Success, Failure states
       - Equatable with proper props
       - copyWith() method
    
    3. {entity_name}Bloc
       - Extend Bloc<Event, State>
       - Event handlers for each operation
       - Proper error handling
       - Use corresponding usecases
       - Emit proper state transitions
    
    Follow these patterns:
    - Use bloc_test compatible code
    - Proper error messages (non-sensitive)
    - Loading states for async operations
    - Success states with data
    - Failure states with error messages
    
    Output: Production-ready Dart code
    No explanations, only code
    """
    
    response = client.messages.create(
        model="claude-3-5-sonnet-20241022",
        max_tokens=4096,
        messages=[{"role": "user", "content": prompt}]
    )
    return response.content[0].text

def generate_tests(entity_name: str, operations: list) -> str:
    """
    Generate comprehensive test cases
    """
    
    prompt = f"""
    Generate comprehensive test file for {entity_name}Bloc.
    
    Entity: {entity_name}
    Operations: {json.dumps(operations)}
    
    Create tests using bloc_test package:
    1. Initial state test
    2. Each operation:
       - Happy path (success)
       - Error scenario
       - Edge cases
    3. State transition tests
    4. Event handling tests
    5. Mock setup using mockito
    
    Include:
    - Proper mocking of usecases
    - setUp() and tearDown()
    - Multiple test cases per operation
    - Edge case handling
    - Error message verification
    
    Use blocTest widget for all BLoC tests:
    ```dart
    blocTest<{entity_name}Bloc, {entity_name}State>(
      'description',
      build: () => bloc,
      act: (bloc) => bloc.add(event),
      expect: () => [state1, state2],
    );
    ```
    
    Output: Production-ready Dart test code
    Include: All imports and setup
    No explanations, only code
    """
    
    response = client.messages.create(
        model="claude-3-5-sonnet-20241022",
        max_tokens=4096,
        messages=[{"role": "user", "content": prompt}]
    )
    return response.content[0].text

def analyze_code_for_improvements(code_snippet: str) -> str:
    """
    Analyze code and suggest performance, security, and best practice improvements
    """
    
    prompt = f"""
    Analyze this Dart/Flutter code and suggest improvements for:
    1. Performance optimization
    2. Security best practices
    3. Code quality and maintainability
    4. Memory efficiency
    5. Error handling
    
    Code to analyze:
    ```dart
    {code_snippet}
    ```
    
    Provide:
    1. List of issues found
    2. Severity level (Critical, High, Medium, Low)
    3. Suggested fix for each issue
    4. Improved code example
    5. Performance impact estimate
    
    Format as structured analysis with before/after code examples.
    """
    
    response = client.messages.create(
        model="claude-3-5-sonnet-20241022",
        max_tokens=4096,
        messages=[{"role": "user", "content": prompt}]
    )
    return response.content[0].text

def find_duplicate_patterns(code_files: list) -> str:
    """
    Scan multiple code files for duplicate patterns
    """
    
    prompt = f"""
    Scan these code snippets for duplicate patterns and opportunities to refactor:
    
    Files to analyze: {code_files}
    
    Find:
    1. Repeated validation logic
    2. Similar error handling patterns
    3. Duplicate widget structures
    4. Similar API call patterns
    5. Repeated business logic
    
    For each duplicate found:
    - Location (file name and approximate line)
    - Pattern description
    - Suggested refactoring
    - Code example
    - Lines of code saved
    
    Provide structured analysis.
    """
    
    response = client.messages.create(
        model="claude-3-5-sonnet-20241022",
        max_tokens=4096,
        messages=[{"role": "user", "content": prompt}]
    )
    return response.content[0].text

# ============================================================
# Example Usage
# ============================================================

def main():
    """
    Demonstrate code generation for a sample feature
    """
    
    print("=" * 70)
    print("HRMS AI Code Generation POC")
    print("=" * 70)
    
    # Example: Generate code for Payroll feature
    entity_name = "PayrollRecord"
    
    fields = {
        "id": "String",
        "employeeId": "String",
        "month": "String",  # YYYY-MM format
        "baseSalary": "double",
        "bonusAmount": "double?",
        "deductions": "double?",
        "netPay": "double",
        "status": "PayrollStatus",  # enum
        "processedAt": "DateTime?",
        "paidAt": "DateTime?",
        "createdAt": "DateTime",
        "updatedAt": "DateTime"
    }
    
    operations = ["get", "create", "update", "process", "markAsPaid", "list"]
    
    print(f"\n📝 Generating code for: {entity_name}")
    print(f"   Fields: {len(fields)}")
    print(f"   Operations: {operations}")
    
    # 1. Generate Entity
    print("\n[1/6] Generating Entity + Mapper...")
    entity_code = generate_entity(
        entity_name,
        fields,
        "Represents employee payroll record for a specific month"
    )
    print("✅ Entity generated")
    
    # 2. Generate Mapper
    print("\n[2/6] Generating Mapper (DTO ↔ Entity)...")
    mapper_code = generate_mapper(entity_name, fields)
    print("✅ Mapper generated")
    
    # 3. Generate Repository
    print("\n[3/6] Generating Repository + Datasource...")
    repo_code = generate_repository(entity_name, operations)
    print("✅ Repository generated")
    
    # 4. Generate Usecases
    print("\n[4/6] Generating Usecases...")
    usecases_code = generate_usecases(entity_name, operations)
    print("✅ Usecases generated")
    
    # 5. Generate BLoC
    print("\n[5/6] Generating BLoC...")
    bloc_code = generate_bloc(entity_name, fields, operations)
    print("✅ BLoC generated")
    
    # 6. Generate Tests
    print("\n[6/6] Generating Test Cases...")
    tests_code = generate_tests(entity_name, operations)
    print("✅ Tests generated")
    
    # Save all generated code to files
    output_dir = "/tmp/hrms_generated"
    import os
    os.makedirs(output_dir, exist_ok=True)
    
    files = {
        f"{output_dir}/{entity_name.lower()}_entity.dart": entity_code,
        f"{output_dir}/{entity_name.lower()}_mapper.dart": mapper_code,
        f"{output_dir}/{entity_name.lower()}_repository.dart": repo_code,
        f"{output_dir}/{entity_name.lower()}_usecases.dart": usecases_code,
        f"{output_dir}/{entity_name.lower()}_bloc.dart": bloc_code,
        f"{output_dir}/{entity_name.lower()}_bloc_test.dart": tests_code,
    }
    
    print("\n" + "=" * 70)
    print("📁 Generated Files")
    print("=" * 70)
    
    for filepath, content in files.items():
        with open(filepath, 'w') as f:
            f.write(content)
        line_count = len(content.split('\n'))
        print(f"✅ {filepath.split('/')[-1]}: {line_count} lines")
    
    # Summary
    total_lines = sum(len(c.split('\n')) for c in files.values())
    print("\n" + "=" * 70)
    print("📊 Generation Summary")
    print("=" * 70)
    print(f"Total Files Generated: {len(files)}")
    print(f"Total Lines of Code: {total_lines}")
    print(f"Time Saved: ~8-12 hours of manual development")
    print(f"Output Directory: {output_dir}")
    print("\n✨ All files ready for use!")

if __name__ == "__main__":
    main()
