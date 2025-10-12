# Contributing to Neovim OOP Config

Welcome! This config is organized for clarity, extensibility, and ease of contribution.

## How the Config Works

- The main logic is encapsulated in an OOP-style Lua table (`NvConfig`).
- All setup steps are methods: bootstrapping, plugin setup, options, diagnostics.
- **Plugins** are specified in the `spec` array in the `setup_plugins()` method.

---

## How to Add a Plugin

1. **Find the `setup_plugins()` method** in `init.lua`.
2. **Add a new table** to the `spec` array:
    ```lua
    {
      "author/plugin-name",
      config = function()
        -- plugin setup code
        require("plugin-name").setup({})
      end,
      opts = { ... }, -- optional
      dependencies = { ... }, -- optional
    },
    ```
3. **See** [lazy.nvim docs](https://github.com/folke/lazy.nvim#spec) for advanced options.

---

## Changing Options

- Edit `set_options()` to add or override Neovim options:
    ```lua
    vim.o.<option> = <value>
    ```

## Keymaps

- Add keymaps to the `keys` array of relevant plugins (e.g., `which-key.nvim`).
- For global keymaps, consider a new method in the class (e.g., `set_keymaps()`).

---

## Diagnostics

- Extend diagnostics setup in `setup_diagnostics()`.

---

## Extending/Modifying

- You can subclass `NvConfig` for advanced usage.
- Add new methods for features, refactoring, or hooks.

---

## Coding Conventions

- Keep plugin specs, methods, and options grouped and well-commented.
- Prefer function-based plugin configs for clarity.
- Avoid global state except where needed for Neovim API.

---

## Submitting Pull Requests

- Fork the repository, create a branch, and submit your PR.
- For feature additions, ensure your code is commented and tested.
- For bugfixes, describe the bug and your fix in the PR description.

---

## Asking Questions / Reporting Issues

- Please use the Issues tab on the repository.
- For plugin-specific issues, link to upstream plugin if relevant.

---

## License

MIT License. See the LICENSE file.

---

Thanks for helping improve this Neovim config!
