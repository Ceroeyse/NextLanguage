### Variable Syntaxes

#### `@variable` / `@var`
- **Definition**: Defines a variable for storing data.
- **Syntax**: `@variable [name]: value` or `@var [name]: value`
- **Examples**:
  ```
  @variable [username]: "abie"
  @var [negatives]: (negative)-10
  ```

#### Data Types:
- **String**: Default type if no type is specified.
  ```
  @variable [username]: "abie"
  ```
- **Boolean**:
  ```
  @var [raining]: (boolean)true
  ```
- **Integer**:
  ```
  @var [score]: (integer)10
  ```
  - Alias: `int`
- **Double (Decimal)**:
  ```
  @var [decimal]: (double)1.9
  ```
- **Percentage**:
  ```
  @var [percentage]: (percentage)10%
  ```
  - Alias: `percent`
- **Decimal Percentage**:
  ```
  @var [decimal_percent]: (percent)0.9
  ```

Use `@output name` to print the value of a variable.
