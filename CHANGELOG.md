# Changelog for v3

## v3.5.1

- Bump deps versions.
- Various documentation improvements.

## v3.4

- Fixed types for adapter keys.
- Added the optional `opts` argument is passed through to the internal call to `Application.put_env/4` and may be used to set the `timeout` and/or
  `persistent` parameters.

## v3.3

- Support `{module, function, arguments}` tuple to define a cast function instead of type atom.
- Added `Confex.resolve_env!/1` to populate application environment from system tuples when application is started.

## v3.2

- Added `:system_file` adapter, which resolves configuration from contents of a file specified in
  environment variable, making it easy to read Docker secrets.

## v3.1

- Adapters list are not hard-coded anymore, now you can use `{:via, module}` tuple to
  set an adapter inside the system tuple.

## v3.0

- Confex is completely redesigned to be adapter-based.
- API is changed to be as similar as possible to the `Application` module.
