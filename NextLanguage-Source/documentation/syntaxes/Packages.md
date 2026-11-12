### Main Packaging Syntaxes

#### `:package-main`
- **Definition**: Indicates the main file of the program.
- **Syntax**: `:package-main root/me;`
  - `root/me`: Designates `/me` as the main file.
- **Examples**:
  ```
  :package-main root/me;
  # This tells the program that this is the main file and must always be at the top of the file.

  :package-main root/whatever_folder/alternatefile.package;
  # If the file is not the main file, use `.package` to indicate it as a secondary file to be executed along with the main.
  ```

#### `:package-com`
- **Definition**: Specifies execution commands within `:packaged` blocks.
- **Syntax**: `:package-com x-auto;`
  - `x-auto`: Automatically executes all commands within the `:packaged` block.
- **Example**:
  ```
  :package-com x-auto;
  ```

#### `:packaged`
- **Definition**: Groups NXL statements for execution.
- **Syntax**:
  ```
  :packaged [
      # Code block here
  ];
  ```
- **Example**:
  ```
  :packaged [
      @output Hello World
  ];
  ```

The older `:package-main`, `:package-com x-auto`, and `:package-advanced` directives are accepted for compatibility. Set the main file in `main.config.file`.
