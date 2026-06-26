# BlueBuild Custom Modules

This directory contains local custom modules for BlueBuild.

## Structure

To create a custom module, add a subdirectory with:
```
modules/<module-name>/
├── <module-name>.json       # JSON Schema defining module inputs
└── <module-name>.sh         # Shell script implementing the module
```

## Usage in recipe.yml

```yaml
modules:
  - type: <module-name>
    source: local
    # ... module-specific options
```

## Notes

- The `source: local` key tells BlueBuild to look in `modules/` directory
- Most common use cases are covered by built-in modules:
  `type: files`, `type: dnf`, `type: script`, `type: default-flatpaks`, `type: signing`
