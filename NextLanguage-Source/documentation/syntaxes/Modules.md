### Module Syntaxes

#### `@output`
- **Definition**: Outputs text or variable contents to the program’s output.
- **Syntax**: `@output <content>;`
- **Example 1**:
  ```
  @output Hello World;
  ```
- **Example 2**:
  ```
  @var [username]: "abie";
  @output username;
  ```

#### `@if` Statement
- **Definition**: Implements conditional logic.
- **Syntax**:
  ```
  @if [condition]:
      # Code block if condition is true
  @else
      # Code block if condition is false
  @end
  ```
- **Example 1**:
  ```
  @var [x]: (integer)11
  @if [x > 10]
      @output x is greater than 10;
  @else
      @output x is less than 10;
  @end
  ```

- **Example 2**:
  ```
  @var [raining]: (boolean)true;

  @if [raining === true]:
      @output It's raining;
  @else
      @output It's not raining;
  @end
  ```

#### `@function`
- **Definition**: Defines a function that can be executed later.
- **Syntax**:
  ```
  @function [name]:
      # Function body
  @end
  ```
- **Examples**:
  ```
  @function [say_abc]:
      @output abc;
  @end
  ```

#### `:set`
- **Definition**: Assigns a value to a variable.
- **Syntax**:
  ```
  :set [@variable]: /name(value);
  ```
- **Example**:
  ```
  :set [@variable]: /raining(true);
  ```


Call a function with `@call :function[say_abc]`. To give a function parameters, declare them as the first line of its body:

```text
@function [greet]:
    :params [name]
    @output name
@end
@call :function[greet]("Someone")
```

#### Loops

```text
@for [i] in [1..3]:
    @output i
@end

@var [remaining]: (integer)2
@while [remaining > 0]:
    @output remaining
    :set [@variable]: /remaining(remaining - 1)
@end
```

A for range includes both endpoints when the step reaches the endpoint. Use `[1..9 step 2]` to specify a positive step.

#### Imports and exports

Use `:packages greet @export` after defining the function to export it. In a different file, write `:packages greet @import ./helpers.nxl` to make it available as `@call :function[greet]`. Use `:packages null @import ./helpers.nxl` to run the imported file without binding a function.
