"""
AI-Powered Code Analysis for Flutter/Dart HRMS

This module analyzes code for:
1. Performance bottlenecks and optimization opportunities
2. Security vulnerabilities and best practices
3. Code duplications and refactoring suggestions
4. Design pattern improvements
5. Code smell detection
6. Maintainability issues

Usage:
    from code_analyzer import CodeAnalyzer
    
    analyzer = CodeAnalyzer()
    report = analyzer.analyze_performance("path/to/widget.dart")
    print(report)
"""

import anthropic
from typing import Optional
from enum import Enum


class AnalysisType(Enum):
    """Types of code analysis available"""
    PERFORMANCE = "performance"
    SECURITY = "security"
    DUPLICATION = "duplication"
    DESIGN = "design"
    MAINTAINABILITY = "maintainability"
    ALL = "all"


class CodeAnalyzer:
    """AI-powered code analyzer for Flutter/Dart"""
    
    def __init__(self):
        self.client = anthropic.Anthropic()
        self.model = "claude-3-5-sonnet-20241022"
    
    def analyze_performance(self, code: str, component_name: str = "Component") -> str:
        """
        Analyze code for performance bottlenecks and optimization opportunities
        """
        
        prompt = f"""
        Perform detailed performance analysis of this Flutter/Dart code.
        
        Component: {component_name}
        
        Code:
        ```dart
        {code}
        ```
        
        Analyze for:
        1. **Rendering Performance**
           - Unnecessary rebuilds (especially in ListView)
           - Heavy computations in build() method
           - Inefficient layouts (nested Columns/Rows)
           - Image loading without cache
           - Unoptimized CustomPainter operations
        
        2. **Memory Leaks**
           - Listeners not disposed
           - Subscriptions not cancelled
           - Large objects kept in state
           - Circular references
        
        3. **Algorithmic Efficiency**
           - O(n²) loops that could be O(n)
           - Redundant calculations
           - Inefficient data structures
           - Repeated database queries
        
        4. **Bundle Size Issues**
           - Unused imports
           - Duplicate dependencies
           - Large assets not optimized
        
        5. **Network Efficiency**
           - Multiple API calls that could be batched
           - Missing pagination
           - Excessive polling
           - Missing request deduplication
        
        For each issue found, provide:
        - **Issue**: Clear description
        - **Location**: File and line number (if visible)
        - **Impact**: Performance impact (High/Medium/Low), and estimated improvement
        - **Root Cause**: Why this happens
        - **Solution**: Step-by-step fix
        - **Code Example**: Before and after code
        - **Tools/Packages**: Recommended tools (e.g., cached_network_image, riverpod)
        
        Format output as:
        ```
        ## Issue #1: [Title]
        **Severity**: High | **Impact**: 50% faster rendering
        **Location**: Line X-Y
        
        **Problem**: 
        [Description]
        
        **Why It Happens**:
        [Root cause]
        
        **Solution**:
        1. [Step 1]
        2. [Step 2]
        
        **Before**:
        ```dart
        [Code]
        ```
        
        **After**:
        ```dart
        [Code]
        ```
        
        **Tools**:
        - recommended_package: https://pub.dev/packages/...
        ```
        
        Order issues by severity and estimated performance impact.
        End with: Performance Improvement Summary and Overall Score
        """
        
        response = self.client.messages.create(
            model=self.model,
            max_tokens=4096,
            messages=[{"role": "user", "content": prompt}]
        )
        return response.content[0].text
    
    def analyze_security(self, code: str, component_name: str = "Component") -> str:
        """
        Analyze code for security vulnerabilities and best practices
        """
        
        prompt = f"""
        Perform detailed security analysis of this Flutter/Dart code.
        
        Component: {component_name}
        
        Code:
        ```dart
        {code}
        ```
        
        Security Analysis Checklist:
        
        1. **Input Validation**
           - User input validation (forms, API params)
           - Injection attack prevention (SQL, NoSQL, etc.)
           - File path validation
           - Type checking
        
        2. **Authentication & Authorization**
           - Token handling and storage
           - Session management
           - Permission checks
           - Privilege escalation risks
        
        3. **Data Security**
           - Sensitive data in memory/logs
           - Hardcoded secrets or credentials
           - Unencrypted API keys
           - Proper data masking
        
        4. **API Security**
           - API endpoint validation
           - Request/response validation
           - Certificate pinning (if applicable)
           - Rate limiting
        
        5. **Storage Security**
           - Secure local storage usage
           - File permissions
           - SQLite encryption (if applicable)
           - Secure deletion of sensitive data
        
        6. **Network Security**
           - HTTPS enforcement
           - SSL/TLS certificate validation
           - Secure data transmission
           - Man-in-the-middle attack prevention
        
        7. **Code Vulnerabilities**
           - Unhandled exceptions
           - Debug code left in production
           - Logging sensitive data
           - Use of insecure packages
        
        For each vulnerability found, provide:
        - **Vulnerability**: OWASP/CWE reference if applicable
        - **Severity**: Critical/High/Medium/Low
        - **Location**: File and line
        - **Description**: What's wrong and why it's a risk
        - **Exploitation**: How an attacker could exploit this
        - **Impact**: Potential damage
        - **Fix**: How to fix it
        - **Code Example**: Secure version
        
        Format as markdown with severity badges (🔴/🟠/🟡/⚪)
        
        End with:
        - Security Score (out of 10)
        - Risk Assessment
        - Recommended Security Hardening Steps
        """
        
        response = self.client.messages.create(
            model=self.model,
            max_tokens=4096,
            messages=[{"role": "user", "content": prompt}]
        )
        return response.content[0].text
    
    def find_duplications(self, code_files: list) -> str:
        """
        Analyze multiple code files for duplicate patterns and suggest refactoring
        
        Args:
            code_files: List of tuples (filename, code_content)
        """
        
        files_text = "\n\n".join([
            f"=== {filename} ===\n```dart\n{code}\n```"
            for filename, code in code_files
        ])
        
        prompt = f"""
        Analyze these code files for duplicate patterns and refactoring opportunities.
        
        Files:
        {files_text}
        
        Find:
        1. **Duplicate Code Blocks**
           - Identical or near-identical code
           - Similar logic with different variable names
           - Repeated patterns
        
        2. **Duplicate Logic**
           - Similar business logic in different methods
           - Repeated validation logic
           - Similar error handling
        
        3. **Duplicate Widgets/UI**
           - Similar widget structures
           - Repeated styling patterns
           - Similar layouts
        
        4. **Refactoring Opportunities**
           - Extract common code to shared utility
           - Create reusable components
           - Use inheritance/composition to DRY
           - Apply builder patterns
        
        For each duplication found, provide:
        - **Pattern**: Description of what's duplicated
        - **Locations**: Files and line numbers where duplicated
        - **Occurrences**: How many times repeated
        - **Lines Duplicated**: Total lines
        - **Severity**: Critical/High/Medium (DRY violation level)
        - **Refactoring Strategy**: How to eliminate duplication
        - **Extracted Code**: What should be extracted
        - **New Structure**: How the refactored code would look
        - **Benefits**: Code size saved, maintainability improvement
        
        Format as:
        ```
        ## Duplication #1: [Pattern Name]
        **Files**: file1.dart (line X-Y), file2.dart (line A-B)
        **Occurrences**: 3 times
        **Total Duplicate Lines**: 45
        
        **Current Pattern**:
        ```dart
        [Code]
        ```
        
        **Refactored Version**:
        ```dart
        // shared_validators.dart
        [Extracted code]
        ```
        
        **Impact**: Save 60 lines, simplify maintenance
        ```
        
        Order by impact (lines saved and maintainability benefit).
        End with: Duplication Summary and Total Refactoring Effort.
        """
        
        response = self.client.messages.create(
            model=self.model,
            max_tokens=4096,
            messages=[{"role": "user", "content": prompt}]
        )
        return response.content[0].text
    
    def analyze_design_patterns(self, code: str, component_name: str = "Component") -> str:
        """
        Analyze code design and suggest improvements
        """
        
        prompt = f"""
        Analyze design patterns and architecture of this code.
        
        Component: {component_name}
        
        Code:
        ```dart
        {code}
        ```
        
        Analysis:
        1. **Current Design Patterns**
           - What patterns are used (Observer, Factory, Builder, etc.)
           - Are patterns applied correctly
           - Are patterns overdone (over-engineering)
        
        2. **SOLID Principles**
           - Single Responsibility: Does class have one reason to change?
           - Open/Closed: Is code open for extension, closed for modification?
           - Liskov Substitution: Are subtypes substitutable?
           - Interface Segregation: Are interfaces focused?
           - Dependency Inversion: Does code depend on abstractions?
        
        3. **Code Cleanliness**
           - God classes (too many responsibilities)
           - Long methods (should be <30 lines)
           - Complex conditionals (should use guard clauses)
           - Tight coupling between classes
        
        4. **Abstraction Level**
           - Are abstractions appropriate?
           - Is code over-abstracted (premature generalization)?
           - Are design decisions clear?
        
        5. **Recommended Improvements**
           - Apply/improve design patterns
           - Refactor for SOLID principles
           - Improve code organization
           - Better separation of concerns
        
        For each issue:
        - **Issue**: What needs improvement
        - **Why**: Why it matters
        - **Current Code**: Code that needs improvement
        - **Improved Code**: How it should be refactored
        - **Pattern**: Design pattern to use (if applicable)
        - **Benefits**: Maintainability, testability, flexibility improvements
        
        Order by impact on code quality and maintainability.
        """
        
        response = self.client.messages.create(
            model=self.model,
            max_tokens=4096,
            messages=[{"role": "user", "content": prompt}]
        )
        return response.content[0].text
    
    def detect_code_smells(self, code: str, component_name: str = "Component") -> str:
        """
        Detect code smells and maintainability issues
        """
        
        prompt = f"""
        Detect code smells and maintainability issues in this code.
        
        Component: {component_name}
        
        Code:
        ```dart
        {code}
        ```
        
        Code Smells to Look For:
        1. **Long Methods**: Methods >30 lines
        2. **Long Classes**: Classes >300 lines
        3. **Long Parameters**: Methods with >4 parameters
        4. **Duplicate Code**: Similar logic repeated
        5. **Dead Code**: Unused methods/variables
        6. **Comments**: Code that needs comments (bad smell)
        7. **Magic Numbers**: Unexplained constants
        8. **Lazy Classes**: Classes with little responsibility
        9. **Data Clumps**: Groups of variables always together
        10. **Switch Statements**: Large if/else or switch chains
        11. **Speculative Generality**: Over-engineered for future needs
        12. **Temporary Variables**: Unnecessary intermediate variables
        
        For each smell found:
        - **Type**: Which code smell
        - **Location**: Line numbers
        - **Description**: What's wrong
        - **Impact**: How it affects maintainability
        - **Severity**: Critical/High/Medium/Low
        - **Fix**: How to refactor it
        - **Example**: Before and after code
        
        Rate code smell severity:
        🔴 Critical: Must fix
        🟠 High: Should fix soon
        🟡 Medium: Consider fixing
        ⚪ Low: Nice to have
        
        End with: Code Quality Score and Refactoring Priority List
        """
        
        response = self.client.messages.create(
            model=self.model,
            max_tokens=4096,
            messages=[{"role": "user", "content": prompt}]
        )
        return response.content[0].text
    
    def comprehensive_analysis(self, code: str, component_name: str = "Component") -> str:
        """
        Perform comprehensive analysis across all dimensions
        """
        
        prompt = f"""
        Perform COMPREHENSIVE code analysis across all dimensions.
        
        Component: {component_name}
        
        Code:
        ```dart
        {code}
        ```
        
        Run all analyses:
        1. Performance Analysis
        2. Security Analysis
        3. Design Pattern Analysis
        4. Code Smell Detection
        5. Maintainability Assessment
        
        Provide:
        - Detailed findings for each dimension
        - Severity ratings (🔴🟠🟡⚪)
        - Quick wins (easy fixes, high impact)
        - Major refactoring recommendations
        - Overall code quality score (out of 100)
        
        Format as comprehensive report with sections and actionable recommendations.
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

def demonstrate_code_analysis():
    """
    Demonstrate code analysis capabilities
    """
    
    analyzer = CodeAnalyzer()
    
    # Sample widget code with performance issues
    sample_widget = """
    class EmployeeListPage extends StatelessWidget {
      @override
      Widget build(BuildContext context) {
        return Scaffold(
          appBar: AppBar(title: Text('Employees')),
          body: BlocBuilder<EmployeesBloc, EmployeesState>(
            builder: (context, state) {
              return ListView.builder(
                itemCount: state.employees.length,
                itemBuilder: (context, index) {
                  final employee = state.employees[index];
                  return Card(
                    child: Column(
                      children: [
                        Image.network(employee.photoUrl),  // ⚠️ No caching
                        Text(employee.name),
                        Text(employee.salary.toString()),
                        _buildDetailedInfo(employee),  // ⚠️ Expensive calculation
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () => _editEmployee(context, employee),
                              child: Text('Edit'),
                            ),
                            ElevatedButton(
                              onPressed: () => _deleteEmployee(context, employee),
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      }
      
      Widget _buildDetailedInfo(Employee employee) {
        // Complex calculation every frame
        final annualSalary = employee.monthlySalary * 12;
        final tax = annualSalary * 0.3;
        final pension = annualSalary * 0.12;
        return Column(
          children: [
            Text('Annual: $annualSalary'),
            Text('Tax: $tax'),
            Text('Pension: $pension'),
          ],
        );
      }
    }
    """
    
    print("=" * 70)
    print("Code Analysis POC")
    print("=" * 70)
    
    # Performance Analysis
    print("\n📊 Running Performance Analysis...")
    perf_report = analyzer.analyze_performance(sample_widget, "EmployeeListPage")
    print("✅ Performance Analysis Complete")
    print(perf_report[:500] + "...")
    
    # Code Smells
    print("\n🐛 Detecting Code Smells...")
    smells_report = analyzer.detect_code_smells(sample_widget, "EmployeeListPage")
    print("✅ Code Smell Detection Complete")
    print(smells_report[:500] + "...")


if __name__ == "__main__":
    demonstrate_code_analysis()
